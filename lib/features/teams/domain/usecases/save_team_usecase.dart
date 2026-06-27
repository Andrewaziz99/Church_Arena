import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/team.dart';
import '../repositories/team_repository.dart';

@injectable
class SaveTeamUseCase {
  final TeamRepository _repository;
  const SaveTeamUseCase(this._repository);

  Future<Either<Failure, Team>> call(Team team) => _repository.saveTeam(team);
}
