import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../teams/domain/entities/team.dart';
import '../bloc/game_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BuzzerAnimationWidget extends StatelessWidget {
  final String teamId;
  final List<Team> teams;

  const BuzzerAnimationWidget({
    super.key,
    required this.teamId,
    required this.teams,
  });

  @override
  Widget build(BuildContext context) {
    final team = teams.where((t) => t.id == teamId).firstOrNull;
    if (team == null) return const SizedBox.shrink();

    final teamColor = Color(team.color);
    final initials = team.name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Positioned.fill(
      child: Container(
        color: teamColor.withOpacity(0.85),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  duration: 500.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 24),
            Text(
              team.name,
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.3, end: 0),
            const SizedBox(height: 8),
            Text(
              AppStrings.buzzed,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w300,
                color: Colors.white.withOpacity(0.8),
                letterSpacing: 6,
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<GameBloc>().add(const ResetBuzzer()),
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.resetBuzzer),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: teamColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 300.ms),
          ],
        ),
      ),
    );
  }
}
