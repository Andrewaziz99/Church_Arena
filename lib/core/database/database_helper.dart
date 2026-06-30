import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

/// Singleton SQLite database manager (Windows Desktop via sqflite_common_ffi).
class DatabaseHelper {
  static const _dbName = 'church_arena.db';
  static const _dbVersion = 5;

  static final DatabaseHelper instance = DatabaseHelper._();
  DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE teams (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        score INTEGER NOT NULL DEFAULT 0,
        logo_path TEXT,
        is_active INTEGER NOT NULL DEFAULT 0,
        section TEXT NOT NULL DEFAULT '',
        members TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute('''
      CREATE TABLE questions (
        id TEXT PRIMARY KEY,
        text TEXT NOT NULL,
        category_id TEXT NOT NULL,
        type TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        points INTEGER NOT NULL,
        wrong_points INTEGER NOT NULL DEFAULT 1,
        media_path TEXT,
        correct_answer TEXT,
        options TEXT NOT NULL DEFAULT '',
        is_used INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        question_ids TEXT NOT NULL DEFAULT '',
        section TEXT NOT NULL DEFAULT '',
        round_type TEXT NOT NULL DEFAULT ''
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE teams ADD COLUMN section TEXT NOT NULL DEFAULT ''");
      await db.execute("ALTER TABLE categories ADD COLUMN section TEXT NOT NULL DEFAULT ''");
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE teams ADD COLUMN members TEXT NOT NULL DEFAULT ''");
    }
    if (oldVersion < 4) {
      await db.execute("ALTER TABLE categories ADD COLUMN round_type TEXT NOT NULL DEFAULT ''");
    }
    if (oldVersion < 5) {
      await db.execute("ALTER TABLE questions ADD COLUMN wrong_points INTEGER NOT NULL DEFAULT 1");
    }
  }
}
