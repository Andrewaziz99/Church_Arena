import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../../../features/teams/domain/entities/team.dart';
import '../../../../services/sync/supabase_sync_service.dart';
import '../../../scoreboard/data/result_local_datasource.dart';
import '../../../scoreboard/domain/competition_result.dart';

part 'scoreboard_event.dart';
part 'scoreboard_state.dart';

@injectable
class ScoreboardBloc extends Bloc<ScoreboardEvent, ScoreboardState> {
  final _ds = ResultLocalDataSource.instance;

  ScoreboardBloc() : super(const ScoreboardInitial()) {
    on<SaveResult>(_onSaveResult);
    on<LoadScoreboard>(_onLoadScoreboard); // legacy shim
    on<LoadResults>(_onLoadResults);
    on<DeleteResult>(_onDeleteResult);
    on<ResetScoreboard>(_onResetScoreboard);
  }

  /// Save a new competition result, then show it with confetti + history.
  Future<void> _onSaveResult(
    SaveResult event,
    Emitter<ScoreboardState> emit,
  ) async {
    final sorted = [...event.teams]..sort((a, b) => b.score.compareTo(a.score));
    final result = CompetitionResult(
      id: const Uuid().v4(),
      completedAt: DateTime.now(),
      teams: sorted.map(TeamSnapshot.fromTeam).toList(),
    );
    try {
      await _ds.save(result);
    } catch (_) {}
    // Push to Supabase in the background — don't block the UI.
    unawaited(SupabaseSyncService.instance.syncResultUp(result));
    final history = await _loadHistory();
    emit(ScoreboardLoaded(
      rankedTeams: sorted,
      showConfetti: true,
      history: history,
    ));
  }

  /// Legacy: show teams in memory without saving to DB (keeps old flow working).
  Future<void> _onLoadScoreboard(
    LoadScoreboard event,
    Emitter<ScoreboardState> emit,
  ) async {
    final ranked = [...event.teams]..sort((a, b) => b.score.compareTo(a.score));
    final history = await _loadHistory();
    emit(ScoreboardLoaded(rankedTeams: ranked, showConfetti: true, history: history));
  }

  Future<void> _onLoadResults(
    LoadResults event,
    Emitter<ScoreboardState> emit,
  ) async {
    emit(const ScoreboardHistory(loading: true));

    // Pull from Supabase and merge any results that aren't in local SQLite yet.
    final remote = await SupabaseSyncService.instance.fetchResults();
    if (remote.isNotEmpty) {
      final localIds = (await _ds.getAll()).map((r) => r.id).toSet();
      for (final r in remote) {
        if (!localIds.contains(r.id)) {
          try {
            await _ds.save(r);
          } catch (_) {}
        }
      }
    }

    final history = await _loadHistory();
    emit(ScoreboardHistory(history: history));
  }

  Future<void> _onDeleteResult(
    DeleteResult event,
    Emitter<ScoreboardState> emit,
  ) async {
    await _ds.delete(event.id);
    unawaited(SupabaseSyncService.instance.deleteResultRemote(event.id));
    final history = await _loadHistory();
    // Stay in history view after delete
    if (state is ScoreboardLoaded) {
      final s = state as ScoreboardLoaded;
      emit(ScoreboardLoaded(
        rankedTeams: s.rankedTeams,
        showConfetti: false,
        history: history,
      ));
    } else {
      emit(ScoreboardHistory(history: history));
    }
  }

  void _onResetScoreboard(
    ResetScoreboard event,
    Emitter<ScoreboardState> emit,
  ) {
    emit(const ScoreboardInitial());
  }

  Future<List<CompetitionResult>> _loadHistory() async {
    try {
      return await _ds.getAll();
    } catch (_) {
      return [];
    }
  }
}
