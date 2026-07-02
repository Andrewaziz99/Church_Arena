import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/question.dart';
import '../bloc/questions_bloc.dart';

/// Full-page form for adding or editing a question.
/// Pass [question] via GoRouter extras to enter edit mode.
class QuestionFormScreen extends StatefulWidget {
  final Question? question;

  const QuestionFormScreen({super.key, this.question});

  @override
  State<QuestionFormScreen> createState() => _QuestionFormScreenState();
}

class _QuestionFormScreenState extends State<QuestionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _textCtrl;
  late final TextEditingController _pointsCtrl;
  late final TextEditingController _wrongPointsCtrl;
  late final TextEditingController _answerCtrl;

  // One controller per option slot (up to 4)
  final List<TextEditingController> _optionCtrls =
      List.generate(4, (_) => TextEditingController());

  late QuestionType _type;
  late DifficultyLevel _difficulty;
  String? _categoryId;
  String? _mediaPath;

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    _textCtrl = TextEditingController(text: q?.text ?? '');
    _pointsCtrl = TextEditingController(text: (q?.points ?? 10).toString());
    _wrongPointsCtrl =
        TextEditingController(text: (q?.wrongPoints ?? 1).toString());
    _answerCtrl = TextEditingController(text: q?.correctAnswer ?? '');
    _type = q?.type ?? QuestionType.text;
    _difficulty = q?.difficulty ?? DifficultyLevel.easy;
    _mediaPath = q?.mediaPath;

    // Pre-fill option slots from existing question
    if (q != null) {
      for (var i = 0; i < q.options.length && i < 4; i++) {
        _optionCtrls[i].text = q.options[i];
      }
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _pointsCtrl.dispose();
    _wrongPointsCtrl.dispose();
    _answerCtrl.dispose();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isEdit => widget.question != null;

  // ── Media helpers ──────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.image, allowMultiple: false);
    if (result?.files.single.path != null) {
      setState(() => _mediaPath = result!.files.single.path);
    }
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'aac', 'm4a', 'ogg'],
      allowMultiple: false,
    );
    if (result?.files.single.path != null) {
      setState(() => _mediaPath = result!.files.single.path);
    }
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  void _save(List<Category> categories) {
    if (!_formKey.currentState!.validate()) return;

    // Determine category: use selected, else first available, else 'default'
    final catId = _categoryId ??
        (categories.isNotEmpty ? categories.first.id : 'default');

    final options = _optionCtrls
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final question = Question(
      id: widget.question?.id ?? const Uuid().v4(),
      text: _textCtrl.text.trim(),
      categoryId: catId,
      type: _type,
      difficulty: _difficulty,
      points: int.tryParse(_pointsCtrl.text) ?? 10,
      wrongPoints: int.tryParse(_wrongPointsCtrl.text) ?? 1,
      correctAnswer:
          _answerCtrl.text.trim().isEmpty ? null : _answerCtrl.text.trim(),
      options: options,
      mediaPath: _mediaPath,
    );

    context.read<QuestionsBloc>().add(SaveQuestion(question));
    context.pop();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuestionsBloc, QuestionsState>(
      builder: (context, state) {
        final categories =
            state is QuestionsLoaded ? state.categories : <Category>[];

        // Keep selected category valid
        if (_categoryId != null &&
            !categories.any((c) => c.id == _categoryId)) {
          _categoryId = null;
        }
        if (_categoryId == null && categories.isNotEmpty) {
          _categoryId = widget.question?.categoryId ??
              (categories.any((c) => c.id == widget.question?.categoryId)
                  ? widget.question!.categoryId
                  : categories.first.id);
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(_isEdit ? 'Edit Question' : 'Add Question'),
            leading: BackButton(onPressed: () => context.pop()),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: FilledButton.icon(
                  onPressed: () => _save(categories),
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Save'),
                ),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Left column: question details ──────────────────────────
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel('Question'),
                        TextFormField(
                          controller: _textCtrl,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Question text',
                            hintText: 'Enter the question...',
                            alignLabelWithHint: true,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Question text is required'
                              : null,
                        ),
                        const SizedBox(height: 20),

                        _SectionLabel('Media'),
                        _MediaSection(
                          type: _type,
                          mediaPath: _mediaPath,
                          onPickImage: _pickImage,
                          onPickAudio: _pickAudio,
                          onClear: () => setState(() => _mediaPath = null),
                        ),
                        const SizedBox(height: 20),

                        _SectionLabel('Answer'),
                        TextFormField(
                          controller: _answerCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Correct answer',
                            hintText: 'Type the correct answer...',
                            prefixIcon: Icon(Icons.check_circle_outline_rounded,
                                color: AppColors.greenSuccess),
                          ),
                        ),
                        const SizedBox(height: 20),

                        _SectionLabel('Options (multiple choice)'),
                        ...List.generate(4, (i) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TextFormField(
                              controller: _optionCtrls[i],
                              decoration: InputDecoration(
                                labelText: 'Option ${i + 1}',
                                hintText: i < 2 ? 'Recommended' : 'Optional',
                                prefixIcon: Container(
                                  width: 36,
                                  alignment: Alignment.center,
                                  child: Text(
                                    String.fromCharCode(65 + i), // A, B, C, D
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.blueContent,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                const VerticalDivider(width: 1),

                // ── Right column: metadata ─────────────────────────────────
                SizedBox(
                  width: 280,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel('Category'),
                        if (categories.isEmpty)
                          const Text(
                            'No categories yet — add one first',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 13),
                          )
                        else
                          DropdownButtonFormField<String>(
                            value: _categoryId,
                            decoration:
                                const InputDecoration(labelText: 'Category'),
                            items: categories
                                .map((c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                              radius: 6,
                                              backgroundColor:
                                                  Color(c.color)),
                                          const SizedBox(width: 8),
                                          Flexible(child: Text(c.name)),
                                        ],
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _categoryId = v),
                          ),
                        const SizedBox(height: 20),

                        _SectionLabel('Type'),
                        DropdownButtonFormField<QuestionType>(
                          value: _type,
                          decoration:
                              const InputDecoration(labelText: 'Question type'),
                          items: QuestionType.values
                              .map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Row(
                                      children: [
                                        Icon(_typeIcon(t),
                                            size: 16,
                                            color: AppColors.blueContent),
                                        const SizedBox(width: 8),
                                        Text(_typeName(t)),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() {
                            _type = v!;
                            if (_type == QuestionType.text) {
                              _mediaPath = null;
                            }
                          }),
                        ),
                        const SizedBox(height: 20),

                        _SectionLabel('Difficulty'),
                        DropdownButtonFormField<DifficultyLevel>(
                          value: _difficulty,
                          decoration:
                              const InputDecoration(labelText: 'Difficulty'),
                          items: DifficultyLevel.values
                              .map((d) => DropdownMenuItem(
                                    value: d,
                                    child: Row(
                                      children: [
                                        Icon(Icons.circle,
                                            size: 10,
                                            color: _diffColor(d)),
                                        const SizedBox(width: 8),
                                        Text(_diffName(d)),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _difficulty = v!),
                        ),
                        const SizedBox(height: 20),

                        _SectionLabel('Scoring'),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _pointsCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Points',
                                  hintText: '10',
                                ),
                                validator: (v) =>
                                    (v == null || v.isEmpty) ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _wrongPointsCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Penalty',
                                  hintText: '1',
                                ),
                                validator: (v) =>
                                    (v == null || v.isEmpty) ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

  String _typeName(QuestionType t) {
    switch (t) {
      case QuestionType.image: return 'Image';
      case QuestionType.audio: return 'Audio';
      case QuestionType.video: return 'Video';
      case QuestionType.text:  return 'Text';
    }
  }

  Color _diffColor(DifficultyLevel d) {
    switch (d) {
      case DifficultyLevel.easy:   return AppColors.greenSuccess;
      case DifficultyLevel.medium: return AppColors.accent;
      case DifficultyLevel.hard:   return AppColors.error;
    }
  }

  String _diffName(DifficultyLevel d) {
    switch (d) {
      case DifficultyLevel.easy:   return 'Easy';
      case DifficultyLevel.medium: return 'Medium';
      case DifficultyLevel.hard:   return 'Hard';
    }
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _MediaSection extends StatelessWidget {
  final QuestionType type;
  final String? mediaPath;
  final VoidCallback onPickImage;
  final VoidCallback onPickAudio;
  final VoidCallback onClear;

  const _MediaSection({
    required this.type,
    required this.mediaPath,
    required this.onPickImage,
    required this.onPickAudio,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (type == QuestionType.text || type == QuestionType.video) {
      return const Text(
        'No media needed for this question type.',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
      );
    }

    final isImage = type == QuestionType.image;
    final hasMedia = mediaPath != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isImage && hasMedia) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(mediaPath!),
                height: 180,
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
            const SizedBox(height: 8),
          ],
          if (!isImage && hasMedia) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.blueContent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.audiotrack_rounded,
                      size: 16, color: AppColors.blueContent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      mediaPath!.split(Platform.pathSeparator).last,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (!hasMedia)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'No ${isImage ? 'image' : 'audio'} selected',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isImage ? onPickImage : onPickAudio,
                  icon: const Icon(Icons.folder_open_rounded, size: 16),
                  label: Text(hasMedia
                      ? 'Change ${isImage ? 'image' : 'audio'}'
                      : 'Select ${isImage ? 'image' : 'audio'}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.blueContent,
                    side: const BorderSide(color: AppColors.blueContent),
                  ),
                ),
              ),
              if (hasMedia) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: AppColors.error,
                  tooltip: 'Remove',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
