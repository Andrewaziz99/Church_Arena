import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/question.dart';
import '../bloc/questions_bloc.dart';
import '../widgets/question_card_widget.dart';
import '../widgets/question_form_dialog.dart';

class QuestionsScreen extends StatelessWidget {
  const QuestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.questions),
        leading: BackButton(onPressed: () => context.go('/')),
        actions: [
          TextButton.icon(
            onPressed: () => _importQuestions(context),
            icon: const Icon(Icons.upload_file, color: AppColors.primary),
            label: const Text(
              AppStrings.importQuestions,
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<QuestionsBloc, QuestionsState>(
        listener: (context, state) {
          if (state is QuestionsError) {
            context.showSnackBar(state.message, isError: true);
          } else if (state is QuestionsImported) {
            context.showSnackBar(
              '${AppStrings.imported} ${state.count} ${AppStrings.questions_}',
            );
          }
        },
        builder: (context, state) {
          if (state is QuestionsLoading || state is QuestionsImporting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is QuestionsLoaded) {
            return Row(
              children: [
                _CategoryPanel(
                  categories: state.categories,
                  selectedId: state.filterCategory,
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _QuestionsPanel(
                    questions: state.filteredQuestions,
                    categories: state.categories,
                    filterDifficulty: state.filterDifficulty,
                  ),
                ),
              ],
            );
          }
          return const Center(
            child: Text(
              AppStrings.noQuestionsYet,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        },
      ),
    );
  }

  Future<void> _importQuestions(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls'],
    );
    if (result != null && result.files.single.path != null && context.mounted) {
      context.read<QuestionsBloc>().add(ImportQuestions(result.files.single.path!));
    }
  }
}

class _CategoryPanel extends StatelessWidget {
  final List<Category> categories;
  final String? selectedId;

  const _CategoryPanel({required this.categories, this.selectedId});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FilterChip(
              label: const Text(AppStrings.allCategories),
              selected: selectedId == null,
              onSelected: (_) =>
                  context.read<QuestionsBloc>().add(const FilterByCategory(null)),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FilterChip(
                    avatar: CircleAvatar(
                      radius: 8,
                      backgroundColor: Color(cat.color),
                    ),
                    label: Text(cat.name),
                    selected: selectedId == cat.id,
                    onSelected: (_) => context
                        .read<QuestionsBloc>()
                        .add(FilterByCategory(cat.id)),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showAddCategoryDialog(context),
                icon: const Icon(Icons.add),
                label: const Text(AppStrings.addCategory),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    int selectedColor = AppColors.primary.value;
    String selectedSection = '';
    String selectedRoundType = '';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text(AppStrings.addCategory),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: AppStrings.categoryName,
                    hintText: 'e.g. Bible Knowledge',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedSection.isEmpty ? null : selectedSection,
                  decoration: const InputDecoration(
                    labelText: AppStrings.section,
                    hintText: 'All sections',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text(AppStrings.allSections,
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    ...AppStrings.sections.map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(color: AppColors.textPrimary)),
                        )),
                  ],
                  onChanged: (v) => setState(() => selectedSection = v ?? ''),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRoundType.isEmpty ? null : selectedRoundType,
                  decoration: const InputDecoration(
                    labelText: 'الفقرة',
                    hintText: 'لكل الفقرات',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: null,
                      child: Text('لكل الفقرات',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    DropdownMenuItem(
                      value: 'r1',
                      child: Text('الفقرة الأولى — أسئلة الفرق',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(color: AppColors.textPrimary)),
                    ),
                    DropdownMenuItem(
                      value: 'r2',
                      child: Text('الفقرة الثانية — ضربات جزاء',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(color: AppColors.textPrimary)),
                    ),
                    DropdownMenuItem(
                      value: 'r3',
                      child: Text('الفقرة الثالثة — تحت الضغط',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(color: AppColors.textPrimary)),
                    ),
                  ],
                  onChanged: (v) => setState(() => selectedRoundType = v ?? ''),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: AppColors.teamColors.map((color) {
                    final isSelected = selectedColor == color.value;
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = color.value),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(AppStrings.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                context.read<QuestionsBloc>().add(
                      SaveCategory(Category(
                        id: const Uuid().v4(),
                        name: nameCtrl.text.trim(),
                        color: selectedColor,
                        section: selectedSection,
                        roundType: selectedRoundType,
                      )),
                    );
                Navigator.pop(ctx);
              },
              child: const Text(AppStrings.save),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionsPanel extends StatelessWidget {
  final List<Question> questions;
  final List<Category> categories;
  final DifficultyLevel? filterDifficulty;

  const _QuestionsPanel({
    required this.questions,
    required this.categories,
    this.filterDifficulty,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DifficultyFilterBar(selected: filterDifficulty),
        Expanded(
          child: questions.isEmpty
              ? const Center(
                  child: Text(
                    AppStrings.noQuestionsYet,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: questions.length,
                  itemBuilder: (context, index) => QuestionCardWidget(
                    question: questions[index],
                    categories: categories,
                  ),
                ),
        ),
        _AddQuestionButton(categories: categories),
      ],
    );
  }
}

class _DifficultyFilterBar extends StatelessWidget {
  final DifficultyLevel? selected;
  const _DifficultyFilterBar({this.selected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: selected == null,
            onSelected: (_) => context
                .read<QuestionsBloc>()
                .add(const FilterByDifficulty(null)),
          ),
          const SizedBox(width: 8),
          ...DifficultyLevel.values.map((d) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(d.name[0].toUpperCase() + d.name.substring(1)),
                  selected: selected == d,
                  onSelected: (_) => context
                      .read<QuestionsBloc>()
                      .add(FilterByDifficulty(d)),
                ),
              )),
        ],
      ),
    );
  }
}

class _AddQuestionButton extends StatelessWidget {
  final List<Category> categories;
  const _AddQuestionButton({required this.categories});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.bottomRight,
        child: FloatingActionButton.extended(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => QuestionFormDialog(
              categories: categories,
              blocContext: context,
            ),
          ),
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.background,
          icon: const Icon(Icons.add,color: Colors.black,),
          label: const Text(AppStrings.addQuestion, style: TextStyle(color: Colors.black),),
        ),
      ),
    );
  }
}
