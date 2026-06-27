import '../../domain/entities/category.dart';

/// SQLite row model for [Category].
class CategoryIsarModel {
  final String id;
  final String name;
  final int color;
  final List<String> questionIds;

  const CategoryIsarModel({
    required this.id,
    required this.name,
    required this.color,
    this.questionIds = const [],
  });

  Category toEntity() => Category(
        id: id,
        name: name,
        color: color,
        questionIds: questionIds,
      );

  static CategoryIsarModel fromEntity(Category c) => CategoryIsarModel(
        id: c.id,
        name: c.name,
        color: c.color,
        questionIds: c.questionIds,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'color': color,
        'question_ids': questionIds.join(';'),
      };

  static CategoryIsarModel fromMap(Map<String, dynamic> m) {
    final idsStr = (m['question_ids'] as String?) ?? '';
    return CategoryIsarModel(
      id: m['id'] as String,
      name: m['name'] as String,
      color: m['color'] as int,
      questionIds: idsStr.isEmpty ? [] : idsStr.split(';'),
    );
  }
}
