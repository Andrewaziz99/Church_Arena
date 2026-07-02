part of 'scoreboard_bloc.dart';

abstract class ScoreboardEvent extends Equatable {
  const ScoreboardEvent();
}

/// Called when a game ends — saves result to DB and loads history.
class SaveResult extends ScoreboardEvent {
  final List<Team> teams;
  const SaveResult(this.teams);
  @override
  List<Object> get props => [teams];
}

/// Load all past results from DB (called on scoreboard screen open).
class LoadResults extends ScoreboardEvent {
  const LoadResults();
  @override
  List<Object> get props => [];
}

/// Delete a past result by ID.
class DeleteResult extends ScoreboardEvent {
  final String id;
  const DeleteResult(this.id);
  @override
  List<Object> get props => [id];
}

/// Legacy: kept so existing code that calls LoadScoreboard still compiles.
/// Prefer SaveResult for new code.
class LoadScoreboard extends ScoreboardEvent {
  final List<Team> teams;
  const LoadScoreboard(this.teams);
  @override
  List<Object> get props => [teams];
}

class ResetScoreboard extends ScoreboardEvent {
  const ResetScoreboard();
  @override
  List<Object> get props => [];
}
