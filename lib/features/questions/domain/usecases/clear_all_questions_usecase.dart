import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/question_repository.dart';

@lazySingleton
class ClearAllQuestionsUseCase {
  final QuestionRepository _repo;
  ClearAllQuestionsUseCase(this._repo);

  Future<Either<Failure, Unit>> call() => _repo.clearAllQuestions();
}
