import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/glow_button.dart';
import '../../../questions/domain/entities/category.dart';
import '../../../questions/domain/entities/question.dart';
import '../../../questions/presentation/bloc/questions_bloc.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/bloc/teams_bloc.dart';
import '../../domain/entities/game_session.dart';
import '../bloc/game_bloc.dart';

/// 4-tab competition setup wizard.
/// [preselectedCategoryName] doubles as sectionName when coming from a banner.
class GameSetupScreen extends StatefulWidget {
  final String? preselectedCategoryName;
  const GameSetupScreen({super.key, this.preselectedCategoryName});

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  // ── Teams ─────────────────────────────────────────────────────────────────
  final Set<String> _selectedTeamIds = {};

  // ── Round 1 config ────────────────────────────────────────────────────────
  int _r1Timer = 30;
  int _questionsPerTeam = 5;
  String? _r1CategoryId;
  DifficultyLevel? _r1Difficulty;

  // ── Round 2 config ────────────────────────────────────────────────────────
  int _r2Timer = 20;
  String? _r2CategoryId;
  DifficultyLevel? _r2Difficulty;

  // ── Round 3 config ────────────────────────────────────────────────────────
  int _r3SharedTimer = 45;
  String? _r3CategoryId;
  DifficultyLevel? _r3Difficulty;
  /// teamId → contestant count (default 3)
  final Map<String, int> _contestantCounts = {};

  String? get _sectionName => widget.preselectedCategoryName;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);

    // Auto-select section teams
    final teamsState = context.read<TeamsBloc>().state;
    if (teamsState is TeamsLoaded && _sectionName != null) {
      final sectionTeams = _teamsForSection(teamsState.teams);
      _selectedTeamIds.addAll(sectionTeams.map((t) => t.id));
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<Team> _teamsForSection(List<Team> all) {
    if (_sectionName == null) return all;
    return all
        .where((t) => t.section == _sectionName || t.section.isEmpty)
        .toList();
  }

  List<Category> _categoriesForSection(List<Category> all) {
    if (_sectionName == null) return all;
    return all
        .where((c) => c.section == _sectionName || c.section.isEmpty)
        .toList();
  }

  List<Team> get _allAvailableTeams {
    final s = context.read<TeamsBloc>().state;
    if (s is TeamsLoaded) return _teamsForSection(s.teams);
    return [];
  }

  List<Team> get _selectedTeams =>
      _allAvailableTeams.where((t) => _selectedTeamIds.contains(t.id)).toList();

  List<Question> _filteredQuestions({
    String? categoryId,
    DifficultyLevel? difficulty,
    Set<String>? excludeIds,
  }) {
    final s = context.read<QuestionsBloc>().state;
    if (s is! QuestionsLoaded) return [];
    final sectionCatIds =
        _categoriesForSection(s.categories).map((c) => c.id).toSet();
    return s.questions.where((q) {
      if (!sectionCatIds.contains(q.categoryId)) return false;
      if (categoryId != null && q.categoryId != categoryId) return false;
      if (difficulty != null && q.difficulty != difficulty) return false;
      if (excludeIds != null && excludeIds.contains(q.id)) return false;
      return !q.isUsed;
    }).toList();
  }


  List<Category> get _sectionCategories {
    final s = context.read<QuestionsBloc>().state;
    if (s is! QuestionsLoaded) return [];
    return _categoriesForSection(s.categories);
  }

  int _contestantsForTeam(Team t) => _contestantCounts[t.id] ?? 3;

  // ── Validation + start ────────────────────────────────────────────────────

  void _startCompetition() {
    final teams = _selectedTeams;
    if (teams.length < 2) {
      context.showSnackBar('اختر فريقين على الأقل.', isError: true);
      return;
    }

    // Allocate R1 questions
    final r1Pool = _filteredQuestions(
        categoryId: _r1CategoryId, difficulty: _r1Difficulty);
    final r1Need = _questionsPerTeam * teams.length;
    if (r1Pool.length < r1Need) {
      context.showSnackBar(
          'أسئلة الفقرة الأولى غير كافية. محتاج $r1Need، متاح ${r1Pool.length}.',
          isError: true);
      _tabs.animateTo(1);
      return;
    }
    final r1Shuffled = [...r1Pool]..shuffle();
    final r1Questions = r1Shuffled.take(r1Need).toList();
    final usedIds = r1Questions.map((q) => q.id).toSet();

    // Allocate R2 questions
    final r2Pool = _filteredQuestions(
        categoryId: _r2CategoryId,
        difficulty: _r2Difficulty,
        excludeIds: usedIds);
    final r2Need = teams.length ~/ 2;
    if (r2Pool.length < r2Need) {
      context.showSnackBar(
          'أسئلة الفقرة الثانية غير كافية. محتاج $r2Need، متاح ${r2Pool.length}.',
          isError: true);
      _tabs.animateTo(2);
      return;
    }
    final r2Shuffled = [...r2Pool]..shuffle();
    final r2Questions = r2Shuffled.take(r2Need).toList();
    usedIds.addAll(r2Questions.map((q) => q.id));

    // Allocate R3 questions
    final contestantsPerTeam =
        teams.map((t) => _contestantsForTeam(t)).toList();
    final r3Need = contestantsPerTeam.fold(0, (s, c) => s + c);
    final r3Pool = _filteredQuestions(
        categoryId: _r3CategoryId,
        difficulty: _r3Difficulty,
        excludeIds: usedIds);
    if (r3Pool.length < r3Need) {
      context.showSnackBar(
          'أسئلة الفقرة الثالثة غير كافية. محتاج $r3Need، متاح ${r3Pool.length}.',
          isError: true);
      _tabs.animateTo(3);
      return;
    }
    final r3Shuffled = [...r3Pool]..shuffle();
    // Order R3 questions: [team0_q0..team0_qN, team1_q0..team1_qN, …]
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _sectionName != null
              ? 'المسابقة — $_sectionName'
              : 'إعداد المسابقة',
          textDirection: TextDirection.rtl,
        ),
        leading: BackButton(onPressed: () => context.go('/')),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.group), text: 'الفرق'),
            Tab(icon: Icon(Icons.quiz), text: 'فقرة ١'),
            Tab(icon: Icon(Icons.sports_soccer), text: 'فقرة ٢'),
            Tab(icon: Icon(Icons.speed), text: 'فقرة ٣'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _TeamsTab(this),
          _Round1Tab(this),
          _Round2Tab(this),
          _Round3Tab(this),
        ],
      ),
      bottomNavigationBar: _StartBar(onStart: _startCompetition),
    );
  }
}

// ── Tab: Teams ────────────────────────────────────────────────────────────────

class _TeamsTab extends StatelessWidget {
  final _GameSetupScreenState s;
  const _TeamsTab(this.s);

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder: (ctx, setState) {
      final teams = s._allAvailableTeams;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (s._sectionName != null) ...[
              _SectionBadge(s._sectionName!),
              const SizedBox(height: 20),
            ],
            _SectionHeader(
              title: 'اختر الفرق',
              subtitle:
                  '${s._selectedTeamIds.length} / ${teams.length} فريق محدد',
            ),
            const SizedBox(height: 12),
            if (teams.isEmpty)
              _EmptyHint(
                message: 'لا توجد فرق. أضف فرقاً أولاً.',
                action: 'إضافة فرق',
                onTap: () => context.go('/teams'),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: teams.map((t) {
                  final selected = s._selectedTeamIds.contains(t.id);
                  final teamColor = Color(t.color);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (selected) {
                          s._selectedTeamIds.remove(t.id);
                        } else {
                          s._selectedTeamIds.add(t.id);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? teamColor.withValues(alpha: 0.2)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              selected ? teamColor : AppColors.border,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: teamColor,
                            child: Text(
                              t.name.isNotEmpty
                                  ? t.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(t.name,
                              style: TextStyle(
                                color: selected
                                    ? teamColor
                                    : AppColors.textPrimary,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              )),
                          if (selected) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.check_circle,
                                size: 16, color: teamColor),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      );
    });
  }
}

// ── Tab: Round 1 ──────────────────────────────────────────────────────────────

class _Round1Tab extends StatelessWidget {
  final _GameSetupScreenState s;
  const _Round1Tab(this.s);

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder: (ctx, setState) {
      final categories = s._sectionCategories;
      final availableCount = s
          ._filteredQuestions(
              categoryId: s._r1CategoryId, difficulty: s._r1Difficulty)
          .length;
      final need = s._questionsPerTeam * s._selectedTeams.length;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RoundHeader(
              title: AppStrings.round1Name,
              subtitle: 'الأسئلة الكلاسيكية — كل فريق يأخذ دوره',
            ),
            const SizedBox(height: 20),

            // Questions per team
            _SectionHeader(
              title: AppStrings.questionsPerTeam,
              subtitle: '${s._questionsPerTeam} أسئلة لكل فريق',
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Text('1',
                  style:
                      TextStyle(color: AppColors.textSecondary)),
              Expanded(
                child: Slider(
                  value: s._questionsPerTeam.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '${s._questionsPerTeam}',
                  activeColor: AppColors.primary,
                  onChanged: (v) =>
                      setState(() => s._questionsPerTeam = v.round()),
                ),
              ),
              const Text('10',
                  style:
                      TextStyle(color: AppColors.textSecondary)),
            ]),

            const SizedBox(height: 20),

            // Timer
            _SectionHeader(
              title: 'وقت السؤال',
              subtitle: '${s._r1Timer} ثانية',
            ),
            const SizedBox(height: 8),
            Row(children: [
              _TimerChip(
                label: '20 ث',
                selected: s._r1Timer == 20,
                onTap: () => setState(() => s._r1Timer = 20),
              ),
              const SizedBox(width: 10),
              _TimerChip(
                label: '30 ث',
                selected: s._r1Timer == 30,
                onTap: () => setState(() => s._r1Timer = 30),
              ),
              const SizedBox(width: 10),
              _TimerChip(
                label: '45 ث',
                selected: s._r1Timer == 45,
                onTap: () => setState(() => s._r1Timer = 45),
              ),
              const SizedBox(width: 10),
              _TimerChip(
                label: '60 ث',
                selected: s._r1Timer == 60,
                onTap: () => setState(() => s._r1Timer = 60),
              ),
            ]),

            const SizedBox(height: 20),

            // Category filter
            _SectionHeader(
              title: 'تصفية الأسئلة',
              subtitle: '$availableCount متاح (محتاج $need)',
              subtitleColor: availableCount < need
                  ? AppColors.error
                  : AppColors.success,
            ),
            const SizedBox(height: 10),
            _CategoryFilterRow(
              categories: categories,
              selected: s._r1CategoryId,
              onChanged: (id) => setState(() => s._r1CategoryId = id),
            ),
            const SizedBox(height: 8),
            _DifficultyFilterRow(
              selected: s._r1Difficulty,
              onChanged: (d) => setState(() => s._r1Difficulty = d),
            ),
          ],
        ),
      );
    });
  }
}

// ── Tab: Round 2 ──────────────────────────────────────────────────────────────

class _Round2Tab extends StatelessWidget {
  final _GameSetupScreenState s;
  const _Round2Tab(this.s);

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder: (ctx, setState) {
      final categories = s._sectionCategories;
      final availableCount = s
          ._filteredQuestions(
              categoryId: s._r2CategoryId, difficulty: s._r2Difficulty)
          .length;
      final need = s._selectedTeams.length ~/ 2;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RoundHeader(
              title: AppStrings.round2Name,
              subtitle: 'كل اتنين يتنافسون — الأول يدوس يجاوب',
            ),
            const SizedBox(height: 20),

            _InfoBox(
              text:
                  '${s._selectedTeams.length ~/ 2} مباراة — الفرق بالترتيب:\n'
                  '${_pairsPreview(s._selectedTeams)}',
            ),
            const SizedBox(height: 20),

            // Timer
            _SectionHeader(
              title: 'وقت السؤال',
              subtitle: '${s._r2Timer} ثانية',
            ),
            const SizedBox(height: 8),
            Row(children: [
              _TimerChip(
                label: '15 ث',
                selected: s._r2Timer == 15,
                onTap: () => setState(() => s._r2Timer = 15),
              ),
              const SizedBox(width: 10),
              _TimerChip(
                label: '20 ث',
                selected: s._r2Timer == 20,
                onTap: () => setState(() => s._r2Timer = 20),
              ),
              const SizedBox(width: 10),
              _TimerChip(
                label: '30 ث',
                selected: s._r2Timer == 30,
                onTap: () => setState(() => s._r2Timer = 30),
              ),
            ]),

            const SizedBox(height: 20),

            // Category filter
            _SectionHeader(
              title: 'تصفية الأسئلة',
              subtitle: '$availableCount متاح (محتاج $need)',
              subtitleColor: availableCount < need
                  ? AppColors.error
                  : AppColors.success,
            ),
            const SizedBox(height: 10),
            _CategoryFilterRow(
              categories: categories,
              selected: s._r2CategoryId,
              onChanged: (id) => setState(() => s._r2CategoryId = id),
            ),
            const SizedBox(height: 8),
            _DifficultyFilterRow(
              selected: s._r2Difficulty,
              onChanged: (d) => setState(() => s._r2Difficulty = d),
            ),
          ],
        ),
      );
    });
  }

  String _pairsPreview(List<Team> teams) {
    final pairs = <String>[];
    for (int i = 0; i + 1 < teams.length; i += 2) {
      pairs.add('${teams[i].name} vs ${teams[i + 1].name}');
    }
    return pairs.join('\n');
  }
}

// ── Tab: Round 3 ──────────────────────────────────────────────────────────────

class _Round3Tab extends StatelessWidget {
  final _GameSetupScreenState s;
  const _Round3Tab(this.s);

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder: (ctx, setState) {
      final categories = s._sectionCategories;
      final teams = s._selectedTeams;
      int totalContestants = 0;
      for (final t in teams) {
        totalContestants += s._contestantsForTeam(t);
      }
      final available = s._filteredQuestions(
          categoryId: s._r3CategoryId, difficulty: s._r3Difficulty);

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RoundHeader(
              title: AppStrings.round3Name,
              subtitle: 'وقت مشترك للفريق — كل متسابق يجاوب سؤاله',
            ),
            const SizedBox(height: 20),

            // Shared timer
            _SectionHeader(
              title: AppStrings.sharedTimer,
              subtitle: '${s._r3SharedTimer} ثانية لكل فريق',
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Text('30',
                  style:
                      TextStyle(color: AppColors.textSecondary)),
              Expanded(
                child: Slider(
                  value: s._r3SharedTimer.toDouble(),
                  min: 30,
                  max: 120,
                  divisions: 18,
                  label: '${s._r3SharedTimer}',
                  activeColor: AppColors.primary,
                  onChanged: (v) =>
                      setState(() => s._r3SharedTimer = v.round()),
                ),
              ),
              const Text('120',
                  style:
                      TextStyle(color: AppColors.textSecondary)),
            ]),

            const SizedBox(height: 20),

            // Contestants per team
            _SectionHeader(
              title: 'متسابقون لكل فريق',
              subtitle: '$totalContestants متسابق إجمالي',
            ),
            const SizedBox(height: 12),
            if (teams.isEmpty)
              const Text(
                'اختر الفرق أولاً من التبويب الأول.',
                style: TextStyle(color: AppColors.textSecondary),
              )
            else
              ...teams.map((t) {
                final count = s._contestantsForTeam(t);
                final color = Color(t.color);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: color,
                        child: Text(
                          t.name.isNotEmpty
                              ? t.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(t.name,
                            style: const TextStyle(
                                color: AppColors.textPrimary)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle,
                            color: AppColors.error),
                        onPressed: count > 1
                            ? () => setState(() =>
                                s._contestantCounts[t.id] =
                                    count - 1)
                            : null,
                      ),
                      SizedBox(
                        width: 36,
                        child: Text(
                          '$count',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: color,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle,
                            color: AppColors.success),
                        onPressed: count < 10
                            ? () => setState(() =>
                                s._contestantCounts[t.id] =
                                    count + 1)
                            : null,
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 20),

            // Category filter
            _SectionHeader(
              title: 'تصفية الأسئلة',
              subtitle:
                  '${available.length} متاح (محتاج $totalContestants)',
              subtitleColor: available.length < totalContestants
                  ? AppColors.error
                  : AppColors.success,
            ),
            const SizedBox(height: 10),
            _CategoryFilterRow(
              categories: categories,
              selected: s._r3CategoryId,
              onChanged: (id) => setState(() => s._r3CategoryId = id),
            ),
            const SizedBox(height: 8),
            _DifficultyFilterRow(
              selected: s._r3Difficulty,
              onChanged: (d) => setState(() => s._r3Difficulty = d),
            ),
            const SizedBox(height: 32),
          ],
        ),
      );
    });
  }
}

// ── Start bar ─────────────────────────────────────────────────────────────────

class _StartBar extends StatelessWidget {
  final VoidCallback onStart;
  const _StartBar({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Center(
        child: GlowButton.accent(
          label: '🎮  ${AppStrings.startCompetition}',
          onPressed: onStart,
          width: 320,
          height: 56,
        ),
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _SectionBadge extends StatelessWidget {
  final String name;
  const _SectionBadge(this.name);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.group,
              color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            name,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _RoundHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textDirection: TextDirection.rtl,
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textDirection: TextDirection.rtl,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color? subtitleColor;
  const _SectionHeader(
      {required this.title,
      required this.subtitle,
      this.subtitleColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        Text(subtitle,
            style: TextStyle(
                color: subtitleColor ?? AppColors.textSecondary,
                fontSize: 13)),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String message;
  final String action;
  final VoidCallback onTap;
  const _EmptyHint(
      {required this.message,
      required this.action,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(message,
            style:
                const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(width: 12),
        TextButton(
            onPressed: onTap,
            child: Text(action,
                style: const TextStyle(color: AppColors.primary))),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;
  const _InfoBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        textDirection: TextDirection.rtl,
        style: const TextStyle(
            color: AppColors.textSecondary, fontSize: 13),
      ),
    );
  }
}

class _TimerChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TimerChip(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? AppColors.primary
                : AppColors.textSecondary,
            fontWeight: selected
                ? FontWeight.bold
                : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _CategoryFilterRow extends StatelessWidget {
  final List<Category> categories;
  final String? selected;
  final ValueChanged<String?> onChanged;
  const _CategoryFilterRow(
      {required this.categories,
      this.selected,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _FilterChip(
          label: 'الكل',
          selected: selected == null,
          color: AppColors.primary,
          onTap: () => onChanged(null),
        ),
        ...categories.map((c) => _FilterChip(
              label: c.name,
              selected: selected == c.id,
              color: Color(c.color),
              onTap: () => onChanged(c.id),
            )),
      ],
    );
  }
}

class _DifficultyFilterRow extends StatelessWidget {
  final DifficultyLevel? selected;
  final ValueChanged<DifficultyLevel?> onChanged;
  const _DifficultyFilterRow(
      {this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        _FilterChip(
            label: 'الكل',
            selected: selected == null,
            color: AppColors.primary,
            onTap: () => onChanged(null)),
        _FilterChip(
            label: 'سهل',
            selected: selected == DifficultyLevel.easy,
            color: AppColors.success,
            onTap: () => onChanged(DifficultyLevel.easy)),
        _FilterChip(
            label: 'متوسط',
            selected: selected == DifficultyLevel.medium,
            color: AppColors.accent,
            onTap: () => onChanged(DifficultyLevel.medium)),
        _FilterChip(
            label: 'صعب',
            selected: selected == DifficultyLevel.hard,
            color: AppColors.error,
            onTap: () => onChanged(DifficultyLevel.hard)),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label,
      required this.selected,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.2)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? color : AppColors.border,
              width: selected ? 1.5 : 1),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? color : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: selected
                    ? FontWeight.bold
                    : FontWeight.normal)),
      ),
    );
  }
}
