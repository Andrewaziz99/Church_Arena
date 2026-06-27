import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/team_isar_model.dart';

@lazySingleton
class TeamLocalDataSource {
  final DatabaseHelper _db;
  TeamLocalDataSource(this._db);

  Future<List<TeamIsarModel>> getTeams() async {
    final db = await _db.database;
    final maps = await db.query('teams');
    return maps.map(TeamIsarModel.fromMap).toList();
  }

  Future<TeamIsarModel?> getTeam(String id) async {
    final db = await _db.database;
    final maps = await db.query('teams', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return TeamIsarModel.fromMap(maps.first);
  }

  Future<void> saveTeam(TeamIsarModel model) async {
    final db = await _db.database;
    await db.insert('teams', model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteTeam(String id) async {
    final db = await _db.database;
    await db.delete('teams', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateAllTeams(List<TeamIsarModel> models) async {
    final db = await _db.database;
    final batch = db.batch();
    for (final m in models) {
      batch.insert('teams', m.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }
}
