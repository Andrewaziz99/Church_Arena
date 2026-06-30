import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../services/sync/remote_sync_bus.dart';
import '../../domain/entities/team.dart';
import '../../domain/usecases/get_teams_usecase.dart';
import '../../domain/usecases/save_team_usecase.dart';
import '../../domain/usecases/delete_team_usecase.dart';
import '../../domain/usecases/update_score_usecase.dart';
import '../../domain/usecases/reset_score_usecase.dart';

part 'teams_event.dart';
part 'teams_state.dart';

@injectable
class TeamsBloc extends Bloc<TeamsEvent, TeamsState> {
  final GetTeamsUseCase getTeams;
  final SaveTeamUseCase saveTeam;
  final DeleteTeamUseCase deleteTeam;
  final UpdateScoreUseCase updateScore;
  final ResetScoreUseCase resetScore;

  StreamSubscription<String>? _remoteSub;

  TeamsBloc({
    required this.getTeams,
    required this.saveTeam,
    required this.deleteTeam,
    required this.updateScore,
    required this.resetScore,
  }) : super(const TeamsInitial()) {
    on<LoadTeams>(_onLoadTeams);
    on<SaveTeam>(_onSaveTeam);
    on<DeleteTeam>(_onDeleteTeam);
    on<UpdateScore>(_onUpdateScore);
    on<ResetScore>(_onResetScore);
    on<ResetAllScores>(_onResetAllScores);

    // Reload when a remote Supabase change is merged into local SQLite.
    _remoteSub = RemoteSyncBus.instance.stream.listen((table) {
      if (table == 'teams') add(const LoadTeams());
    });
  }

  @override
  Future<void> close() {
    _remoteSub?.cancel();
    return super.close();
  }

  Future<void> _onLoadTeams(LoadTeams event, Emitter<TeamsState> emit) async {
    emit(const TeamsLoading());
    final result = await getTeams();
    result.fold(
      (failure) => emit(TeamsError(failure.message)),
      (teams) => emit(TeamsLoaded(teams)),
    );
  }

  Future<void> _onSaveTeam(SaveTeam event, Emitter<TeamsState> emit) async {
    final result = await saveTeam(event.team);
    result.fold(
      (failure) => emit(TeamsError(failure.message)),
      (_) => add(const LoadTeams()),
    );
  }

  Future<void> _onDeleteTeam(DeleteTeam event, Emitter<TeamsState> emit) async {
    final result = await deleteTeam(event.teamId);
    result.fold(
      (failure) => emit(TeamsError(failure.message)),
      (_) => add(const LoadTeams()),
    );
  }

  Future<void> _onUpdateScore(UpdateScore event, Emitter<TeamsState> emit) async {
    final result = await updateScore(event.teamId, event.delta);
    result.fold(
      (failure) => emit(TeamsError(failure.message)),
      (_) => add(const LoadTeams()),
    );
  }

  Future<void> _onResetScore(ResetScore event, Emitter<TeamsState> emit) async {
    final result = await resetScore(event.teamId);
    result.fold(
      (failure) => emit(TeamsError(failure.message)),
      (_) => add(const LoadTeams()),
    );
  }

  Future<void> _onResetAllScores(ResetAllScores event, Emitter<TeamsState> emit) async {
    final result = await resetScore('');
    result.fold(
      (failure) => emit(TeamsError(failure.message)),
      (_) => add(const LoadTeams()),
    );
  }
}
