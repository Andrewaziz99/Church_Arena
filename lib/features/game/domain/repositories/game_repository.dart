import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/game_session.dart';

abstract class GameRepository {
  Future<Either<Failure, GameSession?>> getActiveSession();
  Future<Either<Failure, Unit>> saveSession(GameSession session);
  Future<Either<Failure, Unit>> clearSession();
}
