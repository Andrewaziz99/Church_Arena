import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/question.dart';
import '../repositories/question_repository.dart';

@injectable
class SaveQuestionUseCase {
  final QuestionRepository _repository;
  const SaveQuestionUseCase(this._repository);

  Future<Either<Failure, Question>> call(Question question) =>
      _repository.saveQuestion(question);
}
