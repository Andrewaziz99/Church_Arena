import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/question.dart';
import '../bloc/questions_bloc.dart';
import 'question_form_dialog.dart';

class QuestionCardWidget extends StatelessWidget {
  final Question question;
  final List<Category> categories;

  const QuestionCardWidget({
    super.key,
    required this.question,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final category = categories.where((c) => c.id == question.categoryId).firstOrNull;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TypeIcon(type: question.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _DifficultyBadge(difficulty: question.difficulty),
                      _PointsBadge(points: question.points),
                      if (category != null)
                        Chip(
                          label: Text(
                            category.name,
                            style: const TextStyle(fontSize: 11),
                          ),
                          avatar: CircleAvatar(
                            radius: 6,
                            backgroundColor: Color(category.color),
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => QuestionFormDialog(
                      categories: categories,
                      question: question,
                      blocContext: context,
                    ),
                  ),
                  tooltip: AppStrings.editQuestion,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.error),
                  onPressed: () => _confirmDelete(context),
                  tooltip: AppStrings.deleteQuestion,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.confirm),
        content: const Text(AppStrings.confirmDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              context.read<QuestionsBloc>().add(DeleteQuestion(question.id));
              Navigator.pop(ctx);
            },
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  final QuestionType type;
  const _TypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (type) {
      case QuestionType.text:
        icon = Icons.text_fields;
      case QuestionType.image:
        icon = Icons.image;
      case QuestionType.audio:
        icon = Icons.audiotrack;
      case QuestionType.video:
        icon = Icons.videocam;
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: AppColors.primary, size: 20),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final DifficultyLevel difficulty;
  const _DifficultyBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (difficulty) {
      case DifficultyLevel.easy:
        color = AppColors.success;
      case DifficultyLevel.medium:
        color = AppColors.accent;
      case DifficultyLevel.hard:
        color = AppColors.error;
    }
    final label = difficulty.name[0].toUpperCase() + difficulty.name.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _PointsBadge extends StatelessWidget {
  final int points;
  const _PointsBadge({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.6)),
      ),
      child: Text(
        '$points pts',
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
