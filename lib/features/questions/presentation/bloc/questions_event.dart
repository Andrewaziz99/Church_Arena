part of 'questions_bloc.dart';

abstract class QuestionsEvent extends Equatable {
  const QuestionsEvent();
}

class LoadQuestions extends QuestionsEvent {
  const LoadQuestions();
  @override
  List<Object?> get props => [];
}

class LoadCategories extends QuestionsEvent {
  const LoadCategories();
  @override
  List<Object?> get props => [];
}

class SaveQuestion extends QuestionsEvent {
  final Question question;
  const SaveQuestion(this.question);
  @override
  List<Object?> get props => [question];
}

class DeleteQuestion extends QuestionsEvent {
  final String id;
  const DeleteQuestion(this.id);
  @override
  List<Object?> get props => [id];
}

class ImportQuestions extends QuestionsEvent {
  final String filePath;
  const ImportQuestions(this.filePath);
  @override
  List<Object?> get props => [filePath];
}

class FilterByCategory extends QuestionsEvent {
  final String? categoryId;
  const FilterByCategory(this.categoryId);
  @override
  List<Object?> get props => [categoryId];
}

class FilterByDifficulty extends QuestionsEvent {
  final DifficultyLevel? difficulty;
  const FilterByDifficulty(this.difficulty);
  @override
  List<Object?> get props => [difficulty];
}

class SaveCategory extends QuestionsEvent {
  final Category category;
  const SaveCategory(this.category);
  @override
  List<Object?> get props => [category];
}
