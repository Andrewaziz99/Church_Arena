import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
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
  late final TextEditingController _answerCtrl;
  late final TextEditingController _optionsCtrl;

  late QuestionType _type;
  late DifficultyLevel _difficulty;
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    _textCtrl = TextEditingController(text: q?.text ?? '');
    _pointsCtrl = TextEditingController(text: (q?.points ?? 10).toString());
    _answerCtrl = TextEditingController(text: q?.correctAnswer ?? '');
    _optionsCtrl = TextEditingController(text: q?.options.join('; ') ?? '');
    _type = q?.type ?? QuestionType.text;
    _difficulty = q?.difficulty ?? DifficultyLevel.easy;
    _categoryId = q?.categoryId ??
        (widget.categories.isNotEmpty ? widget.categories.first.id : null);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _pointsCtrl.dispose();
    _answerCtrl.dispose();
    _optionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.question != null;
    return AlertDialog(
      title: Text(isEdit ? AppStrings.editQuestion : AppStrings.addQuestion),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                if (widget.categories.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: _categoryId,
                    decoration: const InputDecoration(
                      labelText: AppStrings.category,
                    ),
                    items: widget.categories.map((c) {
                      return DropdownMenuItem(value: c.id, child: Text(c.name));
                    }).toList(),
                    onChanged: (v) => setState(() => _categoryId = v),
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<QuestionType>(
                  value: _type,
                  decoration: const InputDecoration(
                    labelText: AppStrings.questionType,
                  ),
                  items: QuestionType.values.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text(t.name[0].toUpperCase() + t.name.substring(1)),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _type = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<DifficultyLevel>(
                  value: _difficulty,
                  decoration: const InputDecoration(
                    labelText: AppStrings.difficulty,
                  ),
                  items: DifficultyLevel.values.map((d) {
                    return DropdownMenuItem(
                      value: d,
                      child: Text(d.name[0].toUpperCase() + d.name.substring(1)),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _difficulty = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pointsCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: AppStrings.points,
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? AppStrings.nameRequired : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _answerCtrl,
                  decoration: const InputDecoration(
                    labelText: AppStrings.answer,
                  ),
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
      correctAnswer:
          _answerCtrl.text.trim().isEmpty ? null : _answerCtrl.text.trim(),
      options: options,
    );
    widget.blocContext.read<QuestionsBloc>().add(SaveQuestion(question));
    Navigator.pop(context);
  }
}
