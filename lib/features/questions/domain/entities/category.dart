import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final int color;
  final List<String> questionIds;
  /// Competition section this category belongs to, e.g. 'اولى وثانية'. Empty = all.
  final String section;

  const Category({
    required this.id,
    required this.name,
    required this.color,
    this.questionIds = const [],
    this.section = '',
  });

  Category copyWith({
    String? id,
    String? name,
    int? color,
    List<String>? questionIds,
    String? section,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      questionIds: questionIds ?? this.questionIds,
      section: section ?? this.section,
    );
  }

  @override
  List<Object?> get props => [id, name, color, questionIds, section];
}
