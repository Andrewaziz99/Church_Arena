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

class ClearAllQuestions extends QuestionsEvent {
  const ClearAllQuestions();
  @override
  List<Object?> get props => [];
}

/// Internal event fired by the RemoteSyncBus listener.
/// Does NOT show a loading spinner — refreshes silently so the UI never flashes.
class _RemoteRefreshQuestions extends QuestionsEvent {
  const _RemoteRefreshQuestions();
  @override
  List<Object?> get props => [];
}

/// Triggered by the "Sync from cloud" button.
/// Pulls all data from Supabase into local SQLite, then reloads.
class FetchFromCloud extends QuestionsEvent {
  const FetchFromCloud();
  @override
  List<Object?> get props => [];
}

/// Triggered by the "Upload to cloud" button.
/// Bulk-upserts all local categories + questions to Supabase.
class PushToCloud extends QuestionsEvent {
  const PushToCloud();
  @override
  List<Object?> get props => [];
}

/// Drag-to-reorder: saves new sort_order for each question.
/// [orderedIds] is the full list of question IDs in the desired display order.
class ReorderQuestions extends QuestionsEvent {
  final List<String> orderedIds;
  const ReorderQuestions(this.orderedIds);
  @override
  List<Object?> get props => [orderedIds];
}
