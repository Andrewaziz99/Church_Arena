import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final int color;
  final List<String> questionIds;
  /// Competition section this category belongs to, e.g. 'اولى وثانية'. Empty = all.
  final String section;
  /// Which round this category's questions belong to.
  /// 'r1' = أسئلة الفرق, 'r2' = ضربات جزاء, 'r3' = تحت الضغط, '' = any round.
  final String roundType;

  const Category({
    required this.id,
    required this.name,
    required this.color,
    this.questionIds = const [],
    this.section = '',
    this.roundType = '',
  });

  Category copyWith({
    String? id,
    String? name,
    int? color,
    List<String>? questionIds,
    String? section,
    String? roundType,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      questionIds: questionIds ?? this.questionIds,
      section: section ?? this.section,
      roundType: roundType ?? this.roundType,
    );
  }

  @override
  List<Object?> get props => [id, name, color, questionIds, section, roundType];
}
