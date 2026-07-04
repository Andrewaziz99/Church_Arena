import 'dart:io';
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

class QuestionsScreen extends StatefulWidget {
  const QuestionsScreen({super.key});

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  @override
  void initState() {
    super.initState();
    // Real-time updates are handled by RemoteSyncBus → QuestionsBloc.
    // No polling timer needed.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.questions),
        leading: BackButton(onPressed: () => context.go('/')),
        actions: [
          // ── Pull: cloud → local ───────────────────────────────────────────
          TextButton.icon(
            onPressed: () =>
                context.read<QuestionsBloc>().add(const FetchFromCloud()),
            icon: const Icon(Icons.cloud_download_rounded,
                color: AppColors.greenSuccess),
            label: const Text(
              'Pull from Cloud',
              style: TextStyle(color: AppColors.greenSuccess),
            ),
          ),
          const SizedBox(width: 4),
          // ── Push: local → cloud ───────────────────────────────────────────
          TextButton.icon(
            onPressed: () =>
                context.read<QuestionsBloc>().add(const PushToCloud()),
            icon: const Icon(Icons.cloud_upload_rounded,
                color: AppColors.orangeBg),
            label: const Text(
              'Push to Cloud',
              style: TextStyle(color: AppColors.orangeBg),
            ),
          ),
          const SizedBox(width: 4),
          TextButton.icon(
            onPressed: () => _downloadTemplate(context),
            icon: const Icon(Icons.download_rounded, color: AppColors.blueContent),
            label: const Text(
              'Get Template',
              style: TextStyle(color: AppColors.blueContent),
            ),
          ),
          const SizedBox(width: 4),
          TextButton.icon(
            onPressed: () => _importQuestions(context),
            icon: const Icon(Icons.upload_file, color: AppColors.primary),
            label: const Text(
              AppStrings.importQuestions,
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 4),
          TextButton.icon(
            onPressed: () => _confirmClearAll(context),
            icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.error),
            label: const Text(
              'Clear All',
              style: TextStyle(color: AppColors.error),
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
          } else if (state is QuestionsPushed) {
            context.showSnackBar(
              'Uploaded ${state.categoriesCount} categories and '
              '${state.questionsCount} questions to cloud ☁️',
            );
          }
        },
        builder: (context, state) {
          if (state is QuestionsLoading ||
              state is QuestionsImporting ||
              state is QuestionsPushing) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  if (state is QuestionsPushing) ...[
                    const SizedBox(height: 16),
                    const Text('Uploading to cloud…',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ],
              ),
            );
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
                    filterCategoryId: state.filterCategory,
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

  static const _templateCsv =
      'text,category_name,type,difficulty,points,correct_answer,options,wrong_points\n'
      'Who built the ark?,Bible Knowledge,text,easy,10,Noah,Adam;Moses;Noah;Abraham,1\n'
      'How many disciples did Jesus have?,Bible Knowledge,text,easy,10,12,10;11;12;13,1\n'
      'In which city was Jesus born?,Bible Knowledge,text,medium,15,Bethlehem,'
      'Jerusalem;Nazareth;Bethlehem;Jericho,2\n'
      'Who killed Goliath?,Bible Knowledge,text,easy,10,David,Saul;David;Solomon;Jonathan,1\n';

  Future<void> _downloadTemplate(BuildContext context) async {
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Questions Template',
      fileName: 'questions_template.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (savePath == null) return;
    await File(savePath).writeAsString(_templateCsv);
    if (context.mounted) {
      context.showSnackBar('Template saved — fill it in and import with "Import CSV"');
    }
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

  Future<void> _confirmClearAll(BuildContext context) async {
    final bloc = context.read<QuestionsBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all questions?'),
        content: const Text(
            'This will permanently delete every question in the database. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      bloc.add(const ClearAllQuestions());
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
  final String? filterCategoryId;

  const _QuestionsPanel({
    required this.questions,
    required this.categories,
    this.filterDifficulty,
    this.filterCategoryId,
  });

  @override
  Widget build(BuildContext context) {
    // Show reorder UI whenever a specific category is selected.
    // When "All" is shown, keep the plain list with difficulty filter.
    final canReorder = filterCategoryId != null;

    return Column(
      children: [
        if (canReorder)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.orangeBg.withOpacity(0.10),
            child: const Row(
              children: [
                Icon(Icons.drag_handle_rounded,
                    size: 16, color: AppColors.orangeBg),
                SizedBox(width: 8),
                Text(
                  'اسحب السؤال لتغيير ترتيبه',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.orangeBg,
                    fontWeight: FontWeight.w600,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          )
        else
          _DifficultyFilterBar(selected: filterDifficulty),
        Expanded(
          child: questions.isEmpty
              ? const Center(
                  child: Text(
                    AppStrings.noQuestionsYet,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : canReorder
                  ? _ReorderableQuestionList(
                      questions: questions,
                      categories: categories,
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
        const _AddQuestionButton(),
      ],
    );
  }
}

class _ReorderableQuestionList extends StatelessWidget {
  final List<Question> questions;
  final List<Category> categories;

  const _ReorderableQuestionList({
    required this.questions,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: questions.length,
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        // Flutter's ReorderableListView passes newIndex after removal,
        // so adjust when moving downward.
        final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
        final reordered = List<Question>.from(questions);
        final item = reordered.removeAt(oldIndex);
        reordered.insert(adjusted, item);
        context
            .read<QuestionsBloc>()
            .add(ReorderQuestions(reordered.map((q) => q.id).toList()));
      },
      itemBuilder: (context, index) {
        final question = questions[index];
        return _DraggableQuestionCard(
          key: ValueKey(question.id),
          question: question,
          categories: categories,
          index: index,
        );
      },
    );
  }
}

class _DraggableQuestionCard extends StatelessWidget {
  final Question question;
  final List<Category> categories;
  final int index;

  const _DraggableQuestionCard({
    super.key,
    required this.question,
    required this.categories,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rank number + drag handle stacked vertically
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 12, right: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.orangeBg.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.orangeBg.withOpacity(0.4)),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.orangeBg,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              ReorderableDragStartListener(
                index: index,
                child: const Icon(
                  Icons.drag_handle_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: QuestionCardWidget(
            question: question,
            categories: categories,
          ),
        ),
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
  const _AddQuestionButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.bottomRight,
        child: ElevatedButton.icon(
          onPressed: () => context.push('/questions/add'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.add, color: Colors.black),
          label: const Text(AppStrings.addQuestion,
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
