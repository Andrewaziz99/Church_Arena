import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/glow_button.dart';
import '../../../questions/domain/entities/question.dart';
import '../../../questions/presentation/bloc/questions_bloc.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/bloc/teams_bloc.dart';
import '../bloc/game_bloc.dart';

/// Full-screen setup wizard shown before a game starts.
/// Lets the user pick teams, filter questions, and set the timer.
class GameSetupScreen extends StatefulWidget {
  /// Optional category name to pre-select (passed from the banner buttons).
  final String? preselectedCategoryName;

  const GameSetupScreen({super.key, this.preselectedCategoryName});

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  final Set<String> _selectedTeamIds = {};
  String? _selectedCategoryId; // null = all
  DifficultyLevel? _selectedDifficulty; // null = all
  int _timerSeconds = 30;
  bool _randomOrder = true;

  @override
  void initState() {
    super.initState();
    // Pre-fill timer from settings
    final settingsState = context.read<SettingsBloc>().state;
    if (settingsState is SettingsLoaded) {
      _timerSeconds = settingsState.settings.timerDuration;
    }
    // Pre-select category from banner if provided
    if (widget.preselectedCategoryName != null) {
      final qState = context.read<QuestionsBloc>().state;
      if (qState is QuestionsLoaded) {
        final match = qState.categories.where(
          (c) => c.name == widget.preselectedCategoryName,
        );
        if (match.isNotEmpty) _selectedCategoryId = match.first.id;
      }
    }
  }

  List<Team> get _teams {
    final state = context.read<TeamsBloc>().state;
    if (state is TeamsLoaded) return state.teams;
    return [];
  }

  List<Question> get _filteredQuestions {
    final state = context.read<QuestionsBloc>().state;
    if (state is! QuestionsLoaded) return [];
    return state.questions.where((q) {
      if (_selectedCategoryId != null && q.categoryId != _selectedCategoryId) {
        return false;
      }
      if (_selectedDifficulty != null && q.difficulty != _selectedDifficulty) {
        return false;
      }
      return !q.isUsed;
    }).toList();
  }

  void _startGame() {
    final teams =
        _teams.where((t) => _selectedTeamIds.contains(t.id)).toList();
    if (teams.length < 2) {
      context.showSnackBar('Select at least 2 teams.', isError: true);
      return;
    }
    var questions = _filteredQuestions;
    if (questions.isEmpty) {
      context.showSnackBar('No questions available.', isError: true);
      return;
    }
    if (_randomOrder) questions = [...questions]..shuffle();

    context.read<GameBloc>().add(StartGame(teams, questions, _timerSeconds));
    context.go('/game');
  }

  @override
  Widget build(BuildContext context) {
    final teams = _teams;
    final questionsState = context.watch<QuestionsBloc>().state;
    final categories =
        questionsState is QuestionsLoaded ? questionsState.categories : [];
    final availableCount = _filteredQuestions.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Setup'),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Teams ──────────────────────────────────────────────────────
            _SectionHeader(title: 'Select Teams', subtitle: 'Choose 2–8 teams'),
            const SizedBox(height: 12),
            if (teams.isEmpty)
              _EmptyHint(
                message: 'No teams yet.',
                action: 'Add Teams',
                onTap: () => context.go('/teams'),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: teams.map((t) {
                  final selected = _selectedTeamIds.contains(t.id);
                  final teamColor = Color(t.color);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (selected) {
                        _selectedTeamIds.remove(t.id);
                      } else {
                        _selectedTeamIds.add(t.id);
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? teamColor.withOpacity(0.2)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? teamColor
                              : AppColors.border,
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

            const SizedBox(height: 28),

            // ── Questions filter ───────────────────────────────────────────
            _SectionHeader(
              title: 'Questions',
              subtitle: '$availableCount available',
            ),
            const SizedBox(height: 12),
            if (questionsState is QuestionsLoaded &&
                questionsState.questions.isEmpty)
              _EmptyHint(
                message: 'No questions yet.',
                action: 'Add Questions',
                onTap: () => context.go('/questions'),
              )
            else ...[
              // Category filter
              Text('Category',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _selectedCategoryId == null,
                    color: AppColors.primary,
                    onTap: () =>
                        setState(() => _selectedCategoryId = null),
                  ),
                  ...categories.map((c) => _FilterChip(
                        label: c.name,
                        selected: _selectedCategoryId == c.id,
                        color: Color(c.color),
                        onTap: () =>
                            setState(() => _selectedCategoryId = c.id),
                      )),
                ],
              ),
              const SizedBox(height: 12),
              // Difficulty filter
              Text('Difficulty',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  _FilterChip(
                      label: 'All',
                      selected: _selectedDifficulty == null,
                      color: AppColors.primary,
                      onTap: () =>
                          setState(() => _selectedDifficulty = null)),
                  _FilterChip(
                      label: 'Easy',
                      selected:
                          _selectedDifficulty == DifficultyLevel.easy,
                      color: AppColors.success,
                      onTap: () => setState(
                          () => _selectedDifficulty = DifficultyLevel.easy)),
                  _FilterChip(
                      label: 'Medium',
                      selected:
                          _selectedDifficulty == DifficultyLevel.medium,
                      color: AppColors.accent,
                      onTap: () => setState(() =>
                          _selectedDifficulty = DifficultyLevel.medium)),
                  _FilterChip(
                      label: 'Hard',
                      selected:
                          _selectedDifficulty == DifficultyLevel.hard,
                      color: AppColors.error,
                      onTap: () => setState(
                          () => _selectedDifficulty = DifficultyLevel.hard)),
                ],
              ),
            ],

            const SizedBox(height: 28),

            // ── Timer ──────────────────────────────────────────────────────
            _SectionHeader(
              title: 'Timer',
              subtitle: '$_timerSeconds seconds per question',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('10s',
                    style: TextStyle(color: AppColors.textSecondary)),
                Expanded(
                  child: Slider(
                    value: _timerSeconds.toDouble(),
                    min: 10,
                    max: 120,
                    divisions: 22,
                    label: '${_timerSeconds}s',
                    activeColor: AppColors.primary,
                    onChanged: (v) =>
                        setState(() => _timerSeconds = v.round()),
                  ),
                ),
                const Text('120s',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),

            const SizedBox(height: 16),

            // ── Random order ───────────────────────────────────────────────
            Row(
              children: [
                Switch(
                  value: _randomOrder,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _randomOrder = v),
                ),
                const SizedBox(width: 12),
                const Text('Random question order',
                    style: TextStyle(color: AppColors.textPrimary)),
              ],
            ),

            const SizedBox(height: 36),

            // ── Start button ───────────────────────────────────────────────
            Center(
              child: GlowButton.accent(
                label: '🎮  Start Game',
                onPressed: _startGame,
                width: 280,
                height: 56,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Private helpers ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        Text(subtitle,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String message;
  final String action;
  final VoidCallback onTap;
  const _EmptyHint(
      {required this.message, required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(message,
            style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(width: 12),
        TextButton(
          onPressed: onTap,
          child: Text(action,
              style: const TextStyle(color: AppColors.primary)),
        ),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? color : AppColors.border,
              width: selected ? 1.5 : 1),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? color : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}
