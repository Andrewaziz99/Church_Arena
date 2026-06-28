import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../services/arduino/arduino_service.dart';
import '../../../../services/audio/audio_service.dart';
import '../../../questions/domain/entities/question.dart';
import '../../../teams/domain/entities/team.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/repositories/game_repository.dart';

part 'game_event.dart';
part 'game_state.dart';

@injectable
class GameBloc extends Bloc<GameEvent, GameState> {
  final GameRepository repository;
  final AudioService audioService;
  final ArduinoService arduinoService;

  Timer? _gameTimer;
  Timer? _buzzTimer;
  StreamSubscription<String>? _buzzerSubscription;

  GameBloc({
    required this.repository,
    required this.audioService,
    required this.arduinoService,
  }) : super(const GameIdle()) {
    on<StartGame>(_onStartGame);
    on<NextQuestion>(_onNextQuestion);
    on<BuzzerPressed>(_onBuzzerPressed);
    on<BuzzCountdownTick>(_onBuzzCountdownTick);
    on<ResetBuzzer>(_onResetBuzzer);
    on<AnswerCorrect>(_onAnswerCorrect);
    on<AnswerWrong>(_onAnswerWrong);
    on<PauseTimer>(_onPauseTimer);
    on<ResumeTimer>(_onResumeTimer);
    on<TimerTick>(_onTimerTick);
    on<EndGame>(_onEndGame);

    _buzzerSubscription = arduinoService.buzzerStream.listen((teamIndex) {
      final s = state;
      List<Team>? teams;
      if (s is GameWaitingBuzz) teams = s.session.teams;
      if (s is GameWaitingSecondTeam) teams = s.session.teams;
      if (teams == null) return;
      final idx = int.tryParse(teamIndex);
      if (idx != null && idx >= 1 && idx <= teams.length) {
        add(BuzzerPressed(teams[idx - 1].id));
      }
    });
  }

  // ── Timers ──────────────────────────────────────────────────────────────────

  void _startGameTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const TimerTick());
    });
  }

  void _stopGameTimer() {
    _gameTimer?.cancel();
    _gameTimer = null;
  }

  void _startBuzzTimer() {
    _buzzTimer?.cancel();
    _buzzTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const BuzzCountdownTick());
    });
  }

  void _stopBuzzTimer() {
    _buzzTimer?.cancel();
    _buzzTimer = null;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  GameSession? _sessionFromState([GameState? s]) {
    s ??= state;
    if (s is GameWaitingBuzz) return s.session;
    if (s is GameBuzzedDisplay) return s.session;
    if (s is GameInProgress) return s.session;
    if (s is GameWaitingSecondTeam) return s.session;
    if (s is GamePaused) return s.session;
    return null;
  }

  Future<void> _nextQuestionOrEnd(
      GameSession session, Emitter<GameState> emit) async {
    final currentQ = session.questions[session.currentQuestionIndex];
    final nextIndex = session.currentQuestionIndex + 1;

    if (nextIndex >= session.questions.length) {
      add(const EndGame());
      return;
    }

    final updated = session.copyWith(
      currentQuestionIndex: nextIndex,
      usedQuestionIds: [...session.usedQuestionIds, currentQ.id],
      status: GameStatus.active,
      timerRemaining: session.timerSeconds,
      buzzedTeamId: null,
      firstWrongTeamId: null,
    );
    await repository.saveSession(updated);
    arduinoService.resetBuzzers();
    emit(GameWaitingBuzz(updated));
  }

  // ── Event handlers ───────────────────────────────────────────────────────────

  Future<void> _onStartGame(StartGame event, Emitter<GameState> emit) async {
    emit(const GameLoading());
    final session = GameSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      teams: event.teams,
      questions: event.questions,
      currentQuestionIndex: 0,
      status: GameStatus.active,
      timerSeconds: event.timerSeconds,
      timerRemaining: event.timerSeconds,
    );
    await repository.saveSession(session);
    arduinoService.resetBuzzers();
    // Timer does NOT start here — waits for first buzz
    emit(GameWaitingBuzz(session));
  }

  Future<void> _onNextQuestion(
      NextQuestion event, Emitter<GameState> emit) async {
    _stopGameTimer();
    _stopBuzzTimer();
    final session = _sessionFromState();
    if (session == null) return;
    await _nextQuestionOrEnd(session, emit);
  }

  Future<void> _onBuzzerPressed(
      BuzzerPressed event, Emitter<GameState> emit) async {
    final s = state;
    GameSession? session;
    if (s is GameWaitingBuzz) session = s.session;
    if (s is GameWaitingSecondTeam) session = s.session;
    if (session == null) return;

    _stopGameTimer();
    _stopBuzzTimer();
    await audioService.playBuzzer();

    final updated = session.copyWith(
      status: GameStatus.buzzed,
      buzzedTeamId: event.teamId,
      timerRemaining: session.timerSeconds,
    );
    await repository.saveSession(updated);
    emit(GameBuzzedDisplay(updated, 3));
    _startBuzzTimer();
  }

  Future<void> _onBuzzCountdownTick(
      BuzzCountdownTick event, Emitter<GameState> emit) async {
    if (state is! GameBuzzedDisplay) {
      _stopBuzzTimer();
      return;
    }
    final s = state as GameBuzzedDisplay;
    final next = s.secondsLeft - 1;
    if (next > 0) {
      emit(GameBuzzedDisplay(s.session, next));
    } else {
      _stopBuzzTimer();
      emit(GameInProgress(s.session));
      _startGameTimer();
    }
  }

  Future<void> _onResetBuzzer(
      ResetBuzzer event, Emitter<GameState> emit) async {
    arduinoService.sendResetSignal();
  }

  Future<void> _onAnswerCorrect(
      AnswerCorrect event, Emitter<GameState> emit) async {
    if (state is! GameInProgress) return;
    _stopGameTimer();
    await audioService.playCorrect();
    final session = (state as GameInProgress).session;
    final buzzedId = session.buzzedTeamId;
    if (buzzedId == null) return;

    final updatedTeams = session.teams.map((t) {
      if (t.id == buzzedId) return t.copyWith(score: t.score + event.points);
      return t;
    }).toList();

    final updated = session.copyWith(
      teams: updatedTeams,
      buzzedTeamId: null,
      firstWrongTeamId: null,
    );
    await _nextQuestionOrEnd(updated, emit);
  }

  Future<void> _onAnswerWrong(
      AnswerWrong event, Emitter<GameState> emit) async {
    if (state is! GameInProgress) return;
    _stopGameTimer();
    await audioService.playWrong();
    final session = (state as GameInProgress).session;
    final buzzedId = session.buzzedTeamId;
    if (buzzedId == null) return;

    // Penalise the team that answered wrong (-1 point)
    final penalisedTeams = session.teams.map((t) {
      if (t.id == buzzedId) return t.copyWith(score: t.score - 1);
      return t;
    }).toList();

    if (session.firstWrongTeamId == null) {
      // First wrong answer — offer second team a chance
      final updated = session.copyWith(
        teams: penalisedTeams,
        buzzedTeamId: null,
        firstWrongTeamId: buzzedId,
        timerRemaining: session.timerSeconds,
        status: GameStatus.active,
      );
      await repository.saveSession(updated);
      arduinoService.resetBuzzers();
      emit(GameWaitingSecondTeam(updated));
    } else {
      // Second wrong answer — both penalised, move on
      final updated = session.copyWith(
        teams: penalisedTeams,
        buzzedTeamId: null,
        firstWrongTeamId: null,
      );
      await _nextQuestionOrEnd(updated, emit);
    }
  }

  void _onPauseTimer(PauseTimer event, Emitter<GameState> emit) {
    if (state is! GameInProgress) return;
    _stopGameTimer();
    final session = (state as GameInProgress).session;
    emit(GamePaused(session.copyWith(status: GameStatus.paused)));
  }

  void _onResumeTimer(ResumeTimer event, Emitter<GameState> emit) {
    if (state is! GamePaused) return;
    final session = (state as GamePaused).session;
    emit(GameInProgress(session.copyWith(status: GameStatus.active)));
    _startGameTimer();
  }

  Future<void> _onTimerTick(TimerTick event, Emitter<GameState> emit) async {
    if (state is! GameInProgress) return;
    final session = (state as GameInProgress).session;
    final newRemaining = session.timerRemaining - 1;

    if (newRemaining <= 0) {
      _stopGameTimer();
      await audioService.playTick();
      final updated = session.copyWith(
        timerRemaining: 0,
        status: GameStatus.paused,
        buzzedTeamId: null,
        firstWrongTeamId: null,
      );
      await repository.saveSession(updated);
      emit(GamePaused(updated));
    } else {
      if (newRemaining <= 5) await audioService.playTick();
      final updated = session.copyWith(timerRemaining: newRemaining);
      await repository.saveSession(updated);
      emit(GameInProgress(updated));
    }
  }

  Future<void> _onEndGame(EndGame event, Emitter<GameState> emit) async {
    _stopGameTimer();
    _stopBuzzTimer();
    await audioService.playVictory();
    final session = _sessionFromState();
    final sorted = [...(session?.teams ?? <Team>[])]
      ..sort((a, b) => b.score.compareTo(a.score));
    await repository.clearSession();
    emit(GameEnded(sorted));
  }

  @override
  Future<void> close() {
    _stopGameTimer();
    _stopBuzzTimer();
    _buzzerSubscription?.cancel();
    return super.close();
  }
}
