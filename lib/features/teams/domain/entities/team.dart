import 'package:equatable/equatable.dart';

class Team extends Equatable {
  final String id;
  final String name;
  final int color;
  final int score;
  final String? logoPath;
  final bool isActive;
  /// Competition section this team belongs to, e.g. 'اولى وثانية'. Empty = all.
  final String section;

  const Team({
    required this.id,
    required this.name,
    required this.color,
    this.score = 0,
    this.logoPath,
    this.isActive = false,
    this.section = '',
  });

  Team copyWith({
    String? id,
    String? name,
    int? color,
    int? score,
    Object? logoPath = _sentinel,
    bool? isActive,
    String? section,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      score: score ?? this.score,
      logoPath: logoPath == _sentinel ? this.logoPath : logoPath as String?,
      isActive: isActive ?? this.isActive,
      section: section ?? this.section,
    );
  }

  @override
  List<Object?> get props => [id, name, color, score, logoPath, isActive, section];
}

const _sentinel = Object();
