import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/category.dart';
import '../repositories/question_repository.dart';

@injectable
class SaveCategoryUseCase {
  final QuestionRepository _repository;
  const SaveCategoryUseCase(this._repository);

  Future<Either<Failure, Category>> call(Category category) =>
      _repository.saveCategory(category);
}
