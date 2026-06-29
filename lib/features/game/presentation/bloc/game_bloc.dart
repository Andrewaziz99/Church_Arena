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

  // ── Pending round data (stored at competition start, consumed on transition) ─
  List<Question>? _pendingR2Questions;
  int _pendingR2Timer = 20;
  List<Question>? _pendingR3Questions;
  int _pendingR3SharedTimer = 45;
  List<int>? _pendingContestantsPerTeam;

  GameBloc({
    required this.repository,
    required this.audioService,
    required this.arduinoService,
  }) : super(const GameIdle()) {
    on<StartGame>(_onStartGame);
    on<StartCompetition>(_onStartCompetition);
    on<UseDouble>(_onUseDouble);
    on<ConfirmTeamTurn>(_onConfirmTeamTurn);
    on<ConfirmPairDisplay>(_onConfirmPairDisplay);
    on<AdvanceRound>(_onAdvanceRound);
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

  // ── Timer helpers ─────────────────────────────────────────────────────────

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

  // ── State helpers ─────────────────────────────────────────────────────────

  GameSession? _sessionFromState([GameState? s]) {
    s ??= state;
    if (s is GameWaitingBuzz) return s.session;
    if (s is GameBuzzedDisplay) return s.session;
    if (s is GameInProgress) return s.session;
    if (s is GameWaitingSecondTeam) return s.session;
    if (s is GamePaused) return s.session;
    if (s is GameTeamTurn) return s.session;
    if (s is GamePairDisplay) return s.session;
    if (s is GamePressureQuestion) return s.session;
    return null;
  }

  // ── R1 advancement ────────────────────────────────────────────────────────

  Future<void> _advanceR1Question(
      GameSession session, Emitter<GameState> emit) async {
    final doneCounts = List<int>.from(session.teamQuestionsDone);
    if (session.currentTeamIndex < doneCounts.length) {
      doneCounts[session.currentTeamIndex]++;
    }
    final currentTeamDone = session.currentTeamIndex < doneCounts.length
        ? doneCounts[session.currentTeamIndex]
        : session.questionsPerTeam;

    if (currentTeamDone >= session.questionsPerTeam) {
      // Current team finished their questions
      final nextTeamIdx = session.currentTeamIndex + 1;
      if (nextTeamIdx >= session.teams.length) {
        // All teams done → R1 complete
        emit(GameRoundTransition(session.teams, 1));
      } else {
        final nextQIdx = nextTeamIdx * session.questionsPerTeam;
        if (nextQIdx >= session.questions.length) {
          emit(GameRoundTransition(session.teams, 1));
          return;
        }
        final updated = session.copyWith(
          currentTeamIndex: nextTeamIdx,
          teamQuestionsDone: doneCounts,
          currentQuestionIndex: nextQIdx,
          buzzedTeamId: null,
          firstWrongTeamId: null,
          isDoubleActive: false,
          timerRemaining: session.timerSeconds,
        );
        await repository.saveSession(updated);
        arduinoService.resetBuzzers();
        emit(GameTeamTurn(updated));
      }
    } else {
      // Same team, next question
      final nextQIdx =
          session.currentTeamIndex * session.questionsPerTeam + currentTeamDone;
      if (nextQIdx >= session.questions.length) {
        // Ran out of questions for this team — treat as done
        await _advanceR1Question(
            session.copyWith(
              teamQuestionsDone: doneCounts..[session.currentTeamIndex] =
                  session.questionsPerTeam - 1,
            ),
            emit);
        return;
      }
      final updated = session.copyWith(
        teamQuestionsDone: doneCounts,
        currentQuestionIndex: nextQIdx,
        buzzedTeamId: null,
        firstWrongTeamId: null,
        isDoubleActive: false,
        timerRemaining: session.timerSeconds,
      );
      await repository.saveSession(updated);
      arduinoService.resetBuzzers();
      emit(GameWaitingBuzz(updated));
    }
  }

  // ── R2 advancement ────────────────────────────────────────────────────────

  Future<void> _advanceR2Pair(
      GameSession session, Emitter<GameState> emit) async {
    final nextPairIdx = session.currentPairIndex + 1;
    if (nextPairIdx >= session.totalPairs) {
      emit(GameRoundTransition(session.teams, 2));
    } else {
      final updated = session.copyWith(
        currentPairIndex: nextPairIdx,
        currentQuestionIndex: nextPairIdx,
        buzzedTeamId: null,
        firstWrongTeamId: null,
        timerRemaining: session.timerSeconds,
      );
      await repository.saveSession(updated);
      arduinoService.resetBuzzers();
      emit(GamePairDisplay(updated));
    }
  }

  // ── R3 advancement ────────────────────────────────────────────────────────

  Future<void> _advanceContestant(
      GameSession session, Emitter<GameState> emit) async {
    final nextContestantIdx = session.currentContestantIndex + 1;
    if (nextContestantIdx >= session.currentTeamContestants) {
      await _advanceR3Team(session, emit);
    } else {
      final nextQIdx = session.r3QuestionOffset + nextContestantIdx;
      if (nextQIdx >= session.questions.length) {
        await _advanceR3Team(session, emit);
        return;
      }
      final updated = session.copyWith(
        currentContestantIndex: nextContestantIdx,
        currentQuestionIndex: nextQIdx,
      );
      await repository.saveSession(updated);
      emit(GamePressureQuestion(updated));
    }
  }

  Future<void> _advanceR3Team(
      GameSession session, Emitter<GameState> emit) async {
    _stopGameTimer();
    final nextTeamIdx = session.currentTeamIndex + 1;
    if (nextTeamIdx >= session.teams.length) {
      emit(GameRoundTransition(session.teams, 3));
    } else {
      // Compute question offset for the next team
      int nextOffset = 0;
      for (int i = 0; i < nextTeamIdx; i++) {
        if (i < session.contestantsPerTeam.length) {
          nextOffset += session.contestantsPerTeam[i];
        }
      }
      final updated = session.copyWith(
        currentTeamIndex: nextTeamIdx,
        currentContestantIndex: 0,
        currentQuestionIndex: nextOffset,
        timerRemaining: session.sharedTimerSeconds,
      );
      await repository.saveSession(updated);
      emit(GameTeamTurn(updated));
    }
  }

  // ── Legacy: single-round start ────────────────────────────────────────────

  Future<void> _onStartGame(StartGame event, Emitter<GameState> emit) async {
    emit(const GameLoading());
    final teamsDone = List<int>.filled(event.teams.length, 0);
    final session = GameSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      teams: event.teams,
      questions: event.questions,
      currentQuestionIndex: 0,
      status: GameStatus.active,
      timerSeconds: event.timerSeconds,
      timerRemaining: event.timerSeconds,
      roundType: RoundType.classic,
      roundNumber: 1,
      questionsPerTeam: event.questions.length,
      currentTeamIndex: 0,
      teamQuestionsDone: teamsDone,
    );
    await repository.saveSession(session);
    arduinoService.resetBuzzers();
    emit(GameWaitingBuzz(session));
  }

  // ── Competition start ─────────────────────────────────────────────────────

  Future<void> _onStartCompetition(
      StartCompetition event, Emitter<GameState> emit) async {
    emit(const GameLoading());

    // Stash R2 + R3 data for later transitions
    _pendingR2Questions = event.round2Questions;
    _pendingR2Timer = event.round2Timer;
    _pendingR3Questions = event.round3Questions;
    _pendingR3SharedTimer = event.sharedTimer;
    _pendingContestantsPerTeam = event.contestantsPerTeam;

    final teamsDone = List<int>.filled(event.teams.length, 0);
    final session = GameSession(
      id: '${DateTime.now().millisecondsSinceEpoch}_r1',
      teams: event.teams,
      questions: event.round1Questions,
      currentQuestionIndex: 0,
      status: GameStatus.active,
      timerSeconds: event.round1Timer,
      timerRemaining: event.round1Timer,
      roundType: RoundType.classic,
      roundNumber: 1,
      questionsPerTeam: event.questionsPerTeam,
      currentTeamIndex: 0,
      teamQuestionsDone: teamsDone,
    );

    await repository.saveSession(session);
    arduinoService.resetBuzzers();
    emit(GameTeamTurn(session));
  }

  // ── Double points (R1) ────────────────────────────────────────────────────

  Future<void> _onUseDouble(UseDouble event, Emitter<GameState> emit) async {
    if (state is! GameWaitingBuzz) return;
    final session = (state as GameWaitingBuzz).session;
    if (session.roundType != RoundType.classic) return;
    final currentTeam = session.currentTeam;
    if (currentTeam == null) return;
    if (session.doublesUsed.contains(currentTeam.id)) return;
    if (session.isDoubleActive) return;

    final updated = session.copyWith(
      isDoubleActive: true,
      doublesUsed: [...session.doublesUsed, currentTeam.id],
    );
    await repository.saveSession(updated);
    emit(GameWaitingBuzz(updated));
  }

  // ── Team turn / pair display confirmations ────────────────────────────────

  Future<void> _onConfirmTeamTurn(
      ConfirmTeamTurn event, Emitter<GameState> emit) async {
    if (state is! GameTeamTurn) return;
    final session = (state as GameTeamTurn).session;

    if (session.roundType == RoundType.underPressure) {
      // R3: start shared timer and show first contestant's question
      final firstQIdx = session.r3QuestionOffset;
      if (firstQIdx >= session.questions.length) {
        await _advanceR3Team(session, emit);
        return;
      }
      final updated = session.copyWith(
        currentQuestionIndex: firstQIdx,
        currentContestantIndex: 0,
        timerRemaining: session.sharedTimerSeconds,
      );
      await repository.saveSession(updated);
      emit(GamePressureQuestion(updated));
      _startGameTimer();
    } else {
      // R1: show current team's first question, no timer yet
      arduinoService.resetBuzzers();
      emit(GameWaitingBuzz(session));
    }
  }

  Future<void> _onConfirmPairDisplay(
      ConfirmPairDisplay event, Emitter<GameState> emit) async {
    if (state is! GamePairDisplay) return;
    final session = (state as GamePairDisplay).session;
    arduinoService.resetBuzzers();
    emit(GameWaitingBuzz(session));
  }

  // ── Round transition ──────────────────────────────────────────────────────

  Future<void> _onAdvanceRound(
      AdvanceRound event, Emitter<GameState> emit) async {
    if (state is! GameRoundTransition) return;
    final s = state as GameRoundTransition;

    if (s.completedRound == 3) {
      // R3 done → final scoreboard
      final sorted = [...s.teams]..sort((a, b) => b.score.compareTo(a.score));
      await repository.clearSession();
      emit(GameEnded(sorted));
      return;
    }

    if (s.completedRound == 1) {
      if (_pendingR2Questions == null || _pendingR2Questions!.isEmpty) {
        // No R2 → jump to R3 or end
        if (_pendingR3Questions == null || _pendingR3Questions!.isEmpty) {
          final sorted = [...s.teams]
            ..sort((a, b) => b.score.compareTo(a.score));
          await repository.clearSession();
          emit(GameEnded(sorted));
          return;
        }
        await _startR3Session(s.teams, emit);
        return;
      }
      await _startR2Session(s.teams, emit);
    } else if (s.completedRound == 2) {
      if (_pendingR3Questions == null || _pendingR3Questions!.isEmpty) {
        final sorted = [...s.teams]..sort((a, b) => b.score.compareTo(a.score));
        await repository.clearSession();
        emit(GameEnded(sorted));
        return;
      }
      await _startR3Session(s.teams, emit);
    }
  }

  Future<void> _startR2Session(
      List<Team> teams, Emitter<GameState> emit) async {
    // Pair teams in order: [t0,t1, t2,t3, …]
    final pairsList = teams.map((t) => t.id).toList();
    final session = GameSession(
      id: '${DateTime.now().millisecondsSinceEpoch}_r2',
      teams: teams,
      questions: _pendingR2Questions!,
      currentQuestionIndex: 0,
      status: GameStatus.active,
      timerSeconds: _pendingR2Timer,
      timerRemaining: _pendingR2Timer,
      roundType: RoundType.penaltyShootout,
      roundNumber: 2,
      teamPairsList: pairsList,
      currentPairIndex: 0,
    );
    await repository.saveSession(session);
    arduinoService.resetBuzzers();
    emit(GamePairDisplay(session));
  }

  Future<void> _startR3Session(
      List<Team> teams, Emitter<GameState> emit) async {
    final contestants = _pendingContestantsPerTeam ?? List.filled(teams.length, 3);
    final session = GameSession(
      id: '${DateTime.now().millisecondsSinceEpoch}_r3',
      teams: teams,
      questions: _pendingR3Questions!,
      currentQuestionIndex: 0,
      status: GameStatus.active,
      timerSeconds: _pendingR3SharedTimer,
      timerRemaining: _pendingR3SharedTimer,
      roundType: RoundType.underPressure,
      roundNumber: 3,
      contestantsPerTeam: contestants,
      currentContestantIndex: 0,
      currentTeamIndex: 0,
      sharedTimerSeconds: _pendingR3SharedTimer,
    );
    await repository.saveSession(session);
    emit(GameTeamTurn(session));
  }

  // ── Next question / skip ──────────────────────────────────────────────────

  Future<void> _onNextQuestion(
      NextQuestion event, Emitter<GameState> emit) async {
    _stopGameTimer();
    _stopBuzzTimer();

    if (state is GamePressureQuestion) {
      final session = (state as GamePressureQuestion).session;
      await _advanceContestant(session, emit);
      return;
    }

    final session = _sessionFromState();
    if (session == null) return;

    final clean = session.copyWith(
      buzzedTeamId: null,
      firstWrongTeamId: null,
      isDoubleActive: false,
    );

    switch (clean.roundType) {
      case RoundType.classic:
        await _advanceR1Question(clean, emit);
      case RoundType.penaltyShootout:
        await _advanceR2Pair(clean, emit);
      case RoundType.underPressure:
        await _advanceContestant(clean, emit);
    }
  }

  // ── Buzzer ────────────────────────────────────────────────────────────────

  Future<void> _onBuzzerPressed(
      BuzzerPressed event, Emitter<GameState> emit) async {
    final s = state;
    GameSession? session;
    if (s is GameWaitingBuzz) session = s.session;
    if (s is GameWaitingSecondTeam) session = s.session;
    if (session == null) return;

    // R1: only current team may buzz
    if (session.roundType == RoundType.classic) {
      final current = session.currentTeam;
      if (current == null || event.teamId != current.id) return;
    }

    // R2: only teams in the current pair may buzz
    if (session.roundType == RoundType.penaltyShootout) {
      final pair = session.currentPair;
      if (pair == null) return;
      final (teamA, teamB) = pair;
      if (event.teamId != teamA.id && event.teamId != teamB.id) return;
    }

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
    // resetBuzzers() sends 'R' over serial AND clears the software lock,
    // so the next physical press from the Arduino is registered.
    arduinoService.resetBuzzers();
  }

  // ── Answers ───────────────────────────────────────────────────────────────

  Future<void> _onAnswerCorrect(
      AnswerCorrect event, Emitter<GameState> emit) async {
    // R3: no buzzer, controller-driven
    if (state is GamePressureQuestion) {
      final session = (state as GamePressureQuestion).session;
      await audioService.playCorrect();
      final currentTeam = session.currentTeam;
      if (currentTeam == null) return;
      final updatedTeams = session.teams.map((t) {
        if (t.id == currentTeam.id) {
          return t.copyWith(score: t.score + event.points);
        }
        return t;
      }).toList();
      await _advanceContestant(session.copyWith(teams: updatedTeams), emit);
      return;
    }

    if (state is! GameInProgress) return;
    _stopGameTimer();
    await audioService.playCorrect();
    final session = (state as GameInProgress).session;
    final buzzedId = session.buzzedTeamId;
    if (buzzedId == null) return;

    final pts = session.isDoubleActive ? event.points * 2 : event.points;
    final updatedTeams = session.teams.map((t) {
      if (t.id == buzzedId) return t.copyWith(score: t.score + pts);
      return t;
    }).toList();

    final updated = session.copyWith(
      teams: updatedTeams,
      buzzedTeamId: null,
      firstWrongTeamId: null,
      isDoubleActive: false,
    );

    switch (updated.roundType) {
      case RoundType.classic:
        await _advanceR1Question(updated, emit);
      case RoundType.penaltyShootout:
        await _advanceR2Pair(updated, emit);
      case RoundType.underPressure:
        break; // handled above
    }
  }

  Future<void> _onAnswerWrong(
      AnswerWrong event, Emitter<GameState> emit) async {
    // R3: no second-chance, just advance
    if (state is GamePressureQuestion) {
      final session = (state as GamePressureQuestion).session;
      await audioService.playWrong();
      final currentTeam = session.currentTeam;
      if (currentTeam == null) return;
      final penalisedTeams = session.teams.map((t) {
        if (t.id == currentTeam.id) return t.copyWith(score: t.score - 1);
        return t;
      }).toList();
      await _advanceContestant(session.copyWith(teams: penalisedTeams), emit);
      return;
    }

    if (state is! GameInProgress) return;
    _stopGameTimer();
    await audioService.playWrong();
    final session = (state as GameInProgress).session;
    final buzzedId = session.buzzedTeamId;
    if (buzzedId == null) return;

    final penalisedTeams = session.teams.map((t) {
      if (t.id == buzzedId) return t.copyWith(score: t.score - 1);
      return t;
    }).toList();

    if (session.roundType == RoundType.classic) {
      // R1: no second-team chance
      final updated = session.copyWith(
        teams: penalisedTeams,
        buzzedTeamId: null,
        firstWrongTeamId: null,
        isDoubleActive: false,
      );
      await _advanceR1Question(updated, emit);
      return;
    }

    if (session.roundType == RoundType.penaltyShootout) {
      if (session.firstWrongTeamId == null) {
        // First wrong in R2 → other pair team gets a chance
        final updated = session.copyWith(
          teams: penalisedTeams,
          buzzedTeamId: null,
          firstWrongTeamId: buzzedId,
          timerRemaining: session.timerSeconds,
          status: GameStatus.active,
          isDoubleActive: false,
        );
        await repository.saveSession(updated);
        arduinoService.resetBuzzers();
        emit(GameWaitingSecondTeam(updated));
      } else {
        // Second wrong in R2 → advance pair
        final updated = session.copyWith(
          teams: penalisedTeams,
          buzzedTeamId: null,
          firstWrongTeamId: null,
          isDoubleActive: false,
        );
        await _advanceR2Pair(updated, emit);
      }
      return;
    }
  }

  // ── Timer ─────────────────────────────────────────────────────────────────

  void _onPauseTimer(PauseTimer event, Emitter<GameState> emit) {
    if (state is GameInProgress) {
      _stopGameTimer();
      emit(GamePaused(
          (state as GameInProgress).session.copyWith(status: GameStatus.paused)));
      return;
    }
    if (state is GamePressureQuestion) {
      _stopGameTimer();
      emit(GamePaused((state as GamePressureQuestion)
          .session
          .copyWith(status: GameStatus.paused)));
    }
  }

  void _onResumeTimer(ResumeTimer event, Emitter<GameState> emit) {
    if (state is! GamePaused) return;
    final session = (state as GamePaused).session.copyWith(status: GameStatus.active);
    if (session.roundType == RoundType.underPressure) {
      emit(GamePressureQuestion(session));
    } else {
      emit(GameInProgress(session));
    }
    _startGameTimer();
  }

  Future<void> _onTimerTick(TimerTick event, Emitter<GameState> emit) async {
    // R3: tick in GamePressureQuestion (shared team timer)
    if (state is GamePressureQuestion) {
      final session = (state as GamePressureQuestion).session;
      final newRemaining = session.timerRemaining - 1;
      if (newRemaining <= 0) {
        _stopGameTimer();
        await audioService.playTick();
        // Time's up → advance to next team
        await _advanceR3Team(session, emit);
      } else {
        if (newRemaining <= 5) await audioService.playTick();
        final updated = session.copyWith(timerRemaining: newRemaining);
        await repository.saveSession(updated);
        emit(GamePressureQuestion(updated));
      }
      return;
    }

    if (state is! GameInProgress) return;
    final session = (state as GameInProgress).session;
    final newRemaining = session.timerRemaining - 1;

    if (newRemaining <= 0) {
      _stopGameTimer();
      await audioService.playTick();
      // Time expired → depending on round, skip or pause
      switch (session.roundType) {
        case RoundType.classic:
          final clean = session.copyWith(
              buzzedTeamId: null,
              firstWrongTeamId: null,
              isDoubleActive: false);
          await _advanceR1Question(clean, emit);
        case RoundType.penaltyShootout:
          final clean = session.copyWith(
              buzzedTeamId: null,
              firstWrongTeamId: null);
          await _advanceR2Pair(clean, emit);
        case RoundType.underPressure:
          break;
      }
    } else {
      if (newRemaining <= 5) await audioService.playTick();
      final updated = session.copyWith(timerRemaining: newRemaining);
      await repository.saveSession(updated);
      emit(GameInProgress(updated));
    }
  }

  // ── End game ──────────────────────────────────────────────────────────────

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
