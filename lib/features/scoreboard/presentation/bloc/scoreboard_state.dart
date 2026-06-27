part of 'scoreboard_bloc.dart';

abstract class ScoreboardState extends Equatable {
  const ScoreboardState();
}

class ScoreboardInitial extends ScoreboardState {
  const ScoreboardInitial();
  @override
  List<Object> get props => [];
}

class ScoreboardLoaded extends ScoreboardState {
  final List<Team> rankedTeams;
  final bool showConfetti;

  const ScoreboardLoaded({
    required this.rankedTeams,
    this.showConfetti = false,
  });

  @override
  List<Object> get props => [rankedTeams, showConfetti];
}
