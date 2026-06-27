import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/team.dart';
import '../repositories/team_repository.dart';

@injectable
class GetTeamsUseCase {
  final TeamRepository _repository;
  const GetTeamsUseCase(this._repository);

  Future<Either<Failure, List<Team>>> call() => _repository.getTeams();
}
