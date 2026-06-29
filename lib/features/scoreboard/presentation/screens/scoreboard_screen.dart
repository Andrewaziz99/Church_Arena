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
                            : Column(
                                children: [
                                  // Winner (rank 1)
                                  if (teams.isNotEmpty)
                                    _WinnerCard(team: teams[0])
                                        .animate().fadeIn(duration: 500.ms).slideY(begin: 0.08, end: 0),

                                  const SizedBox(height: 16),

                                  // Rank 2 & 3
                                  if (teams.length > 1)
                                    Expanded(
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(
                                            child: _PodiumCard(team: teams[1], rank: 2)
                                                .animate(delay: 200.ms).fadeIn(duration: 400.ms),
                                          ),
                                          if (teams.length > 2) ...[
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: _PodiumCard(team: teams[2], rank: 3)
                                                  .animate(delay: 350.ms).fadeIn(duration: 400.ms),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),

                                  // Rank 4+
                                  if (teams.length > 3) ...[
                                    const SizedBox(height: 16),
                                    Row(
                                      children: teams.skip(3).toList().asMap().entries.map((e) {
                                        return Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.only(left: e.key > 0 ? 12 : 0),
                                            child: _SmallRankCard(team: e.value, rank: e.key + 4)
                                                .animate(delay: Duration(milliseconds: 500 + e.key * 80))
                                                .fadeIn(duration: 300.ms),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
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
