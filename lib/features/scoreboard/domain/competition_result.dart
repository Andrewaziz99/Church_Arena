import 'dart:convert';
import '../../../features/teams/domain/entities/team.dart';

/// A point-in-time snapshot of one team's score at the end of a competition.
class TeamSnapshot {
  final String id;
  final String name;
  final int color;
  final int score;
  final String section;

  const TeamSnapshot({
    required this.id,
    required this.name,
    required this.color,
    required this.score,
    required this.section,
  });

  factory TeamSnapshot.fromTeam(Team t) => TeamSnapshot(
        id: t.id,
        name: t.name,
        color: t.color,
        score: t.score,
        section: t.section,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
        'score': score,
        'section': section,
      };

  factory TeamSnapshot.fromJson(Map<String, dynamic> j) => TeamSnapshot(
        id: j['id'] as String,
        name: j['name'] as String,
        color: j['color'] as int,
        score: j['score'] as int,
        section: j['section'] as String? ?? '',
      );
}

/// The persisted result of a completed competition.
class CompetitionResult {
  final String id;
  final DateTime completedAt;
  /// Teams sorted by score descending.
  final List<TeamSnapshot> teams;

  const CompetitionResult({
    required this.id,
    required this.completedAt,
    required this.teams,
  });

  TeamSnapshot? get winner => teams.isNotEmpty ? teams.first : null;

  // ── Serialisation (for SQLite TEXT column) ─────────────────────────────────

  String get teamsJson => jsonEncode(teams.map((t) => t.toJson()).toList());

  static List<TeamSnapshot> _decodeTeams(String raw) {
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => TeamSnapshot.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'completed_at': completedAt.toIso8601String(),
        'teams_json': teamsJson,
      };

  factory CompetitionResult.fromMap(Map<String, dynamic> m) =>
      CompetitionResult(
        id: m['id'] as String,
        completedAt: DateTime.parse(m['completed_at'] as String),
        teams: _decodeTeams(m['teams_json'] as String),
      );
}
