import 'package:equatable/equatable.dart';

class Team extends Equatable {
  final String id;
  final String name;
  final int color;
  final int score;
  final String? logoPath;
  final bool isActive;

  const Team({
    required this.id,
    required this.name,
    required this.color,
    this.score = 0,
    this.logoPath,
    this.isActive = false,
  });

  Team copyWith({
    String? id,
    String? name,
    int? color,
    int? score,
    Object? logoPath = _sentinel,
    bool? isActive,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      score: score ?? this.score,
      logoPath: logoPath == _sentinel ? this.logoPath : logoPath as String?,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [id, name, color, score, logoPath, isActive];
}

const _sentinel = Object();
