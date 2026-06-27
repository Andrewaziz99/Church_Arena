part of 'scoreboard_bloc.dart';

abstract class ScoreboardEvent extends Equatable {
  const ScoreboardEvent();
}

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
