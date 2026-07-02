import 'dart:async';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:dartz/dartz.dart';
import 'package:excel/excel.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../services/sync/supabase_sync_service.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/question.dart';
import '../../domain/repositories/question_repository.dart';
import '../datasources/question_local_datasource.dart';
import '../models/category_isar_model.dart';
import '../models/question_isar_model.dart';

@LazySingleton(as: QuestionRepository)
class QuestionRepositoryImpl implements QuestionRepository {
  final QuestionLocalDataSource _dataSource;
  final _uuid = const Uuid();
  final _sync = SupabaseSyncService.instance;

  QuestionRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, List<Question>>> getQuestions({
    String? categoryId,
    DifficultyLevel? difficulty,
  }) async {
    try {
      final models = await _dataSource.getQuestions(
        categoryId: categoryId,
        difficulty: difficulty?.name,
      );
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      AppLogger.e('getQuestions: $e');
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Question>> saveQuestion(Question question) async {
    try {
      await _dataSource.saveQuestion(QuestionIsarModel.fromEntity(question));
      unawaited(_sync.syncQuestionUp(question));
      return Right(question);
    } catch (e) {
      AppLogger.e('saveQuestion: $e');
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteQuestion(String id) async {
    try {
      await _dataSource.deleteQuestion(id);
      unawaited(_sync.deleteQuestionRemote(id));
      return const Right(unit);
    } catch (e) {
      AppLogger.e('deleteQuestion: $e');
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> importFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return Left(ImportFailure('File not found: $filePath'));
      final ext = filePath.toLowerCase().split('.').last;

      // Build category name → id map so the CSV can reference categories by name.
      final catModels = await _dataSource.getCategories();
      final nameToId = <String, String>{
        for (final c in catModels) c.name.toLowerCase().trim(): c.id,
      };

      List<Question> questions = [];
      if (ext == 'csv') {
        questions = await _importFromCsv(file, nameToId);
      } else if (ext == 'xlsx' || ext == 'xls') {
        questions = await _importFromExcel(file, nameToId);
      } else {
        return Left(ImportFailure('Unsupported format: $ext'));
      }
      if (questions.isEmpty) return const Right(0);
      await _dataSource.saveQuestions(questions.map(QuestionIsarModel.fromEntity).toList());
      unawaited(_sync.syncQuestionsUp(questions));
      return Right(questions.length);
    } catch (e) {
      AppLogger.e('importFromFile: $e');
      return Left(ImportFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getCategories() async {
    try {
      final models = await _dataSource.getCategories();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      AppLogger.e('getCategories: $e');
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Category>> saveCategory(Category category) async {
    try {
      await _dataSource.saveCategory(CategoryIsarModel.fromEntity(category));
      unawaited(_sync.syncCategoryUp(category));
      return Right(category);
    } catch (e) {
      AppLogger.e('saveCategory: $e');
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteCategory(String id) async {
    try {
      await _dataSource.deleteCategory(id);
      unawaited(_sync.deleteCategoryRemote(id));
      return const Right(unit);
    } catch (e) {
      AppLogger.e('deleteCategory: $e');
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> clearAllQuestions() async {
    try {
      await _dataSource.deleteAllQuestions();
      unawaited(_sync.clearAllQuestionsRemote());
      return const Right(unit);
    } catch (e) {
      AppLogger.e('clearAllQuestions: $e');
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> reorderQuestions(List<String> orderedIds) async {
    try {
      await _dataSource.reorderQuestions(orderedIds);
      return const Right(unit);
    } catch (e) {
      AppLogger.e('reorderQuestions: $e');
      return Left(DatabaseFailure(e.toString()));
    }
  }

  // ── CSV / Excel import helpers ─────────────────────────────────────────────

  Future<List<Question>> _importFromCsv(
      File file, Map<String, String> nameToId) async {
    final raw = await file.readAsString();
    // Handle both \r\n and \n line endings
    final rows = const CsvToListConverter().convert(raw, eol: '\n');
    final out = <Question>[];
    for (var i = 1; i < rows.length; i++) {
      final r = rows[i];
      if (r.length < 5) continue;
      final q = _row(
        r[0].toString(), r[1].toString(), r[2].toString(),
        r[3].toString(), r[4].toString(),
        answer: r.length > 5 ? r[5]?.toString() : null,
        opts:   r.length > 6 ? r[6]?.toString() : null,
        wrongPts: r.length > 7 ? r[7]?.toString() : null,
        nameToId: nameToId,
      );
      if (q != null) out.add(q);
    }
    return out;
  }

  Future<List<Question>> _importFromExcel(
      File file, Map<String, String> nameToId) async {
    final excel = Excel.decodeBytes(await file.readAsBytes());
    final out = <Question>[];
    for (final table in excel.tables.values) {
      for (var i = 1; i < table.rows.length; i++) {
        final r = table.rows[i];
        if (r.length < 5) continue;
        final q = _row(
          r[0]?.value?.toString() ?? '',
          r[1]?.value?.toString() ?? 'default',
          r[2]?.value?.toString() ?? 'text',
          r[3]?.value?.toString() ?? 'easy',
          r[4]?.value?.toString() ?? '10',
          answer:   r.length > 5 ? r[5]?.value?.toString() : null,
          opts:     r.length > 6 ? r[6]?.value?.toString() : null,
          wrongPts: r.length > 7 ? r[7]?.value?.toString() : null,
          nameToId: nameToId,
        );
        if (q != null) out.add(q);
      }
    }
    return out;
  }

  Question? _row(
    String text, String cat, String typeStr, String diffStr, String pts, {
    String? answer,
    String? opts,
    String? wrongPts,
    required Map<String, String> nameToId,
  }) {
    if (text.trim().isEmpty) return null;
    // Look up category by name (case-insensitive); fall back to raw string as ID
    final resolvedCat = nameToId[cat.toLowerCase().trim()] ?? cat.trim();
    final type = QuestionType.values.firstWhere(
      (t) => t.name.toLowerCase() == typeStr.toLowerCase().trim(),
      orElse: () => QuestionType.text,
    );
    final diff = DifficultyLevel.values.firstWhere(
      (d) => d.name.toLowerCase() == diffStr.toLowerCase().trim(),
      orElse: () => DifficultyLevel.easy,
    );
    return Question(
      id: _uuid.v4(),
      text: text.trim(),
      categoryId: resolvedCat,
      type: type,
      difficulty: diff,
      points: int.tryParse(pts.trim()) ?? 10,
      wrongPoints: int.tryParse(wrongPts?.trim() ?? '') ?? 1,
      correctAnswer: (answer?.trim().isEmpty ?? true) ? null : answer?.trim(),
      options: opts
              ?.split(';')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
    );
  }
}
