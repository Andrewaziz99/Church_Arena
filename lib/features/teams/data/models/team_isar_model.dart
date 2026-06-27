import '../../domain/entities/team.dart';

/// SQLite row model for [Team].
class TeamIsarModel {
  final String id;
  final String name;
  final int color;
  final int score;
  final String? logoPath;
  final bool isActive;

  const TeamIsarModel({
    required this.id,
    required this.name,
    required this.color,
    required this.score,
    this.logoPath,
    this.isActive = false,
  });

  Team toEntity() => Team(
        id: id,
        name: name,
        color: color,
        score: score,
        logoPath: logoPath,
        isActive: isActive,
      );

  static TeamIsarModel fromEntity(Team t) => TeamIsarModel(
        id: t.id,
        name: t.name,
        color: t.color,
        score: t.score,
        logoPath: t.logoPath,
        isActive: t.isActive,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'color': color,
        'score': score,
        'logo_path': logoPath,
        'is_active': isActive ? 1 : 0,
      };

  static TeamIsarModel fromMap(Map<String, dynamic> m) => TeamIsarModel(
        id: m['id'] as String,
        name: m['name'] as String,
        color: m['color'] as int,
        score: m['score'] as int,
        logoPath: m['logo_path'] as String?,
        isActive: (m['is_active'] as int) == 1,
      );
}
