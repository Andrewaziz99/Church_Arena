import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/team_repository.dart';

@injectable
class DeleteTeamUseCase {
  final TeamRepository _repository;
  const DeleteTeamUseCase(this._repository);

  Future<Either<Failure, Unit>> call(String id) => _repository.deleteTeam(id);
}
