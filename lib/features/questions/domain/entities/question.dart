import 'package:equatable/equatable.dart';

enum QuestionType { text, image, audio, video }
enum DifficultyLevel { easy, medium, hard }

class Question extends Equatable {
  final String id;
  final String text;
  final String categoryId;
  final QuestionType type;
  final DifficultyLevel difficulty;
  final int points;
  final String? mediaPath;
  final String? correctAnswer;
  final List<String> options;
  final bool isUsed;
  /// Points deducted when this question is answered incorrectly. Default: 1.
  final int wrongPoints;

  const Question({
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

  Question copyWith({
    String? id,
    String? text,
    String? categoryId,
    QuestionType? type,
    DifficultyLevel? difficulty,
    int? points,
    int? wrongPoints,
    Object? mediaPath = _sentinel,
    Object? correctAnswer = _sentinel,
    List<String>? options,
    bool? isUsed,
  }) {
    return Question(
      id: id ?? this.id,
      text: text ?? this.text,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      points: points ?? this.points,
      wrongPoints: wrongPoints ?? this.wrongPoints,
      mediaPath: mediaPath == _sentinel ? this.mediaPath : mediaPath as String?,
      correctAnswer: correctAnswer == _sentinel ? this.correctAnswer : correctAnswer as String?,
      options: options ?? this.options,
      isUsed: isUsed ?? this.isUsed,
    );
  }

  @override
  List<Object?> get props => [id, text, categoryId, type, difficulty, points,
        wrongPoints, mediaPath, correctAnswer, options, isUsed];
}

const _sentinel = Object();
