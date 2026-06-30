import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/question.dart';
import '../bloc/questions_bloc.dart';

class QuestionFormDialog extends StatefulWidget {
  final List<Category> categories;
  final Question? question;
  final BuildContext blocContext;

  const QuestionFormDialog({
    super.key,
    required this.categories,
    required this.blocContext,
    this.question,
  });

  @override
  State<QuestionFormDialog> createState() => _QuestionFormDialogState();
}

class _QuestionFormDialogState extends State<QuestionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _textCtrl;
  late final TextEditingController _pointsCtrl;
  late final TextEditingController _wrongPointsCtrl;
  late final TextEditingController _answerCtrl;
  late final TextEditingController _optionsCtrl;

  late QuestionType _type;
  late DifficultyLevel _difficulty;
  String? _categoryId;
  String? _mediaPath; // selected image / audio file path

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    _textCtrl = TextEditingController(text: q?.text ?? '');
    _pointsCtrl = TextEditingController(text: (q?.points ?? 10).toString());
    _wrongPointsCtrl = TextEditingController(text: (q?.wrongPoints ?? 1).toString());
    _answerCtrl = TextEditingController(text: q?.correctAnswer ?? '');
    _optionsCtrl = TextEditingController(text: q?.options.join('; ') ?? '');
    _type = q?.type ?? QuestionType.text;
    _difficulty = q?.difficulty ?? DifficultyLevel.easy;
    _categoryId = q?.categoryId ??
        (widget.categories.isNotEmpty ? widget.categories.first.id : null);
    _mediaPath = q?.mediaPath;
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _pointsCtrl.dispose();
    _wrongPointsCtrl.dispose();
    _answerCtrl.dispose();
    _optionsCtrl.dispose();
    super.dispose();
  }

  // ── Media picker ────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _mediaPath = result.files.single.path);
    }
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'aac', 'm4a', 'ogg'],
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _mediaPath = result.files.single.path);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.question != null;
    final showMediaPicker = _type == QuestionType.image || _type == QuestionType.audio;

    return AlertDialog(
      title: Text(isEdit ? AppStrings.editQuestion : AppStrings.addQuestion),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Question text ──────────────────────────────────────
                TextFormField(
                  controller: _textCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: AppStrings.questionText,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? AppStrings.nameRequired : null,
                ),
                const SizedBox(height: 12),

                // ── Category ────────────────────────────────────────────
                if (widget.categories.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: _categoryId,
                    decoration: const InputDecoration(labelText: AppStrings.category),
                    items: widget.categories.map((c) {
                      return DropdownMenuItem(value: c.id, child: Text(c.name));
                    }).toList(),
                    onChanged: (v) => setState(() => _categoryId = v),
                  ),
                const SizedBox(height: 12),

                // ── Type ─────────────────────────────────────────────────
                DropdownButtonFormField<QuestionType>(
                  value: _type,
                  decoration: const InputDecoration(labelText: AppStrings.questionType),
                  items: QuestionType.values.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Row(
                        children: [
                          Icon(_typeIcon(t), size: 16, color: AppColors.blueContent),
                          const SizedBox(width: 8),
                          Text(t.name[0].toUpperCase() + t.name.substring(1)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() {
                    _type = v!;
                    if (_type == QuestionType.text) _mediaPath = null;
                  }),
                ),
                const SizedBox(height: 12),

                // ── Media picker (shown only for image/audio types) ──────
                if (showMediaPicker) ...[
                  _MediaPickerCard(
                    type: _type,
                    mediaPath: _mediaPath,
                    onPickImage: _pickImage,
                    onPickAudio: _pickAudio,
                    onClear: () => setState(() => _mediaPath = null),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Difficulty ──────────────────────────────────────────
                DropdownButtonFormField<DifficultyLevel>(
                  value: _difficulty,
                  decoration: const InputDecoration(labelText: AppStrings.difficulty),
                  items: DifficultyLevel.values.map((d) {
                    return DropdownMenuItem(
                      value: d,
                      child: Text(d.name[0].toUpperCase() + d.name.substring(1)),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _difficulty = v!),
                ),
                const SizedBox(height: 12),

                // ── Points row ──────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _pointsCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: AppStrings.points,
                          hintText: 'e.g. 10',
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? AppStrings.nameRequired : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _wrongPointsCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Wrong points penalty',
                          hintText: 'e.g. 1',
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? AppStrings.nameRequired : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Answer & options ────────────────────────────────────
                TextFormField(
                  controller: _answerCtrl,
                  decoration: const InputDecoration(labelText: AppStrings.answer),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _optionsCtrl,
                  decoration: const InputDecoration(
                    labelText: AppStrings.options,
                    hintText: 'Option A; Option B; Option C',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text(AppStrings.save),
        ),
      ],
    );
  }

  IconData _typeIcon(QuestionType t) {
    switch (t) {
      case QuestionType.image: return Icons.image_rounded;
      case QuestionType.audio: return Icons.audiotrack_rounded;
      case QuestionType.video: return Icons.videocam_rounded;
      case QuestionType.text:  return Icons.text_fields_rounded;
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final options = _optionsCtrl.text
        .split(';')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final question = Question(
      id: widget.question?.id ?? const Uuid().v4(),
      text: _textCtrl.text.trim(),
      categoryId: _categoryId ?? 'default',
      type: _type,
      difficulty: _difficulty,
      points: int.tryParse(_pointsCtrl.text) ?? 10,
      wrongPoints: int.tryParse(_wrongPointsCtrl.text) ?? 1,
      correctAnswer:
          _answerCtrl.text.trim().isEmpty ? null : _answerCtrl.text.trim(),
      options: options,
      mediaPath: _mediaPath,
    );
    widget.blocContext.read<QuestionsBloc>().add(SaveQuestion(question));
    Navigator.pop(context);
  }
}

// ── Media picker card ──────────────────────────────────────────────────────────

class _MediaPickerCard extends StatelessWidget {
  final QuestionType type;
  final String? mediaPath;
  final VoidCallback onPickImage;
  final VoidCallback onPickAudio;
  final VoidCallback onClear;

  const _MediaPickerCard({
    required this.type,
    required this.mediaPath,
    required this.onPickImage,
    required this.onPickAudio,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isImage = type == QuestionType.image;
    final hasMedia = mediaPath != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isImage ? Icons.image_rounded : Icons.audiotrack_rounded,
                size: 16,
                color: AppColors.blueContent,
              ),
              const SizedBox(width: 6),
              Text(
                isImage ? 'Question Image' : 'Question Audio',
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 13),
              ),
              const Spacer(),
              if (hasMedia)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: AppColors.error,
                  tooltip: 'Remove',
                  onPressed: onClear,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Preview for images
          if (isImage && hasMedia)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(mediaPath!),
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 60,
                  child: Center(
                    child: Text('Cannot preview image',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
              ),
            ),

          // Audio path label
          if (!isImage && hasMedia)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.blueContent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.audiotrack_rounded,
                      size: 14, color: AppColors.blueContent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      mediaPath!.split(Platform.pathSeparator).last,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          if (!hasMedia)
            const Text(
              'No file selected',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isImage ? onPickImage : onPickAudio,
              icon: Icon(
                isImage ? Icons.folder_open_rounded : Icons.folder_open_rounded,
                size: 16,
              ),
              label: Text(hasMedia
                  ? (isImage ? 'Change Image' : 'Change Audio')
                  : (isImage ? 'Select Image' : 'Select Audio File')),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.blueContent,
                side: const BorderSide(color: AppColors.blueContent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
