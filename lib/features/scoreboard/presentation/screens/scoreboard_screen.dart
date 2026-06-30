import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../teams/domain/entities/team.dart';
import '../bloc/scoreboard_bloc.dart';

class ScoreboardScreen extends StatefulWidget {
  const ScoreboardScreen({super.key});

  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 6));
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
          if (state is ScoreboardLoaded && state.showConfetti) _confetti.play();
        },
        builder: (context, state) {
          if (state is ScoreboardInitial) {
            return Stack(
              children: [
                Center(
                  child: Text('No scoreboard data.', style: GoogleFonts.alexandria(color: Colors.white54, fontSize: 18)),
                ),
                Positioned(
                  top: 20, left: 20,
                  child: GestureDetector(
                    onTap: () => context.canPop() ? context.pop() : context.go('/'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          Text('BACK', style: GoogleFonts.alexandria(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 1)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          if (state is ScoreboardLoaded) {
            final teams = state.rankedTeams;
            return Stack(
              children: [
                // ── Background ─────────────────────────────────
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

                // ── Confetti ────────────────────────────────────
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confetti,
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

                // ── Back button ─────────────────────────────────
                Positioned(
                  top: 20,
                  left: 20,
                  child: GestureDetector(
                    onTap: () => context.canPop() ? context.pop() : context.go('/'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          Text('BACK', style: GoogleFonts.alexandria(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 1)),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Content ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
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
                                'VIBRANT QUIZ FESTIVAL',
                                style: GoogleFonts.alexandria(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white54,
                                  letterSpacing: 3,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Stats chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.12)),
                            ),
                            child: Row(
                              children: [
                                _StatChip(label: 'TEAMS', value: '${teams.length}'),
                                const SizedBox(width: 28),
                                _StatChip(label: 'STATUS', value: 'ACTIVE', valueColor: AppColors.greenLight),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton.icon(
                            onPressed: () => context.go('/'),
                            icon: const Icon(Icons.home_rounded, color: Colors.white70, size: 18),
                            label: Text(
                              AppStrings.backToDashboard,
                              style: GoogleFonts.alexandria(color: Colors.white70, fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white24),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // ── Scoreboard body ─────────────────────────
                      Expanded(
                        child: teams.isEmpty
                            ? Center(child: Text('No results yet', style: GoogleFonts.alexandria(color: Colors.white54)))
                            : _SectionedScoreboard(teams: teams),
                      ),

                      // Bottom buttons
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => context.go('/'),
                              icon: const Icon(Icons.replay_rounded),
                              label: Text(AppStrings.playAgain, style: GoogleFonts.alexandria(fontWeight: FontWeight.w700)),
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
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ── Sectioned scoreboard ──────────────────────────────────────────────────────

/// Divides teams into 3 grade sections. Teams without a section go into
/// an "Other" bucket so they're never hidden.
class _SectionedScoreboard extends StatelessWidget {
  final List<Team> teams;
  const _SectionedScoreboard({required this.teams});

  static const _sections = [
    ('اولى وثانية',  const Color(0xFF1565C0), '١ & ٢'),
    ('ثالثة ورابعة', const Color(0xFF6A1B9A), '٣ & ٤'),
    ('خامسة وسادسة', const Color(0xFF1B5E20), '٥ & ٦'),
  ];

  @override
  Widget build(BuildContext context) {
    // Group by section
    final Map<String, List<Team>> grouped = {};
    for (final (sectionKey, _, __) in _sections) {
      grouped[sectionKey] = [];
    }
    final others = <Team>[];
    for (final team in teams) {
      if (grouped.containsKey(team.section)) {
        grouped[team.section]!.add(team);
      } else {
        others.add(team);
      }
    }
    // Sort each group by score descending
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
                  ).animate(delay: Duration(milliseconds: i * 150))
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
          // Section header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

          // Team rows
          if (teams.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'لا توجد فرق',
                  style: GoogleFonts.alexandria(fontSize: 13, color: Colors.white38),
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
                    padding: EdgeInsets.only(bottom: e.key < teams.length - 1 ? 8 : 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isFirst
                            ? color.withOpacity(0.35)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: isFirst
                            ? Border.all(color: color.withOpacity(0.7), width: 1.5)
                            : null,
                      ),
                      child: Row(
                        children: [
                          // Rank
                          SizedBox(
                            width: 26,
                            child: Text(
                              '$rank',
                              style: GoogleFonts.alexandria(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: isFirst ? Colors.white : Colors.white38,
                              ),
                            ),
                          ),
                          // Avatar
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(team.color).withOpacity(0.25),
                              border: Border.all(color: Color(team.color), width: 2),
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
                          // Name
                          Expanded(
                            child: Text(
                              team.name,
                              style: GoogleFonts.alexandria(
                                fontSize: 14,
                                fontWeight: isFirst ? FontWeight.w800 : FontWeight.w600,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Score
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
        Text(label, style: GoogleFonts.alexandria(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white54, letterSpacing: 1)),
        Text(value, style: GoogleFonts.alexandria(fontSize: 24, fontWeight: FontWeight.w900, color: valueColor ?? Colors.white)),
      ],
    );
  }
}

// ── Winner card ───────────────────────────────────────────────────────────────

class _WinnerCard extends StatelessWidget {
  final Team team;
  const _WinnerCard({required this.team});

  @override
  Widget build(BuildContext context) {
    final initials = team.name.split(' ').take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
    final color = Color(team.color);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.greenLight, width: 2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withOpacity(0.09), Colors.white.withOpacity(0.03)],
        ),
        boxShadow: [BoxShadow(color: AppColors.greenLight.withOpacity(0.22), blurRadius: 36, spreadRadius: 2)],
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.2),
                  border: Border.all(color: AppColors.orangeBg, width: 3),
                ),
                child: Center(
                  child: Text(initials, style: GoogleFonts.alexandria(color: color, fontWeight: FontWeight.w900, fontSize: 28)),
                ),
              ),
              Positioned(
                top: -8, right: -8,
                child: Container(
                  width: 28, height: 28,
                  decoration: const BoxDecoration(color: AppColors.orangeBg, shape: BoxShape.circle),
                  child: const Icon(Icons.emoji_events_rounded, size: 16, color: AppColors.orangeDark),
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.greenSuccess, borderRadius: BorderRadius.circular(20)),
                      child: Text('THE WINNER', style: GoogleFonts.alexandria(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1, fontStyle: FontStyle.italic)),
                    ),
                    const SizedBox(width: 14),
                    Text('RANK 01', style: GoogleFonts.alexandria(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white54, letterSpacing: 1)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  team.name,
                  style: GoogleFonts.alexandria(fontSize: 44, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0),
                ),
              ],
            ),
          ),

          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('TOTAL SCORE', style: GoogleFonts.alexandria(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.orangeBg, letterSpacing: 1)),
              Text(
                '${team.score}',
                style: GoogleFonts.alexandria(fontSize: 68, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Podium card (rank 2 & 3) ──────────────────────────────────────────────────

class _PodiumCard extends StatelessWidget {
  final Team team;
  final int rank;
  const _PodiumCard({required this.team, required this.rank});

  @override
  Widget build(BuildContext context) {
    final initials = team.name.split(' ').take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
    final bgColor = rank == 2 ? AppColors.orangeDark : AppColors.blueContent;
    final scoreColor = rank == 2 ? AppColors.orangeBg : AppColors.greenLight;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(
            '0$rank',
            style: GoogleFonts.alexandria(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white.withOpacity(0.25)),
          ),
          const SizedBox(width: 16),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black26,
              border: Border.all(color: Colors.white38, width: 2),
            ),
            child: Center(
              child: Text(initials, style: GoogleFonts.alexandria(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(team.name, style: GoogleFonts.alexandria(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          Text(
            '${team.score}',
            style: GoogleFonts.alexandria(fontSize: 32, fontWeight: FontWeight.w900, color: scoreColor),
          ),
        ],
      ),
    );
  }
}

// ── Small rank card (rank 4+) ─────────────────────────────────────────────────

class _SmallRankCard extends StatelessWidget {
  final Team team;
  final int rank;
  const _SmallRankCard({required this.team, required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Text(
            '0$rank',
            style: GoogleFonts.alexandria(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white30),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(team.name, style: GoogleFonts.alexandria(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          Text(
            '${team.score}',
            style: GoogleFonts.alexandria(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white60),
          ),
        ],
      ),
    );
  }
}
