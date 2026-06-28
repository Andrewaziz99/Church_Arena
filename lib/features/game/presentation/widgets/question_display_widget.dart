import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/neon_text.dart';
import '../../../questions/domain/entities/question.dart';

class QuestionDisplayWidget extends StatelessWidget {
  final Question question;

  const QuestionDisplayWidget({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildContent(context),
          if (question.options.isNotEmpty) ...[
            const SizedBox(height: 28),
            _ChoicesGrid(options: question.options),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (question.type) {
      case QuestionType.text:
        return NeonText(
          text: question.text,
          fontSize: 36,
          color: AppColors.textPrimary,
          textAlign: TextAlign.center,
        );
      case QuestionType.image:
        return Column(
          children: [
            if (question.text.isNotEmpty) ...[
              NeonText(
                text: question.text,
                fontSize: 24,
                color: AppColors.textPrimary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
            ],
            if (question.mediaPath != null &&
                File(question.mediaPath!).existsSync())
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(question.mediaPath!),
                  height: 280,
                  fit: BoxFit.contain,
                ),
              )
            else
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported,
                        size: 48, color: AppColors.textSecondary),
                    SizedBox(height: 8),
                    Text('Image not found',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
          ],
        );
      case QuestionType.audio:
        return Column(
          children: [
            NeonText(
              text: question.text,
              fontSize: 28,
              color: AppColors.textPrimary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.audiotrack,
                  size: 60, color: AppColors.primary),
            ),
          ],
        );
      case QuestionType.video:
        return Column(
          children: [
            NeonText(
              text: question.text,
              fontSize: 28,
              color: AppColors.textPrimary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.videocam,
                  size: 60, color: AppColors.primary),
            ),
          ],
        );
    }
  }
}

// ── Multiple-choice grid ──────────────────────────────────────────────────────

class _ChoicesGrid extends StatelessWidget {
  final List<String> options;

  const _ChoicesGrid({required this.options});

  static const List<String> _letters = ['A', 'B', 'C', 'D'];
  static const List<Color> _colors = [
    Color(0xFF1565C0), // blue
    Color(0xFF2E7D32), // green
    Color(0xFF6A1B9A), // purple
    Color(0xFFE65100), // orange
  ];

  @override
  Widget build(BuildContext context) {
    final count = options.length.clamp(0, 4);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 3.8,
      ),
      itemCount: count,
      itemBuilder: (context, i) {
        final color = _colors[i % _colors.length];
        return Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.55), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.4),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(11),
                    bottomLeft: Radius.circular(11),
                  ),
                ),
                child: Center(
                  child: Text(
                    _letters[i],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Text(
                    options[i],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
