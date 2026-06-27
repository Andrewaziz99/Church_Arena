import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/team.dart';

abstract class TeamRepository {
  Future<Either<Failure, List<Team>>> getTeams();
  Future<Either<Failure, Team>> saveTeam(Team team);
  Future<Either<Failure, Unit>> deleteTeam(String id);
  Future<Either<Failure, Team>> updateScore(String id, int delta);
  Future<Either<Failure, Team>> resetScore(String id);
  Future<Either<Failure, Unit>> resetAllScores();
}
