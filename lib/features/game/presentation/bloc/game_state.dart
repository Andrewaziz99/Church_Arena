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

/// Question shown, timer NOT started — waiting for first buzz.
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

/// Timer running — buzzed team is actively answering.
class GameInProgress extends GameState {
  final GameSession session;
  const GameInProgress(this.session);
  @override
  List<Object> get props => [session];
}

/// First team answered wrong; waiting for a second team to buzz.
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
