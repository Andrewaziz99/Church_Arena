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
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildContent(context),
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
                  height: 300,
                  fit: BoxFit.contain,
                ),
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported,
                        size: 60, color: AppColors.textSecondary),
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
              child: const Icon(
                Icons.audiotrack,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              question.mediaPath ?? 'No audio file',
              style: const TextStyle(color: AppColors.textSecondary),
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
              child: const Icon(
                Icons.videocam,
                size: 60,
                color: AppColors.primary,
              ),
            ),
          ],
        );
    }
  }
}
