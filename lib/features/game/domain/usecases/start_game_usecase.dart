import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/failures.dart';
import '../../../questions/domain/entities/question.dart';
import '../../../teams/domain/entities/team.dart';
import '../entities/game_session.dart';
import '../repositories/game_repository.dart';

@injectable
class StartGameUseCase {
  final GameRepository _repository;
  const StartGameUseCase(this._repository);

  Future<Either<Failure, GameSession>> call({
    required List<Team> teams,
    required List<Question> questions,
    required int timerSeconds,
  }) async {
    final session = GameSession(
      id: const Uuid().v4(),
      teams: teams,
      questions: questions,
      currentQuestionIndex: 0,
      status: GameStatus.active,
      timerSeconds: timerSeconds,
      timerRemaining: timerSeconds,
    );
    final result = await _repository.saveSession(session);
    return result.fold(
      Left.new,
      (_) => Right(session),
    );
  }
}
