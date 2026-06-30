part of 'game_bloc.dart';

abstract class GameState extends Equatable {
  const GameState();
}

class GameIdle extends GameState {
  const GameIdle();
  @override
  List<Object> get props => [];
}

class GameLoading extends GameState {
  const GameLoading();
  @override
  List<Object> get props => [];
}

/// Question shown, timer NOT started — waiting for buzz.
class GameWaitingBuzz extends GameState {
  final GameSession session;
  const GameWaitingBuzz(this.session);
  @override
  List<Object> get props => [session];
}

/// A team buzzed — fullscreen team-name display for [secondsLeft] seconds (3→1).
class GameBuzzedDisplay extends GameState {
  final GameSession session;
  final int secondsLeft;
  const GameBuzzedDisplay(this.session, this.secondsLeft);
  @override
  List<Object> get props => [session, secondsLeft];
}

/// Timer running — buzzed team is actively answering (R1 / R2).
class GameInProgress extends GameState {
  final GameSession session;
  const GameInProgress(this.session);
  @override
  List<Object> get props => [session];
}

/// R1 / R2: first team answered wrong; waiting for a second team to buzz.
class GameWaitingSecondTeam extends GameState {
  final GameSession session;
  const GameWaitingSecondTeam(this.session);
  @override
  List<Object> get props => [session];
}

class GamePaused extends GameState {
  final GameSession session;
  const GamePaused(this.session);
  @override
  List<Object> get props => [session];
}

// ── 3-round competition states ────────────────────────────────────────────────

/// R1 / R3: full-screen "Team X's turn" intro between teams.
class GameTeamTurn extends GameState {
  final GameSession session;
  const GameTeamTurn(this.session);
  @override
  List<Object> get props => [session];
}

/// R2: full-screen "Team A vs Team B" display before each pair's question.
class GamePairDisplay extends GameState {
  final GameSession session;
  const GamePairDisplay(this.session);
  @override
  List<Object> get props => [session];
}

/// Shown between rounds: "Round N complete — press to continue".
class GameRoundTransition extends GameState {
  final List<Team> teams;
  final int completedRound; // 1 or 2 (3 → goes directly to GameEnded)
  const GameRoundTransition(this.teams, this.completedRound);
  @override
  List<Object> get props => [teams, completedRound];
}

/// R3 "Under Pressure": shared timer running, controller drives Correct/Wrong/Skip.
class GamePressureQuestion extends GameState {
  final GameSession session;
  const GamePressureQuestion(this.session);
  @override
  List<Object> get props => [session];
}

/// Showing the correct answer highlighted for ~2 seconds, then auto-advancing.
/// Emitted after a correct answer (R1/R2) or after "Reveal Answer" (both-wrong).
class GameShowingAnswer extends GameState {
  final GameSession session;
  final Question question;
  const GameShowingAnswer(this.session, this.question);
  @override
  List<Object?> get props => [session, question];
}

/// Both teams answered wrong — controller can reveal the answer or skip.
class GameBothWrong extends GameState {
  final GameSession session;
  final Question question;
  const GameBothWrong(this.session, this.question);
  @override
  List<Object?> get props => [session, question];
}

// ── Terminal states ───────────────────────────────────────────────────────────

class GameEnded extends GameState {
  final List<Team> teams;
  const GameEnded(this.teams);
  @override
  List<Object> get props => [teams];
}

class GameError extends GameState {
  final String message;
  const GameError(this.message);
  @override
  List<Object> get props => [message];
}
