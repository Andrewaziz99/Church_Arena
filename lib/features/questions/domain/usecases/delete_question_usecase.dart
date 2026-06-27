import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/question_repository.dart';

@injectable
class DeleteQuestionUseCase {
  final QuestionRepository _repository;
  const DeleteQuestionUseCase(this._repository);

  Future<Either<Failure, Unit>> call(String id) =>
      _repository.deleteQuestion(id);
}
