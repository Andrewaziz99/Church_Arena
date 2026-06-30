import 'dart:async';
import 'package:flutter/foundation.dart' hide Category;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/questions/domain/entities/category.dart';
import '../../features/questions/domain/entities/question.dart';
import '../../features/teams/domain/entities/team.dart';
import 'connection_log_service.dart';

// ── Supabase configuration ─────────────────────────────────────────────────────
// Credentials can be overridden at build time with --dart-define:
//   SUPABASE_URL=https://xxx.supabase.co
//   SUPABASE_ANON_KEY=eyJ...

const String _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://pfdnvhdtvijoxucldjum.supabase.co',
);
const String _supabaseKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmZG52aGR0dmlqb3h1Y2xkanVtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI3MzQ1ODAsImV4cCI6MjA5ODMxMDU4MH0.yHx2uhd1S8wgFXT4kMwPpebHCdNrVdvGvf7l7OHtrl8',
);

/// Room identifier — scopes synced data to a specific competition room.
/// Updated at startup (and on settings save) from [AppSettings.roomId].
String appRoomId = 'room1';

/// Initialise Supabase. Call once from main().
/// Skips silently if placeholder credentials are still in place.
Future<void> initSupabase() async {
  if (_supabaseUrl.contains('your-project') || _supabaseKey == 'your-anon-key') {
    debugPrint('[Supabase] Skipping init — placeholder credentials');
    return;
  }
  try {
    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseKey);
    debugPrint('[Supabase] Initialized');
  } catch (e) {
    debugPrint('[Supabase] Initialize error: $e');
  }
}

SupabaseClient get _client => Supabase.instance.client;

// ── SupabaseSyncService ────────────────────────────────────────────────────────

class SupabaseSyncService {
  static final SupabaseSyncService instance = SupabaseSyncService._();
  SupabaseSyncService._();

  bool _online = false;
  bool get isOnline => _online;

  final _log = ConnectionLogService.instance;

  // ── Guard ────────────────────────────────────────────────────────────────────

  /// Returns false (and logs once) when Supabase is not yet initialised.
  bool get isReady {
    try {
      Supabase.instance; // throws StateError if not initialized
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _ready() {
    if (!isReady) {
      if (_online) {
        _online = false;
        _log.log('Supabase not initialized — offline mode', level: LogLevel.warning);
      }
      return false;
    }
    return true;
  }

  // ── Teams ─────────────────────────────────────────────────────────────────────

  /// Upsert a single team row.
  Future<void> syncTeamUp(Team team) async {
    if (!_ready()) return;
    try {
      await _client.from('teams').upsert(_teamRow(team));
      _online = true;
    } catch (e) {
      _online = false;
      _log.log('syncTeamUp error: $e', level: LogLevel.error);
      debugPrint('[Supabase] syncTeamUp: $e');
    }
  }

  /// Upsert all teams (bulk — used for initial push or reset-all).
  Future<void> syncTeamsUp(List<Team> teams) async {
    if (!_ready()) return;
    try {
      await _client.from('teams').upsert(teams.map(_teamRow).toList());
      _online = true;
      _log.log('Teams synced ↑ (${teams.length})', level: LogLevel.success);
    } catch (e) {
      _online = false;
      _log.log('syncTeamsUp error: $e', level: LogLevel.error);
    }
  }

  Future<void> deleteTeamRemote(String id) async {
    if (!_ready()) return;
    try {
      await _client.from('teams').delete().eq('id', id);
      _log.log('Team deleted ↑ $id', level: LogLevel.info);
    } catch (e) {
      _log.log('deleteTeamRemote error: $e', level: LogLevel.error);
    }
  }

  /// Pull all teams from Supabase (ordered by score desc).
  Future<List<Map<String, dynamic>>> fetchTeams() async {
    if (!_ready()) return [];
    final sw = Stopwatch()..start();
    try {
      final data = await _client
          .from('teams')
          .select()
          .order('score', ascending: false);
      sw.stop();
      final wasOnline = _online;
      _online = true;
      if (!wasOnline) _log.log('Supabase connected', level: LogLevel.success);
      _log.log(
        'Ping ${sw.elapsedMilliseconds}ms — ${(data as List).length} teams',
        level: LogLevel.info,
      );
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      sw.stop();
      final wasOnline = _online;
      _online = false;
      if (wasOnline) _log.log('Supabase disconnected', level: LogLevel.warning);
      _log.log('fetchTeams error: $e', level: LogLevel.error);
      return [];
    }
  }

  // ── Categories ────────────────────────────────────────────────────────────────

  Future<void> syncCategoryUp(Category category) async {
    if (!_ready()) return;
    try {
      await _client.from('categories').upsert(_categoryRow(category));
      _online = true;
    } catch (e) {
      _online = false;
      _log.log('syncCategoryUp error: $e', level: LogLevel.error);
    }
  }

  Future<void> syncCategoriesUp(List<Category> categories) async {
    if (!_ready()) return;
    try {
      await _client.from('categories').upsert(categories.map(_categoryRow).toList());
      _online = true;
      _log.log('Categories synced ↑ (${categories.length})', level: LogLevel.success);
    } catch (e) {
      _online = false;
      _log.log('syncCategoriesUp error: $e', level: LogLevel.error);
    }
  }

  Future<void> deleteCategoryRemote(String id) async {
    if (!_ready()) return;
    try {
      await _client.from('categories').delete().eq('id', id);
    } catch (e) {
      _log.log('deleteCategoryRemote error: $e', level: LogLevel.error);
    }
  }

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    if (!_ready()) return [];
    try {
      final data = await _client.from('categories').select();
      _online = true;
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _online = false;
      _log.log('fetchCategories error: $e', level: LogLevel.error);
      return [];
    }
  }

  // ── Questions ─────────────────────────────────────────────────────────────────

  Future<void> syncQuestionUp(Question question) async {
    if (!_ready()) return;
    try {
      await _client.from('questions').upsert(_questionRow(question));
      _online = true;
    } catch (e) {
      _online = false;
      _log.log('syncQuestionUp error: $e', level: LogLevel.error);
    }
  }

  Future<void> syncQuestionsUp(List<Question> questions) async {
    if (!_ready()) return;
    try {
      await _client.from('questions').upsert(questions.map(_questionRow).toList());
      _online = true;
      _log.log('Questions synced ↑ (${questions.length})', level: LogLevel.success);
    } catch (e) {
      _online = false;
      _log.log('syncQuestionsUp error: $e', level: LogLevel.error);
    }
  }

  Future<void> deleteQuestionRemote(String id) async {
    if (!_ready()) return;
    try {
      await _client.from('questions').delete().eq('id', id);
    } catch (e) {
      _log.log('deleteQuestionRemote error: $e', level: LogLevel.error);
    }
  }

  Future<void> clearAllQuestionsRemote() async {
    if (!_ready()) return;
    try {
      // Delete all rows — neq('id','') is always-true filter required by Supabase
      await _client.from('questions').delete().neq('id', '');
      _log.log('All questions cleared ↑', level: LogLevel.warning);
    } catch (e) {
      _log.log('clearAllQuestionsRemote error: $e', level: LogLevel.error);
    }
  }

  Future<List<Map<String, dynamic>>> fetchQuestions() async {
    if (!_ready()) return [];
    try {
      final data = await _client.from('questions').select();
      _online = true;
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _online = false;
      _log.log('fetchQuestions error: $e', level: LogLevel.error);
      return [];
    }
  }

  // ── Game session ──────────────────────────────────────────────────────────────

  Future<void> syncGameSession({
    required String sessionId,
    required String section,
    required String status,
    required int currentRound,
    required int currentQuestionIndex,
    String? buzzedTeamId,
    required int timerRemaining,
  }) async {
    if (!_ready()) return;
    try {
      await _client.from('game_sessions').upsert({
        'id': sessionId,
        'room_id': appRoomId,
        'section': section,
        'status': status,
        'current_round': currentRound,
        'current_question_index': currentQuestionIndex,
        'buzzed_team_id': buzzedTeamId,
        'timer_remaining': timerRemaining,
        'updated_at': DateTime.now().toIso8601String(),
      });
      _online = true;
    } catch (e) {
      _online = false;
      _log.log('syncGameSession error: $e', level: LogLevel.error);
    }
  }

  Future<void> publishEvent({
    required String sessionId,
    required String eventType,
    String? teamId,
    Map<String, dynamic>? payload,
  }) async {
    if (!_ready()) return;
    try {
      await _client.from('game_events').insert({
        'session_id': sessionId,
        'event_type': eventType,
        'team_id': teamId,
        'payload': payload,
      });
    } catch (e) {
      _log.log('publishEvent error: $e', level: LogLevel.error);
    }
  }

  // ── Realtime subscriptions ────────────────────────────────────────────────────

  /// Subscribe to per-row changes on the `teams` table.
  RealtimeChannel? listenToTeamChanges(
      void Function(PostgresChangePayload) onEvent) {
    if (!_ready()) return null;
    return _client
        .channel('public:teams:changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'teams',
          callback: onEvent,
        )
        .subscribe();
  }

  /// Subscribe to per-row changes on the `categories` table.
  RealtimeChannel? listenToCategoryChanges(
      void Function(PostgresChangePayload) onEvent) {
    if (!_ready()) return null;
    return _client
        .channel('public:categories:changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'categories',
          callback: onEvent,
        )
        .subscribe();
  }

  /// Subscribe to per-row changes on the `questions` table.
  RealtimeChannel? listenToQuestionChanges(
      void Function(PostgresChangePayload) onEvent) {
    if (!_ready()) return null;
    return _client
        .channel('public:questions:changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'questions',
          callback: onEvent,
        )
        .subscribe();
  }

  /// Subscribe to game session updates (mobile scoreboard).
  RealtimeChannel? listenToGameSession(
    String sessionId,
    void Function(Map<String, dynamic>) onUpdate,
  ) {
    if (!_ready()) return null;
    return _client
        .channel('session-$sessionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'game_sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: sessionId,
          ),
          callback: (payload) {
            final rec = payload.newRecord;
            if (rec.isNotEmpty) onUpdate(rec);
          },
        )
        .subscribe();
  }

  // ── Row builders ──────────────────────────────────────────────────────────────

  static Map<String, dynamic> _teamRow(Team t) => {
        'id': t.id,
        'name': t.name,
        // Flutter Color.value is unsigned 32-bit; PostgreSQL integer is signed 32-bit.
        // .toSigned(32) maps e.g. 0xFF27D9DC → -16749028, which fits in the column.
        'color': t.color.toSigned(32),
        'score': t.score,
        'section': t.section,
        'members': t.members.join('||'),
        'is_active': t.isActive,
        'updated_at': DateTime.now().toIso8601String(),
      };

  static Map<String, dynamic> _categoryRow(Category c) => {
        'id': c.id,
        'name': c.name,
        'color': c.color.toSigned(32),
        'question_ids': c.questionIds.join(';'),
        'section': c.section,
        'round_type': c.roundType,
        'updated_at': DateTime.now().toIso8601String(),
      };

  static Map<String, dynamic> _questionRow(Question q) => {
        'id': q.id,
        'text': q.text,
        'category_id': q.categoryId,
        'type': q.type.name,
        'difficulty': q.difficulty.name,
        'points': q.points,
        'wrong_points': q.wrongPoints,
        'media_path': q.mediaPath,
        'correct_answer': q.correctAnswer,
        'options': q.options.join(';'),
        'is_used': q.isUsed,
        'updated_at': DateTime.now().toIso8601String(),
      };
}
