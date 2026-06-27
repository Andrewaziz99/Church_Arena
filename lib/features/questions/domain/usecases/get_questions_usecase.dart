import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/question.dart';
import '../repositories/question_repository.dart';

@injectable
class GetQuestionsUseCase {
  final QuestionRepository _repository;
  const GetQuestionsUseCase(this._repository);

  Future<Either<Failure, List<Question>>> call({
    String? categoryId,
    DifficultyLevel? difficulty,
  }) =>
      _repository.getQuestions(categoryId: categoryId, difficulty: difficulty);
}
