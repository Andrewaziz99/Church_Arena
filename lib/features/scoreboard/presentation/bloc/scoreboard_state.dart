part of 'scoreboard_bloc.dart';

abstract class ScoreboardState extends Equatable {
  const ScoreboardState();
}

class ScoreboardInitial extends ScoreboardState {
  const ScoreboardInitial();
  @override
  List<Object> get props => [];
}

/// Shown immediately after a game ends (with confetti) while also listing history.
class ScoreboardLoaded extends ScoreboardState {
  final List<Team> rankedTeams;
  final bool showConfetti;
  final List<CompetitionResult> history;

  const ScoreboardLoaded({
    required this.rankedTeams,
    this.showConfetti = false,
    this.history = const [],
  });

  @override
  List<Object> get props => [rankedTeams, showConfetti, history];
}

/// No current game result — just show the history browser.
class ScoreboardHistory extends ScoreboardState {
  final List<CompetitionResult> history;
  final bool loading;

  const ScoreboardHistory({this.history = const [], this.loading = false});

  @override
  List<Object> get props => [history, loading];
}
