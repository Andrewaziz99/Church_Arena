part of 'teams_bloc.dart';

abstract class TeamsEvent extends Equatable {
  const TeamsEvent();
}

class LoadTeams extends TeamsEvent {
  const LoadTeams();
  @override
  List<Object> get props => [];
}

class SaveTeam extends TeamsEvent {
  final Team team;
  const SaveTeam(this.team);
  @override
  List<Object> get props => [team];
}

class DeleteTeam extends TeamsEvent {
  final String teamId;
  const DeleteTeam(this.teamId);
  @override
  List<Object> get props => [teamId];
}

class UpdateScore extends TeamsEvent {
  final String teamId;
  final int delta;
  const UpdateScore(this.teamId, this.delta);
  @override
  List<Object> get props => [teamId, delta];
}

class ResetScore extends TeamsEvent {
  final String teamId;
  const ResetScore(this.teamId);
  @override
  List<Object> get props => [teamId];
}

class ResetAllScores extends TeamsEvent {
  const ResetAllScores();
  @override
  List<Object> get props => [];
}
