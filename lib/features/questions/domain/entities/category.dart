import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final int color;
  final List<String> questionIds;

  const Category({
    required this.id,
    required this.name,
    required this.color,
    this.questionIds = const [],
  });

  Category copyWith({
    String? id,
    String? name,
    int? color,
    List<String>? questionIds,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      questionIds: questionIds ?? this.questionIds,
    );
  }

  @override
  List<Object?> get props => [id, name, color, questionIds];
}
