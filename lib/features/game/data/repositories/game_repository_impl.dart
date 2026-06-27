import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/repositories/game_repository.dart';

@LazySingleton(as: GameRepository)
class GameRepositoryImpl implements GameRepository {
  GameSession? _session;

  @override
  Future<Either<Failure, GameSession?>> getActiveSession() async {
    return Right(_session);
  }

  @override
  Future<Either<Failure, Unit>> saveSession(GameSession session) async {
    _session = session;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> clearSession() async {
    _session = null;
    return const Right(unit);
  }
}
