import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/question_repository.dart';

@injectable
class ImportQuestionsUseCase {
  final QuestionRepository _repository;
  const ImportQuestionsUseCase(this._repository);

  Future<Either<Failure, int>> call(String filePath) =>
      _repository.importFromFile(filePath);
}
