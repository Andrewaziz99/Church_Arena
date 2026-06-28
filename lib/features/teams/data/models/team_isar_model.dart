import '../../domain/entities/team.dart';

/// SQLite row model for [Team].
class TeamIsarModel {
  final String id;
  final String name;
  final int color;
  final int score;
  final String? logoPath;
  final bool isActive;
  final String section;

  const TeamIsarModel({
    required this.id,
    required this.name,
    required this.color,
    required this.score,
    this.logoPath,
    this.isActive = false,
    this.section = '',
  });

  Team toEntity() => Team(
        id: id,
        name: name,
        color: color,
        score: score,
        logoPath: logoPath,
        isActive: isActive,
        section: section,
      );

  static TeamIsarModel fromEntity(Team t) => TeamIsarModel(
        id: t.id,
        name: t.name,
        color: t.color,
        score: t.score,
        logoPath: t.logoPath,
        isActive: t.isActive,
        section: t.section,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'color': color,
        'score': score,
        'logo_path': logoPath,
        'is_active': isActive ? 1 : 0,
        'section': section,
      };

  static TeamIsarModel fromMap(Map<String, dynamic> m) => TeamIsarModel(
        id: m['id'] as String,
        name: m['name'] as String,
        color: m['color'] as int,
        score: m['score'] as int,
        logoPath: m['logo_path'] as String?,
        isActive: (m['is_active'] as int) == 1,
        section: (m['section'] as String?) ?? '',
      );
}
