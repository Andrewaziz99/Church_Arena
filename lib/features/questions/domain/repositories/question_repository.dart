import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/category.dart';
import '../entities/question.dart';

abstract class QuestionRepository {
  Future<Either<Failure, List<Question>>> getQuestions({
    String? categoryId,
    DifficultyLevel? difficulty,
  });
  Future<Either<Failure, Question>> saveQuestion(Question question);
  Future<Either<Failure, Unit>> deleteQuestion(String id);
  Future<Either<Failure, int>> importFromFile(String filePath);
  Future<Either<Failure, List<Category>>> getCategories();
  Future<Either<Failure, Category>> saveCategory(Category category);
  Future<Either<Failure, Unit>> deleteCategory(String id);
}
