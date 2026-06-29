import 'dart:async';
import 'package:dartz/dartz.dart' as FilterType;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/teams/domain/entities/team.dart';
import 'connection_log_service.dart';

// ── Supabase configuration ─────────────────────────────────────────────────────
// TODO: Fill in your Supabase project URL and anon key after creating the project
// at https://supabase.com → New Project → Settings → API

// define the SUPABASE_URL and SUPABASE_ANON_KEY while building the app using --dart-define

const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://pfdnvhdtvijoxucldjum.supabase.co');
const String _supabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmZG52aGR0dmlqb3h1Y2xkanVtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI3MzQ1ODAsImV4cCI6MjA5ODMxMDU4MH0.yHx2uhd1S8wgFXT4kMwPpebHCdNrVdvGvf7l7OHtrl8');

// ── Room identifier ────────────────────────────────────────────────────────────
// Set a unique ID per device/room before running. E.g. 'room1', 'room2', 'room3'
const appRoomId = 'room1';

/// Initialise Supabase. Call once from main().
Future<void> initSupabase() async {
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseKey);
}

SupabaseClient get _client => Supabase.instance.client;

// ── SupabaseSyncService ────────────────────────────────────────────────────────

class SupabaseSyncService {
  // Singleton
  static final SupabaseSyncService instance = SupabaseSyncService._();
  SupabaseSyncService._();

  bool _online = false;
  bool get isOnline => _online;

  final _log = ConnectionLogService.instance;

  /// Returns false and logs once if Supabase was never initialized
  /// (e.g. placeholder URL / initSupabase() not called yet).
  bool _ready() {
    try {
      Supabase.instance; // throws StateError if not initialized
      return true;
    } catch (_) {
      if (_online) {
        _online = false;
        _log.log('Supabase not initialized — call initSupabase() in main()',
            level: LogLevel.warning);
      }
      return false;
    }
  }

  // ── Teams sync ──────────────────────────────────────────────────────────────

  /// Push all local teams to Supabase (upsert).
  Future<void> syncTeamsUp(List<Team> teams) async {
    if (!_ready()) return;
    try {
      final rows = teams.map((t) => {
        'id': t.id,
        'name': t.name,
        'color': t.color,
        'score': t.score,
        'section': t.section,
        'members': t.members.join('||'),
        'is_active': t.isActive,
        'updated_at': DateTime.now().toIso8601String(),
      }).toList();
      await _client.from('teams').upsert(rows);
      _online = true;
      _log.log('Teams synced (${teams.length} rows)', level: LogLevel.success);
    } catch (e) {
      _online = false;
      _log.log('syncTeamsUp failed: $e', level: LogLevel.error);
      debugPrint('[Supabase] syncTeamsUp error: $e');
    }
  }

  /// Pull teams from Supabase (for read-only scoreboard mobile app).
  Future<List<Map<String, dynamic>>> fetchTeams() async {
    if (!_ready()) return [];
    final sw = Stopwatch()..start();
    try {
      final data = await _client.from('teams').select().order('score', ascending: false);
      sw.stop();
      final wasOnline = _online;
      _online = true;
      if (!wasOnline) {
        _log.log('Supabase connected', level: LogLevel.success);
      }
      _log.log('Ping ${sw.elapsedMilliseconds}ms — ${(data as List).length} teams fetched',
          level: LogLevel.info);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      sw.stop();
      final wasOnline = _online;
      _online = false;
      if (wasOnline) {
        _log.log('Supabase disconnected', level: LogLevel.warning);
      }
      _log.log('fetchTeams error: $e', level: LogLevel.error);
      return [];
    }
  }

  // ── Game session sync ───────────────────────────────────────────────────────

  /// Push current game state to Supabase.
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
      _log.log('Session synced — round $currentRound, q$currentQuestionIndex',
          level: LogLevel.success);
    } catch (e) {
      _online = false;
      _log.log('syncGameSession error: $e', level: LogLevel.error);
      debugPrint('[Supabase] syncGameSession error: $e');
    }
  }

  /// Publish a game event (buzz, score change, etc.).
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
      _log.log('Event published: $eventType${teamId != null ? ' (team $teamId)' : ''}',
          level: LogLevel.info);
    } catch (e) {
      _log.log('publishEvent error: $e', level: LogLevel.error);
      debugPrint('[Supabase] publishEvent error: $e');
    }
  }

  // ── Real-time subscriptions ─────────────────────────────────────────────────

  /// Subscribe to live team score updates. Returns a [StreamSubscription]
  /// that you should cancel when done.
  RealtimeChannel? listenToTeams(void Function(List<Map<String, dynamic>>) onUpdate) {
    if (!_ready()) return null;
    return _client
        .channel('teams-channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'teams',
          callback: (payload) async {
            final teams = await fetchTeams();
            onUpdate(teams);
          },
        )
        .subscribe();
  }

  /// Subscribe to game session updates (for the mobile scoreboard).
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
            final newRecord = payload.newRecord;
            if (newRecord.isNotEmpty) onUpdate(newRecord);
          },
        )
        .subscribe();
  }
}
