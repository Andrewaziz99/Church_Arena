import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../questions/domain/entities/category.dart';
import '../../../questions/domain/entities/question.dart';
import '../../../questions/presentation/bloc/questions_bloc.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/bloc/teams_bloc.dart';
import '../../domain/entities/game_session.dart';
import '../bloc/game_bloc.dart';

class GameSetupScreen extends StatefulWidget {
  final String? preselectedCategoryName;
  const GameSetupScreen({super.key, this.preselectedCategoryName});

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  // ── Teams ──────────────────────────────────────────────────────────────────
  final Set<String> _selectedTeamIds = {};

  // ── Round 1 ────────────────────────────────────────────────────────────────
  int _r1Timer = 30;
  int _questionsPerTeam = 5;
  String? _r1CategoryId;
  DifficultyLevel? _r1Difficulty;

  // ── Round 2 ────────────────────────────────────────────────────────────────
  int _r2Timer = 20;
  String? _r2CategoryId;
  DifficultyLevel? _r2Difficulty;

  // ── Round 3 ────────────────────────────────────────────────────────────────
  int _r3SharedTimer = 45;
  String? _r3CategoryId;
  DifficultyLevel? _r3Difficulty;
  final Map<String, int> _contestantCounts = {};

  String? get _sectionName => widget.preselectedCategoryName;

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<Team> _filterTeams(List<Team> all) {
    if (_sectionName == null) return all;
    return all.where((t) => t.section == _sectionName || t.section.isEmpty).toList();
  }

  List<Category> _filterCategories(List<Category> all) {
    if (_sectionName == null) return all;
    return all.where((c) => c.section == _sectionName || c.section.isEmpty).toList();
  }

  List<Question> _pool({
    required List<Question> all,
    required List<Category> sectionCats,
    required String roundType,
    String? categoryId,
    DifficultyLevel? difficulty,
    Set<String>? excludeIds,
  }) {
    // When no specific category is chosen, restrict to round-typed categories.
    final catIds = categoryId != null
        ? {categoryId}
        : sectionCats
            .where((c) => c.roundType == roundType || c.roundType.isEmpty)
            .map((c) => c.id)
            .toSet();
    return all.where((q) {
      if (!catIds.contains(q.categoryId)) return false;
      if (difficulty != null && q.difficulty != difficulty) return false;
      if (excludeIds != null && excludeIds.contains(q.id)) return false;
      return !q.isUsed;
    }).toList();
  }

  int _contestantsFor(Team t) => _contestantCounts[t.id] ?? 3;

  void _showError(String msg) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.error_outline, color: AppColors.redError),
          SizedBox(width: 8),
          Text('تنبيه', style: TextStyle(color: AppColors.redError)),
        ]),
        content: Text(msg, textDirection: TextDirection.rtl,
            style: GoogleFonts.alexandria(fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('حسناً', style: GoogleFonts.alexandria(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _start(List<Team> sectionTeams, List<Question> allQ, List<Category> allCats) {
    final sectionCats = _filterCategories(allCats);
    final teams = sectionTeams.where((t) => _selectedTeamIds.contains(t.id)).toList();

    if (teams.length < 2) {
      _showError('اختر فريقين على الأقل.');
      return;
    }

    // R1
    final r1Pool = _pool(all: allQ, sectionCats: sectionCats, roundType: 'r1', categoryId: _r1CategoryId, difficulty: _r1Difficulty);
    final r1Need = _questionsPerTeam * teams.length;
    if (r1Pool.length < r1Need) {
      _showError('أسئلة الفقرة الأولى غير كافية.\nمحتاج $r1Need، متاح ${r1Pool.length}.\n\nاضغط SEED DATA في الداشبورد لإضافة أسئلة تجريبية.');
      return;
    }
    final r1Shuffled = [...r1Pool]..shuffle();
    final r1Questions = r1Shuffled.take(r1Need).toList();
    final usedIds = r1Questions.map((q) => q.id).toSet();

    // R2
    final r2Pool = _pool(all: allQ, sectionCats: sectionCats, roundType: 'r2', categoryId: _r2CategoryId, difficulty: _r2Difficulty, excludeIds: usedIds);
    final r2Need = teams.length ~/ 2;
    if (r2Pool.length < r2Need) {
      _showError('أسئلة الفقرة الثانية غير كافية.\nمحتاج $r2Need، متاح ${r2Pool.length}.');
      return;
    }
    final r2Shuffled = [...r2Pool]..shuffle();
    final r2Questions = r2Shuffled.take(r2Need).toList();
    usedIds.addAll(r2Questions.map((q) => q.id));

    // R3
    final contestantsPerTeam = teams.map(_contestantsFor).toList();
    final r3Need = contestantsPerTeam.fold(0, (s, c) => s + c);
    final r3Pool = _pool(all: allQ, sectionCats: sectionCats, roundType: 'r3', categoryId: _r3CategoryId, difficulty: _r3Difficulty, excludeIds: usedIds);
    if (r3Pool.length < r3Need) {
      _showError('أسئلة الفقرة الثالثة غير كافية.\nمحتاج $r3Need، متاح ${r3Pool.length}.');
      return;
    }
    final r3Shuffled = [...r3Pool]..shuffle();
    final r3Questions = r3Shuffled.take(r3Need).toList();

    context.read<GameBloc>().add(StartCompetition(
      teams: teams,
      round1Questions: r1Questions,
      round1Timer: _r1Timer,
      questionsPerTeam: _questionsPerTeam,
      round2Questions: r2Questions,
      round2Timer: _r2Timer,
      round3Questions: r3Questions,
      sharedTimer: _r3SharedTimer,
      contestantsPerTeam: contestantsPerTeam,
    ));
    context.go('/game');
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TeamsBloc, TeamsState>(
      builder: (context, teamsState) {
        return BlocBuilder<QuestionsBloc, QuestionsState>(
          builder: (context, questionsState) {
            final sectionTeams = teamsState is TeamsLoaded
                ? _filterTeams(teamsState.teams)
                : <Team>[];
            final allQ = questionsState is QuestionsLoaded
                ? questionsState.questions
                : <Question>[];
            final allCats = questionsState is QuestionsLoaded
                ? questionsState.categories
                : <Category>[];
            final sectionCats = _filterCategories(allCats);
            final selectedTeams = sectionTeams
                .where((t) => _selectedTeamIds.contains(t.id))
                .toList();

            return Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: AppColors.blueContent,
                foregroundColor: Colors.white,
                elevation: 0,
                title: Text(
                  _sectionName != null ? 'مسابقة — $_sectionName' : 'إعداد المسابقة',
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.alexandria(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                ),
                leading: BackButton(
                  color: Colors.white,
                  onPressed: () => context.canPop() ? context.pop() : context.go('/'),
                ),
              ),
              body: Stack(
                  children: [
                    Image.asset('assets/images/Artboard.png', fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // ── Section badge ──────────────────────────────────────────
                          if (_sectionName != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.orangeBg.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.orangeBg),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.groups_rounded, color: AppColors.orangeDark, size: 18),
                                  const SizedBox(width: 8),
                                  Text(_sectionName!,
                                      textDirection: TextDirection.rtl,
                                      style: GoogleFonts.alexandria(color: AppColors.orangeDark, fontWeight: FontWeight.w800, fontSize: 15)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // ── 1. Teams ───────────────────────────────────────────────
                          _Card(
                            title: 'الفرق المشاركة',
                            icon: Icons.groups_rounded,
                            color: AppColors.blueContent,
                            child: sectionTeams.isEmpty
                                ? Row(children: [
                              Text('لا توجد فرق بعد.',
                                  style: GoogleFonts.alexandria(color: AppColors.textSecondary, fontSize: 13)),
                              const SizedBox(width: 12),
                              TextButton(
                                onPressed: () => context.go('/teams'),
                                child: Text('إضافة فرق',
                                    style: GoogleFonts.alexandria(color: AppColors.blueContent, fontWeight: FontWeight.bold)),
                              ),
                            ])
                                : Wrap(
                              spacing: 10, runSpacing: 8,
                              children: sectionTeams.map((t) {
                                final sel = _selectedTeamIds.contains(t.id);
                                final c = Color(t.color);
                                return GestureDetector(
                                  onTap: () => setState(() {
                                    if (sel) _selectedTeamIds.remove(t.id);
                                    else _selectedTeamIds.add(t.id);
                                  }),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: sel ? c.withOpacity(0.15) : AppColors.surfaceLight,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: sel ? c : AppColors.border, width: sel ? 2 : 1),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(radius: 11, backgroundColor: c,
                                            child: Text(t.name.isNotEmpty ? t.name[0].toUpperCase() : '?',
                                                style: const TextStyle(fontSize: 9, color: Colors.white))),
                                        const SizedBox(width: 8),
                                        Text(t.name, style: GoogleFonts.alexandria(
                                            color: sel ? c : AppColors.textPrimary,
                                            fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                                            fontSize: 13)),
                                        if (sel) ...[
                                          const SizedBox(width: 6),
                                          Icon(Icons.check_circle_rounded, size: 14, color: c),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // ── 2. Round 1 ─────────────────────────────────────────────
                          _Card(
                            title: 'الفقرة الأولى — أسئلة الفرق',
                            icon: Icons.quiz_rounded,
                            color: AppColors.greenSuccess,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Label(text: 'أسئلة لكل فريق', value: '$_questionsPerTeam'),
                                Slider(
                                  value: _questionsPerTeam.toDouble(),
                                  min: 1, max: 10, divisions: 9,
                                  activeColor: AppColors.greenSuccess,
                                  label: '$_questionsPerTeam',
                                  onChanged: (v) => setState(() => _questionsPerTeam = v.round()),
                                ),
                                const SizedBox(height: 6),
                                _Label(text: 'وقت السؤال', value: '$_r1Timer ث'),
                                const SizedBox(height: 6),
                                _TimerChips(
                                  values: const [20, 30, 45, 60],
                                  selected: _r1Timer,
                                  color: AppColors.greenSuccess,
                                  onSelect: (v) => setState(() => _r1Timer = v),
                                ),
                                const SizedBox(height: 14),
                                _FilterBlock(
                                  categories: sectionCats.where((c) => c.roundType == 'r1' || c.roundType.isEmpty).toList(),
                                  allQuestions: allQ,
                                  roundType: 'r1',
                                  selectedCategoryId: _r1CategoryId,
                                  selectedDifficulty: _r1Difficulty,
                                  need: _questionsPerTeam * _selectedTeamIds.length,
                                  color: AppColors.greenSuccess,
                                  onCatChanged: (id) => setState(() => _r1CategoryId = id),
                                  onDiffChanged: (d) => setState(() => _r1Difficulty = d),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // ── 3. Round 2 ─────────────────────────────────────────────
                          _Card(
                            title: 'الفقرة الثانية — ضربات جزاء',
                            icon: Icons.sports_soccer_rounded,
                            color: AppColors.blueContent,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.blueContent.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'كل اتنين فرق بيتنافسوا — اللي يدوس الزرار أول ويجاوب صح يكسب النقط.',
                                    textDirection: TextDirection.rtl,
                                    style: GoogleFonts.alexandria(color: AppColors.blueContent, fontSize: 13),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _Label(text: 'وقت السؤال', value: '$_r2Timer ث'),
                                const SizedBox(height: 6),
                                _TimerChips(
                                  values: const [15, 20, 30],
                                  selected: _r2Timer,
                                  color: AppColors.blueContent,
                                  onSelect: (v) => setState(() => _r2Timer = v),
                                ),
                                const SizedBox(height: 14),
                                _FilterBlock(
                                  categories: sectionCats.where((c) => c.roundType == 'r2' || c.roundType.isEmpty).toList(),
                                  allQuestions: allQ,
                                  roundType: 'r2',
                                  selectedCategoryId: _r2CategoryId,
                                  selectedDifficulty: _r2Difficulty,
                                  need: _selectedTeamIds.length ~/ 2,
                                  color: AppColors.blueContent,
                                  onCatChanged: (id) => setState(() => _r2CategoryId = id),
                                  onDiffChanged: (d) => setState(() => _r2Difficulty = d),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // ── 4. Round 3 ─────────────────────────────────────────────
                          _Card(
                            title: 'الفقرة الثالثة — تحت الضغط',
                            icon: Icons.speed_rounded,
                            color: AppColors.redError,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Label(text: 'وقت الفريق المشترك', value: '$_r3SharedTimer ث'),
                                Slider(
                                  value: _r3SharedTimer.toDouble(),
                                  min: 30, max: 120, divisions: 18,
                                  activeColor: AppColors.redError,
                                  label: '$_r3SharedTimer',
                                  onChanged: (v) => setState(() => _r3SharedTimer = v.round()),
                                ),
                                const SizedBox(height: 8),
                                Text('عدد المتسابقين لكل فريق:',
                                    style: GoogleFonts.alexandria(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                if (selectedTeams.isEmpty)
                                  Text('اختر الفرق أولاً من القسم أعلاه.',
                                      style: GoogleFonts.alexandria(color: AppColors.textSecondary, fontSize: 13))
                                else
                                  ...selectedTeams.map((t) {
                                    final count = _contestantsFor(t);
                                    final c = Color(t.color);
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          CircleAvatar(radius: 13, backgroundColor: c,
                                              child: Text(t.name.isNotEmpty ? t.name[0].toUpperCase() : '?',
                                                  style: const TextStyle(color: Colors.white, fontSize: 11))),
                                          const SizedBox(width: 10),
                                          Expanded(child: Text(t.name,
                                              style: GoogleFonts.alexandria(color: AppColors.textPrimary, fontSize: 14))),
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline, color: AppColors.redError, size: 22),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            onPressed: count > 1
                                                ? () => setState(() => _contestantCounts[t.id] = count - 1)
                                                : null,
                                          ),
                                          SizedBox(
                                            width: 36,
                                            child: Text('$count',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.alexandria(fontSize: 20, fontWeight: FontWeight.w900, color: c)),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle_outline, color: AppColors.greenSuccess, size: 22),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            onPressed: count < 10
                                                ? () => setState(() => _contestantCounts[t.id] = count + 1)
                                                : null,
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                const SizedBox(height: 14),
                                _FilterBlock(
                                  categories: sectionCats.where((c) => c.roundType == 'r3' || c.roundType.isEmpty).toList(),
                                  allQuestions: allQ,
                                  roundType: 'r3',
                                  selectedCategoryId: _r3CategoryId,
                                  selectedDifficulty: _r3Difficulty,
                                  need: selectedTeams.fold(0, (s, t) => s + _contestantsFor(t)),
                                  color: AppColors.redError,
                                  onCatChanged: (id) => setState(() => _r3CategoryId = id),
                                  onDiffChanged: (d) => setState(() => _r3Difficulty = d),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    )
                  ],
              ),

              // ── Start button ───────────────────────────────────────────────
              bottomNavigationBar: Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _start(sectionTeams, allQ, allCats),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blueContent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🎮', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Text(AppStrings.startCompetition,
                            style: GoogleFonts.alexandria(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;
  const _Card({required this.title, required this.icon, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.09),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: color.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(title,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.alexandria(fontWeight: FontWeight.w800, color: color, fontSize: 15)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final String value;
  const _Label({required this.text, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text, textDirection: TextDirection.rtl,
            style: GoogleFonts.alexandria(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        Text(value, style: GoogleFonts.alexandria(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _TimerChips extends StatelessWidget {
  final List<int> values;
  final int selected;
  final Color color;
  final ValueChanged<int> onSelect;
  const _TimerChips({required this.values, required this.selected, required this.color, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: values.map((v) {
        final sel = v == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onSelect(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? color.withOpacity(0.12) : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? color : AppColors.border, width: sel ? 2 : 1),
              ),
              child: Text('$v ث',
                  style: GoogleFonts.alexandria(
                      color: sel ? color : AppColors.textSecondary,
                      fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13)),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FilterBlock extends StatelessWidget {
  final List<Category> categories;
  final List<Question> allQuestions;
  final String roundType;
  final String? selectedCategoryId;
  final DifficultyLevel? selectedDifficulty;
  final ValueChanged<String?> onCatChanged;
  final ValueChanged<DifficultyLevel?> onDiffChanged;
  final int need;
  final Color color;

  const _FilterBlock({
    required this.categories,
    required this.allQuestions,
    required this.roundType,
    this.selectedCategoryId,
    this.selectedDifficulty,
    required this.onCatChanged,
    required this.onDiffChanged,
    required this.need,
    required this.color,
  });

  int get _available {
    final catIds = selectedCategoryId != null
        ? {selectedCategoryId!}
        : categories.map((c) => c.id).toSet();
    return allQuestions.where((q) {
      if (!catIds.contains(q.categoryId)) return false;
      if (selectedDifficulty != null && q.difficulty != selectedDifficulty) return false;
      return !q.isUsed;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final avail = _available;
    final ok = need == 0 || avail >= need;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Availability badge
        Row(
          children: [
            Icon(ok ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                size: 15, color: ok ? AppColors.greenSuccess : AppColors.redError),
            const SizedBox(width: 6),
            Text(
              need > 0 ? '$avail أسئلة متاحة (محتاج $need)' : '$avail أسئلة متاحة',
              textDirection: TextDirection.rtl,
              style: GoogleFonts.alexandria(
                  fontSize: 12,
                  color: ok ? AppColors.greenSuccess : AppColors.redError,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),

        if (categories.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('فئة:', style: GoogleFonts.alexandria(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _SmallChip(label: 'الكل', sel: selectedCategoryId == null, color: color, onTap: () => onCatChanged(null)),
            ...categories.map((c) => _SmallChip(
                label: c.name, sel: selectedCategoryId == c.id,
                color: Color(c.color), onTap: () => onCatChanged(c.id))),
          ]),
        ],

        const SizedBox(height: 10),
        Text('صعوبة:', style: GoogleFonts.alexandria(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, children: [
          _SmallChip(label: 'الكل', sel: selectedDifficulty == null, color: color, onTap: () => onDiffChanged(null)),
          _SmallChip(label: 'سهل', sel: selectedDifficulty == DifficultyLevel.easy, color: AppColors.greenSuccess, onTap: () => onDiffChanged(DifficultyLevel.easy)),
          _SmallChip(label: 'متوسط', sel: selectedDifficulty == DifficultyLevel.medium, color: AppColors.orangeDark, onTap: () => onDiffChanged(DifficultyLevel.medium)),
          _SmallChip(label: 'صعب', sel: selectedDifficulty == DifficultyLevel.hard, color: AppColors.redError, onTap: () => onDiffChanged(DifficultyLevel.hard)),
        ]),
      ],
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String label;
  final bool sel;
  final Color color;
  final VoidCallback onTap;
  const _SmallChip({required this.label, required this.sel, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: sel ? color.withOpacity(0.13) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? color : AppColors.border, width: sel ? 1.5 : 1),
        ),
        child: Text(label,
            style: GoogleFonts.alexandria(
                color: sel ? color : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}
