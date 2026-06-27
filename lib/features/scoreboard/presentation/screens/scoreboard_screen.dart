import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.finalScoreboard),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      body: BlocConsumer<ScoreboardBloc, ScoreboardState>(
        listener: (context, state) {
          if (state is ScoreboardLoaded && state.showConfetti) {
            _confettiController.play();
          }
        },
        builder: (context, state) {
          if (state is ScoreboardInitial) {
            return const Center(
              child: Text(
                'No scoreboard data.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          if (state is ScoreboardLoaded) {
            return Stack(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    particleDrag: 0.05,
                    emissionFrequency: 0.05,
                    numberOfParticles: 20,
                    gravity: 0.05,
                    colors: const [
                      AppColors.primary,
                      AppColors.accent,
                      AppColors.success,
                      AppColors.error,
                    ],
                  ),
                ),
                Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: state.rankedTeams.length,
                        itemBuilder: (context, index) => _RankCard(
                          team: state.rankedTeams[index],
                          rank: index + 1,
                        )
                            .animate(delay: Duration(milliseconds: index * 150))
                            .fadeIn(duration: 400.ms)
                            .slideX(begin: -0.2, end: 0),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => context.go('/'),
                            icon: const Icon(Icons.replay),
                            label: const Text(AppStrings.playAgain),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton.icon(
                            onPressed: () => context.go('/'),
                            icon: const Icon(Icons.home),
                            label: const Text(AppStrings.backToDashboard),
                          ),
                        ],
                      ),
                    ),
                  ],
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

class _RankCard extends StatelessWidget {
  final Team team;
  final int rank;

  const _RankCard({required this.team, required this.rank});

  @override
  Widget build(BuildContext context) {
    final teamColor = Color(team.color);
    final initials = team.name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    Color rankColor;
    IconData? rankIcon;
    switch (rank) {
      case 1:
        rankColor = AppColors.accent;
        rankIcon = null;
      case 2:
        rankColor = const Color(0xFFC0C0C0);
        rankIcon = null;
      case 3:
        rankColor = const Color(0xFFCD7F32);
        rankIcon = null;
      default:
        rankColor = AppColors.textSecondary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: rank == 1
                  ? const Text(
                      '👑',
                      style: TextStyle(fontSize: 32),
                      textAlign: TextAlign.center,
                    )
                  : Text(
                      '#$rank',
                      style: TextStyle(
                        color: rankColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
            ),
            const SizedBox(width: 16),
            CircleAvatar(
              radius: 28,
              backgroundColor: teamColor,
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                team.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${team.score}',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: AppColors.accent.withOpacity(0.6),
                    blurRadius: 8,
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
            const SizedBox(width: 8),
            Text(
              'pts',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
