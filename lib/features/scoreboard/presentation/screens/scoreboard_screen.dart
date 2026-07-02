import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../scoreboard/domain/competition_result.dart';
import '../../../teams/domain/entities/team.dart';
import '../bloc/scoreboard_bloc.dart';

class ScoreboardScreen extends StatefulWidget {
  const ScoreboardScreen({super.key});

  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  late final ConfettiController _confetti;
  CompetitionResult? _selectedResult;
  bool _viewingHistory = false;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 6));
    // Always load history on open
    context.read<ScoreboardBloc>().add(const LoadResults());
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scoreboardBg,
      body: BlocConsumer<ScoreboardBloc, ScoreboardState>(
        listener: (context, state) {
          if (state is ScoreboardLoaded && state.showConfetti) {
            _confetti.play();
            _viewingHistory = false;
          }
          // Auto-select the most recent result in history
          if (state is ScoreboardHistory && state.history.isNotEmpty) {
            setState(() => _selectedResult ??= state.history.first);
          }
          if (state is ScoreboardLoaded && state.history.isNotEmpty) {
            setState(() => _selectedResult ??= state.history.first);
          }
        },
        builder: (context, state) {
          // ── Full-page "just finished" result ─────────────────────────────
          if (state is ScoreboardLoaded && !_viewingHistory) {
            return _CurrentResultView(
              teams: state.rankedTeams,
              history: state.history,
              confetti: _confetti,
              onViewHistory: () => setState(() => _viewingHistory = true),
            );
          }

          // ── History browser ──────────────────────────────────────────────
          final history = state is ScoreboardLoaded
              ? state.history
              : state is ScoreboardHistory
                  ? state.history
                  : <CompetitionResult>[];

          final loading =
              state is ScoreboardHistory && state.loading;

          return _HistoryBrowser(
            history: history,
            loading: loading,
            selected: _selectedResult,
            confetti: _confetti,
            onSelect: (r) => setState(() => _selectedResult = r),
            onDelete: (id) {
              context.read<ScoreboardBloc>().add(DeleteResult(id));
              if (_selectedResult?.id == id) {
                setState(() => _selectedResult = null);
              }
            },
            onBack: () => context.canPop() ? context.pop() : context.go('/'),
          );
        },
      ),
    );
  }
}

// ── Current result (shown right after a game ends) ─────────────────────────────

class _CurrentResultView extends StatelessWidget {
  final List<Team> teams;
  final List<CompetitionResult> history;
  final ConfettiController confetti;
  final VoidCallback onViewHistory;

  const _CurrentResultView({
    required this.teams,
    required this.history,
    required this.confetti,
    required this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.3, -0.2),
                radius: 1.2,
                colors: [Color(0xFF1B3A6B), Color(0xFF0A1020)],
              ),
            ),
          ),
        ),

        // Confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 30,
            gravity: 0.05,
            colors: const [
              AppColors.orangeBg,
              AppColors.greenLight,
              AppColors.blueLight,
              Colors.white,
            ],
          ),
        ),

        // Content
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LEADERBOARD',
                        style: GoogleFonts.alexandria(
                          fontSize: 60,
                          fontWeight: FontWeight.w900,
                          color: AppColors.orangeBg,
                          letterSpacing: -2,
                          height: 1,
                        ),
                      ),
                      Text(
                        DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                        style: GoogleFonts.alexandria(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white54,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // History button
                  OutlinedButton.icon(
                    onPressed: onViewHistory,
                    icon: const Icon(Icons.history_rounded,
                        color: Colors.white70, size: 18),
                    label: Text(
                      'History (${history.length})',
                      style: GoogleFonts.alexandria(
                          color: Colors.white70, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.home_rounded,
                        color: Colors.white70, size: 18),
                    label: Text(
                      AppStrings.backToDashboard,
                      style: GoogleFonts.alexandria(
                          color: Colors.white70, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              Expanded(
                child: teams.isEmpty
                    ? Center(
                        child: Text('No results',
                            style: GoogleFonts.alexandria(
                                color: Colors.white54)))
                    : _SectionedScoreboard(teams: teams),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.replay_rounded),
                      label: Text(AppStrings.playAgain,
                          style: GoogleFonts.alexandria(
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── History browser ────────────────────────────────────────────────────────────

class _HistoryBrowser extends StatelessWidget {
  final List<CompetitionResult> history;
  final bool loading;
  final CompetitionResult? selected;
  final ConfettiController confetti;
  final ValueChanged<CompetitionResult> onSelect;
  final ValueChanged<String> onDelete;
  final VoidCallback onBack;

  const _HistoryBrowser({
    required this.history,
    required this.loading,
    required this.selected,
    required this.confetti,
    required this.onSelect,
    required this.onDelete,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.3, -0.2),
                radius: 1.2,
                colors: [Color(0xFF1B3A6B), Color(0xFF0A1020)],
              ),
            ),
          ),
        ),

        Row(
          children: [
            // ── Left: result list ──────────────────────────────────────────
            SizedBox(
              width: 320,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: onBack,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white70, size: 16),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'HISTORY',
                          style: GoogleFonts.alexandria(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.orangeBg,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      '${history.length} competition${history.length != 1 ? 's' : ''} saved',
                      style: GoogleFonts.alexandria(
                          fontSize: 12,
                          color: Colors.white38,
                          letterSpacing: 0.5),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // List
                  Expanded(
                    child: loading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.orangeBg))
                        : history.isEmpty
                            ? Center(
                                child: Text(
                                  'No past results yet.\nPlay a game to record one!',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.alexandria(
                                      color: Colors.white38, fontSize: 14),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                itemCount: history.length,
                                itemBuilder: (ctx, i) {
                                  final r = history[i];
                                  final isSelected = r.id == selected?.id;
                                  return _ResultListTile(
                                    result: r,
                                    isSelected: isSelected,
                                    onTap: () => onSelect(r),
                                    onDelete: () => onDelete(r.id),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),

            // Divider
            Container(width: 1, color: Colors.white12),

            // ── Right: detail panel ────────────────────────────────────────
            Expanded(
              child: selected == null
                  ? Center(
                      child: Text(
                        'Select a result to view',
                        style: GoogleFonts.alexandria(
                            color: Colors.white38, fontSize: 16),
                      ),
                    )
                  : _ResultDetail(result: selected!),
            ),
          ],
        ),
      ],
    );
  }
}

class _ResultListTile extends StatelessWidget {
  final CompetitionResult result;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ResultListTile({
    required this.result,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final winner = result.winner;
    final dateStr = DateFormat('d MMM yyyy  HH:mm').format(result.completedAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.orangeBg.withOpacity(0.18)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.orangeBg.withOpacity(0.6)
                  : Colors.white12,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Trophy icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.orangeBg.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events_rounded,
                    color: AppColors.orangeBg, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      winner?.name ?? '—',
                      style: GoogleFonts.alexandria(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: GoogleFonts.alexandria(
                          fontSize: 10,
                          color: Colors.white38,
                          letterSpacing: 0.3),
                    ),
                  ],
                ),
              ),
              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 16, color: Colors.white30),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete result?'),
                      content: Text(
                          'Remove the result from ${dateStr}? This cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) onDelete();
                },
                tooltip: 'Delete',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultDetail extends StatelessWidget {
  final CompetitionResult result;

  const _ResultDetail({required this.result});

  @override
  Widget build(BuildContext context) {
    final teams = result.teams
        .map((s) => Team(
              id: s.id,
              name: s.name,
              color: s.color,
              score: s.score,
              section: s.section,
            ))
        .toList();

    final dateStr =
        DateFormat('EEEE, d MMMM yyyy  •  HH:mm').format(result.completedAt);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RESULT',
            style: GoogleFonts.alexandria(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: AppColors.orangeBg,
              letterSpacing: -1,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateStr,
            style: GoogleFonts.alexandria(
                fontSize: 13, color: Colors.white38, letterSpacing: 1),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: teams.isEmpty
                ? Center(
                    child: Text('No team data',
                        style: GoogleFonts.alexandria(color: Colors.white38)))
                : _SectionedScoreboard(teams: teams),
          ),
        ],
      ),
    );
  }
}

// ── Sectioned scoreboard (shared between current result and history detail) ────

class _SectionedScoreboard extends StatelessWidget {
  final List<Team> teams;
  const _SectionedScoreboard({required this.teams});

  static const _sections = [
    ('اولى وثانية', Color(0xFF1565C0), '١ & ٢'),
    ('ثالثة ورابعة', Color(0xFF6A1B9A), '٣ & ٤'),
    ('خامسة وسادسة', Color(0xFF1B5E20), '٥ & ٦'),
  ];

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Team>> grouped = {};
    for (final (key, _, __) in _sections) {
      grouped[key] = [];
    }
    final others = <Team>[];
    for (final team in teams) {
      if (grouped.containsKey(team.section)) {
        grouped[team.section]!.add(team);
      } else {
        others.add(team);
      }
    }
    for (final list in grouped.values) {
      list.sort((a, b) => b.score.compareTo(a.score));
    }
    others.sort((a, b) => b.score.compareTo(a.score));

    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < _sections.length; i++) ...[
                if (i > 0) const SizedBox(width: 16),
                Expanded(
                  child: _GradeSection(
                    label: _sections[i].$3,
                    subtitle: _sections[i].$1,
                    color: _sections[i].$2,
                    teams: grouped[_sections[i].$1] ?? [],
                  )
                      .animate(delay: Duration(milliseconds: i * 150))
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.06, end: 0),
                ),
              ],
            ],
          ),
          if (others.isNotEmpty) ...[
            const SizedBox(height: 16),
            _GradeSection(
              label: 'أخرى',
              subtitle: 'بدون فئة',
              color: const Color(0xFF37474F),
              teams: others,
            ),
          ],
        ],
      ),
    );
  }
}

class _GradeSection extends StatelessWidget {
  final String label;
  final String subtitle;
  final Color color;
  final List<Team> teams;

  const _GradeSection({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.teams,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(19),
                topRight: Radius.circular(19),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.alexandria(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  subtitle,
                  style: GoogleFonts.alexandria(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white60,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const Spacer(),
                Text(
                  '${teams.length} فريق',
                  style: GoogleFonts.alexandria(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white54,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
          if (teams.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'لا توجد فرق',
                  style: GoogleFonts.alexandria(
                      fontSize: 13, color: Colors.white38),
                  textDirection: TextDirection.rtl,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: teams.asMap().entries.map((e) {
                  final rank = e.key + 1;
                  final team = e.value;
                  final isFirst = rank == 1;
                  final initials = team.name
                      .split(' ')
                      .take(2)
                      .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
                      .join();

                  return Padding(
                    padding: EdgeInsets.only(
                        bottom: e.key < teams.length - 1 ? 8 : 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isFirst
                            ? color.withOpacity(0.35)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: isFirst
                            ? Border.all(
                                color: color.withOpacity(0.7), width: 1.5)
                            : null,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 26,
                            child: Text(
                              '$rank',
                              style: GoogleFonts.alexandria(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color:
                                    isFirst ? Colors.white : Colors.white38,
                              ),
                            ),
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(team.color).withOpacity(0.25),
                              border: Border.all(
                                  color: Color(team.color), width: 2),
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: GoogleFonts.alexandria(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Color(team.color),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              team.name,
                              style: GoogleFonts.alexandria(
                                fontSize: 14,
                                fontWeight: isFirst
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isFirst)
                            const Icon(Icons.emoji_events_rounded,
                                size: 16, color: AppColors.orangeBg),
                          const SizedBox(width: 4),
                          Text(
                            '${team.score}',
                            style: GoogleFonts.alexandria(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: isFirst ? Colors.white : Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _StatChip({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.alexandria(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white54,
                letterSpacing: 1)),
        Text(value,
            style: GoogleFonts.alexandria(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: valueColor ?? Colors.white)),
      ],
    );
  }
}
