import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
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
  bool _scoreChanged = false;

  @override
  void didUpdateWidget(TeamCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.team.score != widget.team.score) {
      setState(() => _scoreChanged = true);
      Future.delayed(const Duration(milliseconds: 700), () {
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

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: teamColor.withOpacity(0.4), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar + status badge ──────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: teamColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: teamColor.withOpacity(0.45), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: GoogleFonts.alexandria(color: teamColor, fontWeight: FontWeight.w900, fontSize: 20),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    color: AppColors.surfaceLight,
                  ),
                  child: Text(
                    'IDLE',
                    style: GoogleFonts.alexandria(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Team name ──────────────────────────────────────
            Text(
              widget.team.name.toUpperCase(),
              style: GoogleFonts.alexandria(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // ── Members ────────────────────────────────────────
            if (widget.team.members.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                widget.team.members.take(3).join(' · '),
                style: GoogleFonts.alexandria(fontSize: 10, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.rtl,
              ),
            ],

            const SizedBox(height: 12),

            // ── Score ──────────────────────────────────────────
            Text(
              'SCORE',
              style: GoogleFonts.alexandria(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1),
            ),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: Text(
                key: ValueKey(widget.team.score),
                '${widget.team.score}',
                style: GoogleFonts.alexandria(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: _scoreChanged ? AppColors.greenSuccess : AppColors.blueContent,
                ),
              ),
            ),

            const Spacer(),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // ── Actions ────────────────────────────────────────
            Row(
              children: [
                _ActionBtn(
                  icon: Icons.edit_rounded,
                  bgColor: AppColors.orangeBg.withOpacity(0.5),
                  iconColor: AppColors.orangeDark,
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => TeamFormDialog(blocContext: context, team: widget.team),
                  ),
                ),
                const SizedBox(width: 8),
                _ActionBtn(
                  icon: Icons.delete_rounded,
                  bgColor: AppColors.redError.withOpacity(0.1),
                  iconColor: AppColors.redError,
                  onTap: () => _confirmDelete(context),
                ),
                const Spacer(),
                _ScoreBtns(team: widget.team),
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
        title: Text(AppStrings.confirm, style: GoogleFonts.alexandria(fontWeight: FontWeight.w700)),
        content: const Text(AppStrings.confirmDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.redError),
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

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.bgColor, required this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }
}

class _ScoreBtns extends StatelessWidget {
  final Team team;
  const _ScoreBtns({required this.team});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Btn(label: '-10', onTap: () => context.read<TeamsBloc>().add(UpdateScore(team.id, -10)), color: AppColors.redError),
        const SizedBox(width: 6),
        _Btn(label: '+10', onTap: () => context.read<TeamsBloc>().add(UpdateScore(team.id, 10)), color: AppColors.greenSuccess),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _Btn({required this.label, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(
          label,
          style: GoogleFonts.alexandria(color: color, fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
