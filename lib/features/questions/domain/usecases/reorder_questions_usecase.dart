import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/question_repository.dart';

@lazySingleton
class ReorderQuestionsUseCase {
  final QuestionRepository _repo;
  ReorderQuestionsUseCase(this._repo);

  Future<Either<Failure, Unit>> call(List<String> orderedIds) =>
      _repo.reorderQuestions(orderedIds);
}
