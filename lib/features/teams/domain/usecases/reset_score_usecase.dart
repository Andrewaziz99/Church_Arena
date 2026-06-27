import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/team_repository.dart';

@injectable
class ResetScoreUseCase {
  final TeamRepository _repository;
  const ResetScoreUseCase(this._repository);

  Future<Either<Failure, Unit>> call(String id) => _repository.resetAllScores();
}
