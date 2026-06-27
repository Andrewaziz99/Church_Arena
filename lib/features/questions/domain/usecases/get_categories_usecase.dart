import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/category.dart';
import '../repositories/question_repository.dart';

@injectable
class GetCategoriesUseCase {
  final QuestionRepository _repository;
  const GetCategoriesUseCase(this._repository);

  Future<Either<Failure, List<Category>>> call() =>
      _repository.getCategories();
}
