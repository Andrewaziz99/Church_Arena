import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/team.dart';
import '../bloc/teams_bloc.dart';
import 'team_form_dialog.dart';

class TeamCardWidget extends StatefulWidget {
  final Team team;

  const TeamCardWidget({super.key, required this.team});

  @override
  State<TeamCardWidget> createState() => _TeamCardWidgetState();
}

class _TeamCardWidgetState extends State<TeamCardWidget> {
  int? _lastScore;
  bool _scoreChanged = false;

  @override
  void didUpdateWidget(TeamCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.team.score != widget.team.score) {
      setState(() {
        _lastScore = oldWidget.team.score;
        _scoreChanged = true;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _scoreChanged = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamColor = Color(widget.team.color);
    final initials = widget.team.name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: teamColor,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.team.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit,
                          size: 18, color: AppColors.primary),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => TeamFormDialog(
                          blocContext: context,
                          team: widget.team,
                        ),
                      ),
                      tooltip: AppStrings.editTeam,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete,
                          size: 18, color: AppColors.error),
                      onPressed: () => _confirmDelete(context),
                      tooltip: AppStrings.deleteTeam,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _scoreChanged
                      ? Text(
                          '${widget.team.score}',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: AppColors.accent.withOpacity(0.8),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        )
                          .animate()
                          .scale(
                            begin: const Offset(1.3, 1.3),
                            end: const Offset(1, 1),
                            duration: 300.ms,
                            curve: Curves.easeOut,
                          )
                          .then()
                          .shimmer(
                              duration: 300.ms,
                              color: AppColors.accent.withOpacity(0.6))
                      : Text(
                          '${widget.team.score}',
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
                        ),
                ),
                _ScoreButtons(team: widget.team),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.confirm),
        content: const Text(AppStrings.confirmDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              context.read<TeamsBloc>().add(DeleteTeam(widget.team.id));
              Navigator.pop(ctx);
            },
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}

class _ScoreButtons extends StatelessWidget {
  final Team team;
  const _ScoreButtons({required this.team});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: [
        _ScoreBtn(
          label: '-10',
          onTap: () =>
              context.read<TeamsBloc>().add(UpdateScore(team.id, -10)),
          color: AppColors.error,
        ),
        _ScoreBtn(
          label: '-1',
          onTap: () =>
              context.read<TeamsBloc>().add(UpdateScore(team.id, -1)),
          color: AppColors.error.withOpacity(0.7),
        ),
        _ScoreBtn(
          label: '+1',
          onTap: () =>
              context.read<TeamsBloc>().add(UpdateScore(team.id, 1)),
          color: AppColors.success.withOpacity(0.7),
        ),
        _ScoreBtn(
          label: '+10',
          onTap: () =>
              context.read<TeamsBloc>().add(UpdateScore(team.id, 10)),
          color: AppColors.success,
        ),
        _ScoreBtn(
          icon: Icons.refresh,
          onTap: () => context.read<TeamsBloc>().add(ResetScore(team.id)),
          color: AppColors.textSecondary,
        ),
      ],
    );
  }
}

class _ScoreBtn extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color color;

  const _ScoreBtn({
    this.label,
    this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: icon != null
            ? Icon(icon, size: 14, color: color)
            : Text(
                label!,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
