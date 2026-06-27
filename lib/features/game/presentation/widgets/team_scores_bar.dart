import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../teams/domain/entities/team.dart';

class TeamScoresBar extends StatelessWidget {
  final List<Team> teams;
  final String? buzzedTeamId;

  const TeamScoresBar({
    super.key,
    required this.teams,
    this.buzzedTeamId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: AppColors.surface,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: teams.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final team = teams[index];
          final isBuzzed = team.id == buzzedTeamId;
          final teamColor = Color(team.color);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isBuzzed
                  ? teamColor.withOpacity(0.3)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isBuzzed ? teamColor : AppColors.border,
                width: isBuzzed ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: teamColor,
                    shape: BoxShape.circle,
                    boxShadow: isBuzzed
                        ? [BoxShadow(color: teamColor, blurRadius: 6)]
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  team.name,
                  style: TextStyle(
                    color: isBuzzed ? teamColor : AppColors.textPrimary,
                    fontWeight:
                        isBuzzed ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${team.score}',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    shadows: [
                      Shadow(
                          color: AppColors.accent.withOpacity(0.6),
                          blurRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
