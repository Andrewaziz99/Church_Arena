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

class GameInProgress extends GameState {
  final GameSession session;
  const GameInProgress(this.session);
  @override
  List<Object> get props => [session];
}

class GameBuzzed extends GameState {
  final GameSession session;
  const GameBuzzed(this.session);
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
