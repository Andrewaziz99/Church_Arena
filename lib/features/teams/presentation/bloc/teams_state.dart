part of 'teams_bloc.dart';

abstract class TeamsState extends Equatable {
  const TeamsState();
}

class TeamsInitial extends TeamsState {
  const TeamsInitial();
  @override
  List<Object> get props => [];
}

class TeamsLoading extends TeamsState {
  const TeamsLoading();
  @override
  List<Object> get props => [];
}

class TeamsLoaded extends TeamsState {
  final List<Team> teams;
  const TeamsLoaded(this.teams);
  @override
  List<Object> get props => [teams];
}

class TeamsError extends TeamsState {
  final String message;
  const TeamsError(this.message);
  @override
  List<Object> get props => [message];
}
