import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../services/sync/remote_sync_bus.dart';
import '../../../../services/sync/supabase_realtime_manager.dart';
import '../../../../services/sync/supabase_sync_service.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/question.dart';
import '../../domain/usecases/clear_all_questions_usecase.dart';
import '../../domain/usecases/delete_question_usecase.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/get_questions_usecase.dart';
import '../../domain/usecases/import_questions_usecase.dart';
import '../../domain/usecases/reorder_questions_usecase.dart';
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
  final ClearAllQuestionsUseCase clearAllQuestions;
  final ReorderQuestionsUseCase reorderQuestions;

  StreamSubscription<String>? _remoteSub;
  Timer? _debounceTimer;

  QuestionsBloc({
    required this.getQuestions,
    required this.saveQuestion,
    required this.deleteQuestion,
    required this.importQuestions,
    required this.getCategories,
    required this.saveCategory,
    required this.clearAllQuestions,
    required this.reorderQuestions,
  }) : super(const QuestionsInitial()) {
    on<LoadQuestions>(_onLoadQuestions);
    on<_RemoteRefreshQuestions>(_onRemoteRefreshQuestions);
    on<LoadCategories>(_onLoadCategories);
    on<SaveQuestion>(_onSaveQuestion);
    on<DeleteQuestion>(_onDeleteQuestion);
    on<ImportQuestions>(_onImportQuestions);
    on<FilterByCategory>(_onFilterByCategory);
    on<FilterByDifficulty>(_onFilterByDifficulty);
    on<SaveCategory>(_onSaveCategory);
    on<ClearAllQuestions>(_onClearAllQuestions);
    on<FetchFromCloud>(_onFetchFromCloud);
    on<PushToCloud>(_onPushToCloud);
    on<ReorderQuestions>(_onReorderQuestions);

    // Silent background refresh when a remote Supabase change arrives.
    // Debounced 800 ms so burst realtime events collapse into one reload.
    _remoteSub = RemoteSyncBus.instance.stream.listen((table) {
      if (table == 'questions') {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 800), () {
          if (!isClosed) add(const _RemoteRefreshQuestions());
        });
      }
    });
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    _remoteSub?.cancel();
    return super.close();
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

  /// Silent background refresh — no loading spinner, preserves current filters.
  Future<void> _onRemoteRefreshQuestions(
    _RemoteRefreshQuestions event,
    Emitter<QuestionsState> emit,
  ) async {
    final questionsResult = await getQuestions();
    final categoriesResult = await getCategories();
    questionsResult.fold(
      (failure) => null, // silently ignore errors on background refresh
      (questions) => categoriesResult.fold(
        (failure) => null,
        (categories) {
          if (state is QuestionsLoaded) {
            final current = state as QuestionsLoaded;
            emit(current.copyWith(
              questions: questions,
              categories: categories,
            ));
          } else {
            emit(QuestionsLoaded(questions: questions, categories: categories));
          }
        },
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

  Future<void> _onClearAllQuestions(
    ClearAllQuestions event,
    Emitter<QuestionsState> emit,
  ) async {
    final result = await clearAllQuestions();
    result.fold(
      (failure) => emit(QuestionsError(failure.message)),
      (_) => add(const LoadQuestions()),
    );
  }

  Future<void> _onFetchFromCloud(
    FetchFromCloud event,
    Emitter<QuestionsState> emit,
  ) async {
    emit(const QuestionsLoading());
    await SupabaseRealtimeManager.instance.pullAll();
    add(const LoadQuestions());
  }

  Future<void> _onPushToCloud(
    PushToCloud event,
    Emitter<QuestionsState> emit,
  ) async {
    emit(const QuestionsPushing());

    // Read all local data
    final catsResult = await getCategories();
    final qsResult = await getQuestions();

    int catCount = 0;
    int qCount = 0;

    await catsResult.fold(
      (_) async {},
      (cats) async {
        if (cats.isNotEmpty) {
          await SupabaseSyncService.instance.syncCategoriesUp(cats);
          catCount = cats.length;
        }
      },
    );

    await qsResult.fold(
      (_) async {},
      (qs) async {
        if (qs.isNotEmpty) {
          await SupabaseSyncService.instance.syncQuestionsUp(qs);
          qCount = qs.length;
        }
      },
    );

    emit(QuestionsPushed(categoriesCount: catCount, questionsCount: qCount));
    add(const LoadQuestions());
  }

  /// Saves new sort_order for all questions in the dragged order,
  /// then silently refreshes (no loading spinner).
  Future<void> _onReorderQuestions(
    ReorderQuestions event,
    Emitter<QuestionsState> emit,
  ) async {
    // Optimistically update the displayed list immediately.
    if (state is QuestionsLoaded) {
      final current = state as QuestionsLoaded;
      final reordered = List<Question>.from(current.questions);
      // Re-sort by the orderedIds list.
      final indexMap = {for (int i = 0; i < event.orderedIds.length; i++) event.orderedIds[i]: i};
      reordered.sort((a, b) =>
          (indexMap[a.id] ?? 0).compareTo(indexMap[b.id] ?? 0));
      emit(current.copyWith(questions: reordered));
    }
    // Persist to DB.
    await reorderQuestions(event.orderedIds);
  }
}
