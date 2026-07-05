import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

/// Singleton SQLite database manager (Windows Desktop via sqflite_common_ffi).
class DatabaseHelper {
  static const _dbName = 'church_arena.db';
  static const _dbVersion = 7;

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

    // On desktop, getDatabasesPath() returns the cwd (the install dir on
    // Windows — C:\Program Files\...) which is write-protected, causing
    // PathAccessException / errno 5. Store the database in the user's
    // Documents\Church Arena folder instead — always writable and easy to find.
    final String dbPath;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final docs = await getApplicationDocumentsDirectory();
      dbPath = join(docs.path, 'Church Arena');
    } else {
      dbPath = await getDatabasesPath();
    }

    await Directory(dbPath).create(recursive: true);
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        // WAL mode allows one writer + concurrent readers — eliminates most
        // "database is locked" (code 5) errors from parallel Supabase sync.
        await db.execute('PRAGMA journal_mode=WAL');
        // Wait up to 5 s before giving up on a lock instead of failing instantly.
        await db.execute('PRAGMA busy_timeout=5000');
      },
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
        is_used INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0
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
    await db.execute('''
      CREATE TABLE competition_results (
        id TEXT PRIMARY KEY,
        completed_at TEXT NOT NULL,
        teams_json TEXT NOT NULL
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
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS competition_results (
          id TEXT PRIMARY KEY,
          completed_at TEXT NOT NULL,
          teams_json TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 7) {
      await db.execute(
        "ALTER TABLE questions ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0",
      );
    }
  }
}
