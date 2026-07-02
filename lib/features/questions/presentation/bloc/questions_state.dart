part of 'questions_bloc.dart';

abstract class QuestionsState extends Equatable {
  const QuestionsState();
}

class QuestionsInitial extends QuestionsState {
  const QuestionsInitial();
  @override
  List<Object?> get props => [];
}

class QuestionsLoading extends QuestionsState {
  const QuestionsLoading();
  @override
  List<Object?> get props => [];
}

class QuestionsLoaded extends QuestionsState {
  final List<Question> questions;
  final List<Category> categories;
  final String? filterCategory;
  final DifficultyLevel? filterDifficulty;

  const QuestionsLoaded({
    required this.questions,
    required this.categories,
    this.filterCategory,
    this.filterDifficulty,
  });

  List<Question> get filteredQuestions {
    return questions.where((q) {
      final catMatch = filterCategory == null || q.categoryId == filterCategory;
      final diffMatch = filterDifficulty == null || q.difficulty == filterDifficulty;
      return catMatch && diffMatch;
    }).toList();
  }

  QuestionsLoaded copyWith({
    List<Question>? questions,
    List<Category>? categories,
    Object? filterCategory = _sentinel,
    Object? filterDifficulty = _sentinel,
  }) {
    return QuestionsLoaded(
      questions: questions ?? this.questions,
      categories: categories ?? this.categories,
      filterCategory: filterCategory == _sentinel
          ? this.filterCategory
          : filterCategory as String?,
      filterDifficulty: filterDifficulty == _sentinel
          ? this.filterDifficulty
          : filterDifficulty as DifficultyLevel?,
    );
  }

  @override
  List<Object?> get props => [questions, categories, filterCategory, filterDifficulty];
}

const _sentinel = Object();

class QuestionsError extends QuestionsState {
  final String message;
  const QuestionsError(this.message);
  @override
  List<Object?> get props => [message];
}

class QuestionsImporting extends QuestionsState {
  const QuestionsImporting();
  @override
  List<Object?> get props => [];
}

class QuestionsImported extends QuestionsState {
  final int count;
  const QuestionsImported(this.count);
  @override
  List<Object?> get props => [count];
}

class QuestionsPushing extends QuestionsState {
  const QuestionsPushing();
  @override
  List<Object?> get props => [];
}

class QuestionsPushed extends QuestionsState {
  final int categoriesCount;
  final int questionsCount;
  const QuestionsPushed({required this.categoriesCount, required this.questionsCount});
  @override
  List<Object?> get props => [categoriesCount, questionsCount];
}
