import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../domain/competition_result.dart';

/// Singleton data source for persisted competition results.
class ResultLocalDataSource {
  static final ResultLocalDataSource instance = ResultLocalDataSource._();
  ResultLocalDataSource._();

  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<void> save(CompetitionResult result) async {
    final db = await _db;
    await db.insert(
      'competition_results',
      result.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Returns all results ordered by most recent first.
  Future<List<CompetitionResult>> getAll() async {
    final db = await _db;
    final rows = await db.query(
      'competition_results',
      orderBy: 'completed_at DESC',
    );
    return rows.map(CompetitionResult.fromMap).toList();
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('competition_results', where: 'id = ?', whereArgs: [id]);
  }
}
