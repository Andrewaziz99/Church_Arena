import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/category_isar_model.dart';
import '../models/question_isar_model.dart';

@lazySingleton
class QuestionLocalDataSource {
  final DatabaseHelper _db;
  QuestionLocalDataSource(this._db);

  Future<List<QuestionIsarModel>> getQuestions({
    String? categoryId,
    String? difficulty,
  }) async {
    final db = await _db.database;
    final conditions = <String>[];
    final args = <dynamic>[];
    if (categoryId != null) { conditions.add('category_id = ?'); args.add(categoryId); }
    if (difficulty != null) { conditions.add('difficulty = ?'); args.add(difficulty); }
    final where = conditions.isEmpty ? null : conditions.join(' AND ');
    final maps = await db.query('questions', where: where, whereArgs: args.isEmpty ? null : args);
    return maps.map(QuestionIsarModel.fromMap).toList();
  }

  Future<QuestionIsarModel?> getQuestion(String id) async {
    final db = await _db.database;
    final maps = await db.query('questions', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return QuestionIsarModel.fromMap(maps.first);
  }

  Future<void> saveQuestion(QuestionIsarModel model) async {
    final db = await _db.database;
    await db.insert('questions', model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteQuestion(String id) async {
    final db = await _db.database;
    await db.delete('questions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> saveQuestions(List<QuestionIsarModel> models) async {
    final db = await _db.database;
    final batch = db.batch();
    for (final m in models) {
      batch.insert('questions', m.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<CategoryIsarModel>> getCategories() async {
    final db = await _db.database;
    final maps = await db.query('categories');
    return maps.map(CategoryIsarModel.fromMap).toList();
  }

  Future<void> saveCategory(CategoryIsarModel model) async {
    final db = await _db.database;
    await db.insert('categories', model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteCategory(String id) async {
    final db = await _db.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllQuestions() async {
    final db = await _db.database;
    await db.delete('questions');
  }
}
