import '../../domain/entities/category.dart';

/// SQLite row model for [Category].
class CategoryIsarModel {
  final String id;
  final String name;
  final int color;
  final List<String> questionIds;
  final String section;
  final String roundType;

  const CategoryIsarModel({
    required this.id,
    required this.name,
    required this.color,
    this.questionIds = const [],
    this.section = '',
    this.roundType = '',
  });

  Category toEntity() => Category(
        id: id,
        name: name,
        color: color,
        questionIds: questionIds,
        section: section,
        roundType: roundType,
      );

  static CategoryIsarModel fromEntity(Category c) => CategoryIsarModel(
        id: c.id,
        name: c.name,
        color: c.color,
        questionIds: c.questionIds,
        section: c.section,
        roundType: c.roundType,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'color': color,
        'question_ids': questionIds.join(';'),
        'section': section,
        'round_type': roundType,
      };

  static CategoryIsarModel fromMap(Map<String, dynamic> m) {
    final idsStr = (m['question_ids'] as String?) ?? '';
    return CategoryIsarModel(
      id: m['id'] as String,
      name: m['name'] as String,
      color: m['color'] as int,
      questionIds: idsStr.isEmpty ? [] : idsStr.split(';'),
      section: (m['section'] as String?) ?? '',
      roundType: (m['round_type'] as String?) ?? '',
    );
  }
}
