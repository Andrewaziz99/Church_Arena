import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../services/sync/supabase_sync_service.dart';
import '../../domain/entities/team.dart';
import '../../domain/repositories/team_repository.dart';
import '../datasources/team_local_datasource.dart';
import '../models/team_isar_model.dart';

@LazySingleton(as: TeamRepository)
class TeamRepositoryImpl implements TeamRepository {
  final TeamLocalDataSource _dataSource;
  TeamRepositoryImpl(this._dataSource);

  final _sync = SupabaseSyncService.instance;

  @override
  Future<Either<Failure, List<Team>>> getTeams() async {
    try {
      final models = await _dataSource.getTeams();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      AppLogger.e('getTeams: $e');
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Team>> saveTeam(Team team) async {
    try {
      await _dataSource.saveTeam(TeamIsarModel.fromEntity(team));
      unawaited(_sync.syncTeamUp(team));
      return Right(team);
    } catch (e) {
      AppLogger.e('saveTeam: $e');
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteTeam(String id) async {
    try {
      await _dataSource.deleteTeam(id);
      unawaited(_sync.deleteTeamRemote(id));
      return const Right(unit);
    } catch (e) {
      AppLogger.e('deleteTeam: $e');
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Team>> updateScore(String id, int delta) async {
    try {
      final model = await _dataSource.getTeam(id);
      if (model == null) return Left(NotFoundFailure('Team not found'));
      final updated = TeamIsarModel(
        id: model.id,
        name: model.name,
        color: model.color,
        score: (model.score + delta).clamp(0, 999999),
        logoPath: model.logoPath,
        isActive: model.isActive,
        section: model.section,
        members: model.members,
      );
      await _dataSource.saveTeam(updated);
      unawaited(_sync.syncTeamUp(updated.toEntity()));
      return Right(updated.toEntity());
    } catch (e) {
      AppLogger.e('updateScore: $e');
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Team>> resetScore(String id) async {
    try {
      final model = await _dataSource.getTeam(id);
      if (model == null) return Left(NotFoundFailure('Team not found'));
      final updated = TeamIsarModel(
        id: model.id,
        name: model.name,
        color: model.color,
        score: 0,
        logoPath: model.logoPath,
        isActive: model.isActive,
        section: model.section,
        members: model.members,
      );
      await _dataSource.saveTeam(updated);
      unawaited(_sync.syncTeamUp(updated.toEntity()));
      return Right(updated.toEntity());
    } catch (e) {
      AppLogger.e('resetScore: $e');
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> resetAllScores() async {
    try {
      final models = await _dataSource.getTeams();
      final zeroed = models
          .map((m) => TeamIsarModel(
                id: m.id,
                name: m.name,
                color: m.color,
                score: 0,
                logoPath: m.logoPath,
                isActive: m.isActive,
                section: m.section,
                members: m.members,
              ))
          .toList();
      await _dataSource.updateAllTeams(zeroed);
      unawaited(_sync.syncTeamsUp(zeroed.map((m) => m.toEntity()).toList()));
      return const Right(unit);
    } catch (e) {
      AppLogger.e('resetAllScores: $e');
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
