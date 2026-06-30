import '../../domain/entities/question.dart';

/// SQLite row model for [Question].
class QuestionIsarModel {
  final String id;
  final String text;
  final String categoryId;
  final String type;
  final String difficulty;
  final int points;
  final String? mediaPath;
  final String? correctAnswer;
  final List<String> options;
  final bool isUsed;
  final int wrongPoints;

  const QuestionIsarModel({
    required this.id,
    required this.text,
    required this.categoryId,
    required this.type,
    required this.difficulty,
    required this.points,
    this.mediaPath,
    this.correctAnswer,
    this.options = const [],
    this.isUsed = false,
    this.wrongPoints = 1,
  });

  Question toEntity() => Question(
        id: id,
        text: text,
        categoryId: categoryId,
        type: QuestionType.values.byName(type),
        difficulty: DifficultyLevel.values.byName(difficulty),
        points: points,
        wrongPoints: wrongPoints,
        mediaPath: mediaPath,
        correctAnswer: correctAnswer,
        options: options,
        isUsed: isUsed,
      );

  static QuestionIsarModel fromEntity(Question q) => QuestionIsarModel(
        id: q.id,
        text: q.text,
        categoryId: q.categoryId,
        type: q.type.name,
        difficulty: q.difficulty.name,
        points: q.points,
        wrongPoints: q.wrongPoints,
        mediaPath: q.mediaPath,
        correctAnswer: q.correctAnswer,
        options: q.options,
        isUsed: q.isUsed,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'category_id': categoryId,
        'type': type,
        'difficulty': difficulty,
        'points': points,
        'wrong_points': wrongPoints,
        'media_path': mediaPath,
        'correct_answer': correctAnswer,
        'options': options.join(';'),
        'is_used': isUsed ? 1 : 0,
      };

  static QuestionIsarModel fromMap(Map<String, dynamic> m) {
    final optStr = (m['options'] as String?) ?? '';
    return QuestionIsarModel(
      id: m['id'] as String,
      text: m['text'] as String,
      categoryId: m['category_id'] as String,
      type: m['type'] as String,
      difficulty: m['difficulty'] as String,
      points: m['points'] as int,
      wrongPoints: (m['wrong_points'] as int?) ?? 1,
      mediaPath: m['media_path'] as String?,
      correctAnswer: m['correct_answer'] as String?,
      options: optStr.isEmpty ? [] : optStr.split(';'),
      isUsed: (m['is_used'] as int) == 1,
    );
  }
}
