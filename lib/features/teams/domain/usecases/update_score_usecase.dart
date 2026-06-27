import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/team.dart';
import '../repositories/team_repository.dart';

@injectable
class UpdateScoreUseCase {
  final TeamRepository _repository;
  const UpdateScoreUseCase(this._repository);

  Future<Either<Failure, Team>> call(String teamId, int delta) =>
      _repository.updateScore(teamId, delta);
}
