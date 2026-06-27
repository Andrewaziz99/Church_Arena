import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/question.dart';
import '../../domain/usecases/delete_question_usecase.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/get_questions_usecase.dart';
import '../../domain/usecases/import_questions_usecase.dart';
import '../../domain/usecases/save_category_usecase.dart';
import '../../domain/usecases/save_question_usecase.dart';

part 'questions_event.dart';
part 'questions_state.dart';

@injectable
class QuestionsBloc extends Bloc<QuestionsEvent, QuestionsState> {
  final GetQuestionsUseCase getQuestions;
  final SaveQuestionUseCase saveQuestion;
  final DeleteQuestionUseCase deleteQuestion;
  final ImportQuestionsUseCase importQuestions;
  final GetCategoriesUseCase getCategories;
  final SaveCategoryUseCase saveCategory;

  QuestionsBloc({
    required this.getQuestions,
    required this.saveQuestion,
    required this.deleteQuestion,
    required this.importQuestions,
    required this.getCategories,
    required this.saveCategory,
  }) : super(const QuestionsInitial()) {
    on<LoadQuestions>(_onLoadQuestions);
    on<LoadCategories>(_onLoadCategories);
    on<SaveQuestion>(_onSaveQuestion);
    on<DeleteQuestion>(_onDeleteQuestion);
    on<ImportQuestions>(_onImportQuestions);
    on<FilterByCategory>(_onFilterByCategory);
    on<FilterByDifficulty>(_onFilterByDifficulty);
    on<SaveCategory>(_onSaveCategory);
  }

  Future<void> _onLoadQuestions(
    LoadQuestions event,
    Emitter<QuestionsState> emit,
  ) async {
    emit(const QuestionsLoading());
    final questionsResult = await getQuestions();
    final categoriesResult = await getCategories();
    questionsResult.fold(
      (failure) => emit(QuestionsError(failure.message)),
      (questions) => categoriesResult.fold(
        (failure) => emit(QuestionsError(failure.message)),
        (categories) => emit(
          QuestionsLoaded(questions: questions, categories: categories),
        ),
      ),
    );
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<QuestionsState> emit,
  ) async {
    final result = await getCategories();
    result.fold(
      (failure) => emit(QuestionsError(failure.message)),
      (categories) {
        if (state is QuestionsLoaded) {
          emit((state as QuestionsLoaded).copyWith(categories: categories));
        }
      },
    );
  }

  Future<void> _onSaveQuestion(
    SaveQuestion event,
    Emitter<QuestionsState> emit,
  ) async {
    final result = await saveQuestion(event.question);
    result.fold(
      (failure) => emit(QuestionsError(failure.message)),
      (_) => add(const LoadQuestions()),
    );
  }

  Future<void> _onDeleteQuestion(
    DeleteQuestion event,
    Emitter<QuestionsState> emit,
  ) async {
    final result = await deleteQuestion(event.id);
    result.fold(
      (failure) => emit(QuestionsError(failure.message)),
      (_) => add(const LoadQuestions()),
    );
  }

  Future<void> _onImportQuestions(
    ImportQuestions event,
    Emitter<QuestionsState> emit,
  ) async {
    emit(const QuestionsImporting());
    final result = await importQuestions(event.filePath);
    result.fold(
      (failure) => emit(QuestionsError(failure.message)),
      (count) {
        emit(QuestionsImported(count));
        add(const LoadQuestions());
      },
    );
  }

  void _onFilterByCategory(
    FilterByCategory event,
    Emitter<QuestionsState> emit,
  ) {
    if (state is QuestionsLoaded) {
      emit((state as QuestionsLoaded).copyWith(filterCategory: event.categoryId));
    }
  }

  void _onFilterByDifficulty(
    FilterByDifficulty event,
    Emitter<QuestionsState> emit,
  ) {
    if (state is QuestionsLoaded) {
      emit((state as QuestionsLoaded).copyWith(filterDifficulty: event.difficulty));
    }
  }

  Future<void> _onSaveCategory(
    SaveCategory event,
    Emitter<QuestionsState> emit,
  ) async {
    final result = await saveCategory(event.category);
    result.fold(
      (failure) => emit(QuestionsError(failure.message)),
      (_) => add(const LoadQuestions()),
    );
  }
}
