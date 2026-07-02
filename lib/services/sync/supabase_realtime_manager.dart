import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/questions/data/datasources/question_local_datasource.dart';
import '../../features/questions/data/models/category_isar_model.dart';
import '../../features/questions/data/models/question_isar_model.dart';
import '../../features/teams/data/datasources/team_local_datasource.dart';
import '../../features/teams/data/models/team_isar_model.dart';
import 'connection_log_service.dart';
import 'remote_sync_bus.dart';
import 'supabase_sync_service.dart';

/// Manages all realtime Supabase subscriptions for two-way sync.
///
/// On startup it runs an **initial pull** (Supabase → local SQLite) so the
/// local database reflects the latest remote state.  Afterwards it keeps
/// channel subscriptions open so remote inserts, updates, and deletes are
/// immediately merged into local SQLite and the [RemoteSyncBus] notifies the
/// relevant BLoCs to reload.
class SupabaseRealtimeManager {
  static final SupabaseRealtimeManager instance = SupabaseRealtimeManager._();
  SupabaseRealtimeManager._();

  final _log = ConnectionLogService.instance;
  final List<RealtimeChannel> _channels = [];
  bool _started = false;

  // Stored so pullAll() can re-run without needing them passed again.
  TeamLocalDataSource? _teamDs;
  QuestionLocalDataSource? _questionDs;

  // ── Public API ────────────────────────────────────────────────────────────────

  /// Starts realtime sync.  Safe to call multiple times (no-op after first).
  /// Non-blocking — returns immediately; initial pull runs in background.
  Future<void> start({
    required TeamLocalDataSource teamDs,
    required QuestionLocalDataSource questionDs,
  }) async {
    if (_started || !SupabaseSyncService.instance.isReady) return;
    _started = true;
    _teamDs = teamDs;
    _questionDs = questionDs;

    _subscribeToTeams(teamDs);
    _subscribeToCategories(questionDs);
    _subscribeToQuestions(questionDs);

    _log.log('Realtime subscriptions started', level: LogLevel.success);

    // Run initial pull in background — don't block the caller.
    unawaited(_initialPull(teamDs, questionDs));
  }

  /// Pull all remote data into local SQLite on demand (e.g. from a UI button).
  /// Returns the total number of records merged, or -1 if offline/not ready.
  Future<int> pullAll() async {
    if (!SupabaseSyncService.instance.isReady) return -1;
    final tDs = _teamDs;
    final qDs = _questionDs;
    if (tDs == null || qDs == null) return -1;
    await _initialPull(tDs, qDs);
    return 0; // count logged inside _initialPull
  }

  /// Stops all subscriptions.
  void stop() {
    for (final ch in _channels) {
      try {
        ch.unsubscribe();
      } catch (_) {}
    }
    _channels.clear();
    _started = false;
  }

  // ── Initial pull ──────────────────────────────────────────────────────────────

  Future<void> _initialPull(
      TeamLocalDataSource teamDs, QuestionLocalDataSource questionDs) async {
    int teamsCount = 0, categoriesCount = 0, questionsCount = 0;

    // Teams
    final remoteTeams = await SupabaseSyncService.instance.fetchTeams();
    for (final row in remoteTeams) {
      try {
        await teamDs.saveTeam(TeamIsarModel.fromMap(_remapTeamRow(row)));
        teamsCount++;
      } catch (e) {
        debugPrint('[Realtime] team merge error: $e');
      }
    }

    // Categories
    final remoteCategories = await SupabaseSyncService.instance.fetchCategories();
    for (final row in remoteCategories) {
      try {
        await questionDs.saveCategory(CategoryIsarModel.fromMap(_remapCategoryRow(row)));
        categoriesCount++;
      } catch (e) {
        debugPrint('[Realtime] category merge error: $e');
      }
    }

    // Questions
    final remoteQuestions = await SupabaseSyncService.instance.fetchQuestions();
    for (final row in remoteQuestions) {
      try {
        await questionDs.saveQuestion(QuestionIsarModel.fromMap(_remapQuestionRow(row)));
        questionsCount++;
      } catch (e) {
        debugPrint('[Realtime] question merge error: $e');
      }
    }

    if (teamsCount > 0 || categoriesCount > 0 || questionsCount > 0) {
      RemoteSyncBus.instance.notify('teams');
      RemoteSyncBus.instance.notify('questions');
      _log.log(
        'Initial pull: $teamsCount teams, $categoriesCount categories, $questionsCount questions',
        level: LogLevel.success,
      );
    } else {
      _log.log('Initial pull: nothing to merge (local is up-to-date)', level: LogLevel.info);
    }
  }

  // ── Realtime subscriptions ────────────────────────────────────────────────────

  void _subscribeToTeams(TeamLocalDataSource teamDs) {
    final ch = SupabaseSyncService.instance.listenToTeamChanges((payload) async {
      switch (payload.eventType) {
        case PostgresChangeEvent.insert:
        case PostgresChangeEvent.update:
          final row = payload.newRecord;
          if (row.isEmpty) return;
          try {
            await teamDs.saveTeam(TeamIsarModel.fromMap(_remapTeamRow(row)));
            RemoteSyncBus.instance.notify('teams');
            _log.log('↓ Team updated: ${row['name']}', level: LogLevel.info);
          } catch (e) {
            _log.log('Team merge error: $e', level: LogLevel.error);
          }
        case PostgresChangeEvent.delete:
          final id = payload.oldRecord['id'] as String?;
          if (id != null) {
            await teamDs.deleteTeam(id);
            RemoteSyncBus.instance.notify('teams');
            _log.log('↓ Team deleted: $id', level: LogLevel.info);
          }
        default:
          break;
      }
    });
    if (ch != null) _channels.add(ch);
  }

  void _subscribeToCategories(QuestionLocalDataSource questionDs) {
    final ch = SupabaseSyncService.instance.listenToCategoryChanges((payload) async {
      switch (payload.eventType) {
        case PostgresChangeEvent.insert:
        case PostgresChangeEvent.update:
          final row = payload.newRecord;
          if (row.isEmpty) return;
          try {
            await questionDs.saveCategory(CategoryIsarModel.fromMap(_remapCategoryRow(row)));
            RemoteSyncBus.instance.notify('questions');
            _log.log('↓ Category: ${row['name']}', level: LogLevel.info);
          } catch (e) {
            _log.log('Category merge error: $e', level: LogLevel.error);
          }
        case PostgresChangeEvent.delete:
          final id = payload.oldRecord['id'] as String?;
          if (id != null) {
            await questionDs.deleteCategory(id);
            RemoteSyncBus.instance.notify('questions');
          }
        default:
          break;
      }
    });
    if (ch != null) _channels.add(ch);
  }

  void _subscribeToQuestions(QuestionLocalDataSource questionDs) {
    final ch = SupabaseSyncService.instance.listenToQuestionChanges((payload) async {
      switch (payload.eventType) {
        case PostgresChangeEvent.insert:
        case PostgresChangeEvent.update:
          final row = payload.newRecord;
          if (row.isEmpty) return;
          try {
            await questionDs.saveQuestion(QuestionIsarModel.fromMap(_remapQuestionRow(row)));
            RemoteSyncBus.instance.notify('questions');
            _log.log('↓ Question updated', level: LogLevel.info);
          } catch (e) {
            _log.log('Question merge error: $e', level: LogLevel.error);
          }
        case PostgresChangeEvent.delete:
          final id = payload.oldRecord['id'] as String?;
          if (id != null) {
            await questionDs.deleteQuestion(id);
            RemoteSyncBus.instance.notify('questions');
          }
        default:
          break;
      }
    });
    if (ch != null) _channels.add(ch);
  }

  // ── Row format converters: Supabase → local SQLite ────────────────────────────
  //
  // Supabase returns BOOLEAN columns as Dart [bool]; local SQLite models expect
  // INTEGER (0 / 1).  The helpers below normalise that difference.

  static Map<String, dynamic> _remapTeamRow(Map<String, dynamic> r) => {
        'id': r['id'],
        'name': r['name'],
        // Supabase stores color as signed int32; convert back to unsigned for Flutter.
        'color': (r['color'] as int? ?? 0).toUnsigned(32),
        'score': r['score'] as int? ?? 0,
        'logo_path': r['logo_path'],
        'is_active': _boolToInt(r['is_active']),
        'section': r['section'] ?? '',
        'members': r['members'] ?? '',
      };

  static Map<String, dynamic> _remapCategoryRow(Map<String, dynamic> r) => {
        'id': r['id'],
        'name': r['name'],
        'color': (r['color'] as int? ?? 0).toUnsigned(32),
        'question_ids': r['question_ids'] ?? '',
        'section': r['section'] ?? '',
        'round_type': r['round_type'] ?? '',
      };

  static Map<String, dynamic> _remapQuestionRow(Map<String, dynamic> r) => {
        'id': r['id'],
        'text': r['text'],
        'category_id': r['category_id'] ?? '',
        'type': r['type'] ?? 'text',
        'difficulty': r['difficulty'] ?? 'easy',
        'points': r['points'] as int? ?? 10,
        'wrong_points': r['wrong_points'] as int? ?? 1,
        'media_path': r['media_path'],
        'correct_answer': r['correct_answer'],
        'options': r['options'] ?? '',
        'is_used': _boolToInt(r['is_used']),
      };

  static int _boolToInt(dynamic v) {
    if (v == null) return 0;
    if (v is bool) return v ? 1 : 0;
    if (v is int) return v;
    return 0;
  }
}
