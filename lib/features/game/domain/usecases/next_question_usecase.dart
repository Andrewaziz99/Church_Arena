import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/game_session.dart';
import '../repositories/game_repository.dart';

@injectable
class NextQuestionUseCase {
  final GameRepository _repository;
  const NextQuestionUseCase(this._repository);

  Future<Either<Failure, GameSession>> call(GameSession session) async {
    final currentQ = session.questions[session.currentQuestionIndex];
    final updated = session.copyWith(
      currentQuestionIndex: session.currentQuestionIndex + 1,
      usedQuestionIds: [...session.usedQuestionIds, currentQ.id],
      status: GameStatus.active,
      timerRemaining: session.timerSeconds,
      buzzedTeamId: null,
    );
    final result = await _repository.saveSession(updated);
    return result.fold(
      Left.new,
      (_) => Right(updated),
    );
  }
}
