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

  Timer? _timer;
  StreamSubscription<String>? _buzzerSubscription;

  GameBloc({
    required this.repository,
    required this.audioService,
    required this.arduinoService,
  }) : super(const GameIdle()) {
    on<StartGame>(_onStartGame);
    on<NextQuestion>(_onNextQuestion);
    on<BuzzerPressed>(_onBuzzerPressed);
    on<ResetBuzzer>(_onResetBuzzer);
    on<AnswerCorrect>(_onAnswerCorrect);
    on<AnswerWrong>(_onAnswerWrong);
    on<PauseTimer>(_onPauseTimer);
    on<ResumeTimer>(_onResumeTimer);
    on<StopTimer>(_onStopTimer);
    on<TimerTick>(_onTimerTick);
    on<EndGame>(_onEndGame);

    _buzzerSubscription = arduinoService.buzzerStream.listen((teamIndex) {
      final currentState = state;
      if (currentState is GameInProgress) {
        final teams = currentState.session.teams;
        final idx = int.tryParse(teamIndex);
        if (idx != null && idx >= 1 && idx <= teams.length) {
          add(BuzzerPressed(teams[idx - 1].id));
        }
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const TimerTick());
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

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
    emit(GameInProgress(session));
    _startTimer();
  }

  Future<void> _onNextQuestion(NextQuestion event, Emitter<GameState> emit) async {
    final currentState = state;
    GameSession? session;
    if (currentState is GameInProgress) session = currentState.session;
    if (currentState is GameBuzzed) session = currentState.session;
    if (currentState is GamePaused) session = currentState.session;
    if (session == null) return;

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
    );
    await repository.saveSession(updated);
    arduinoService.resetBuzzers();
    emit(GameInProgress(updated));
    _startTimer();
  }

  Future<void> _onBuzzerPressed(BuzzerPressed event, Emitter<GameState> emit) async {
    final currentState = state;
    if (currentState is! GameInProgress) return;
    _stopTimer();
    await audioService.playBuzzer();
    final updated = currentState.session.copyWith(
      status: GameStatus.buzzed,
      buzzedTeamId: event.teamId,
    );
    await repository.saveSession(updated);
    emit(GameBuzzed(updated));
  }

  Future<void> _onResetBuzzer(ResetBuzzer event, Emitter<GameState> emit) async {
    final currentState = state;
    if (currentState is! GameBuzzed) return;
    arduinoService.resetBuzzers();
    final updated = currentState.session.copyWith(
      status: GameStatus.active,
      buzzedTeamId: null,
    );
    await repository.saveSession(updated);
    emit(GameInProgress(updated));
    _startTimer();
  }

  Future<void> _onAnswerCorrect(AnswerCorrect event, Emitter<GameState> emit) async {
    final currentState = state;
    if (currentState is! GameBuzzed) return;
    await audioService.playCorrect();
    final session = currentState.session;
    final buzzedId = session.buzzedTeamId;
    if (buzzedId == null) return;

    final updatedTeams = session.teams.map((t) {
      if (t.id == buzzedId) return t.copyWith(score: t.score + event.points);
      return t;
    }).toList();

    final updated = session.copyWith(
      teams: updatedTeams,
      status: GameStatus.active,
      buzzedTeamId: null,
    );
    await repository.saveSession(updated);
    arduinoService.resetBuzzers();
    emit(GameInProgress(updated));
    _startTimer();
  }

  Future<void> _onAnswerWrong(AnswerWrong event, Emitter<GameState> emit) async {
    final currentState = state;
    if (currentState is! GameBuzzed) return;
    await audioService.playWrong();
    final updated = currentState.session.copyWith(
      status: GameStatus.active,
      buzzedTeamId: null,
    );
    await repository.saveSession(updated);
    arduinoService.resetBuzzers();
    emit(GameInProgress(updated));
    _startTimer();
  }

  void _onPauseTimer(PauseTimer event, Emitter<GameState> emit) {
    final currentState = state;
    GameSession? session;
    if (currentState is GameInProgress) session = currentState.session;
    if (session == null) return;
    _stopTimer();
    final updated = session.copyWith(status: GameStatus.paused);
    emit(GamePaused(updated));
  }

  void _onResumeTimer(ResumeTimer event, Emitter<GameState> emit) {
    final currentState = state;
    if (currentState is! GamePaused) return;
    final updated = currentState.session.copyWith(status: GameStatus.active);
    emit(GameInProgress(updated));
    _startTimer();
  }

  void _onStopTimer(StopTimer event, Emitter<GameState> emit) {
    _stopTimer();
  }

  Future<void> _onTimerTick(TimerTick event, Emitter<GameState> emit) async {
    final currentState = state;
    if (currentState is! GameInProgress) return;
    final session = currentState.session;
    final newRemaining = session.timerRemaining - 1;

    if (newRemaining <= 0) {
      _stopTimer();
      await audioService.playTick();
      final updated = session.copyWith(
        timerRemaining: 0,
        status: GameStatus.paused,
      );
      await repository.saveSession(updated);
      emit(GamePaused(updated));
    } else {
      if (newRemaining <= 5) {
        await audioService.playTick();
      }
      final updated = session.copyWith(timerRemaining: newRemaining);
      await repository.saveSession(updated);
      emit(GameInProgress(updated));
    }
  }

  Future<void> _onEndGame(EndGame event, Emitter<GameState> emit) async {
    _stopTimer();
    await audioService.playVictory();
    final currentState = state;
    List<Team> teams = [];
    if (currentState is GameInProgress) teams = currentState.session.teams;
    if (currentState is GameBuzzed) teams = currentState.session.teams;
    if (currentState is GamePaused) teams = currentState.session.teams;
    teams = [...teams]..sort((a, b) => b.score.compareTo(a.score));
    await repository.clearSession();
    emit(GameEnded(teams));
  }

  @override
  Future<void> close() {
    _stopTimer();
    _buzzerSubscription?.cancel();
    return super.close();
  }
}
