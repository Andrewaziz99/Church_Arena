import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_nav_sidebar.dart';
import '../../../scoreboard/data/result_local_datasource.dart';
import '../bloc/teams_bloc.dart';
import '../widgets/team_card_widget.dart';
import '../widgets/team_form_dialog.dart';

class TeamsScreen extends StatelessWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.orangeBg,
      body: Row(
        children: [
          const AppNavSidebar(activeRoute: '/teams'),
          Expanded(
            child: BlocConsumer<TeamsBloc, TeamsState>(
              listener: (context, state) {
                if (state is TeamsError) {
                  context.showSnackBar(state.message, isError: true);
                }
              },
              builder: (context, state) {
                final teams = state is TeamsLoaded ? state.teams : [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TEAMS HUB',
                                style: GoogleFonts.alexandria(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(width: 28, height: 2.5, color: AppColors.textPrimary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Live Stage',
                                    style: GoogleFonts.alexandria(fontSize: 13, color: AppColors.textPrimary.withOpacity(0.7)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Spacer(),
                          _ClearAllPointsButton(teamsLoaded: state is TeamsLoaded),
                          const SizedBox(width: 12),
                          const _SyncLastGameButton(),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: AppColors.border, width: 1.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 9, height: 9,
                                  decoration: const BoxDecoration(color: AppColors.greenSuccess, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${teams.length} TEAMS ACTIVE',
                                  style: GoogleFonts.alexandria(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Team cards ────────────────────────────────
                    Expanded(
                      child: state is TeamsLoading
                          ? const Center(child: CircularProgressIndicator())
                          : (state is TeamsLoaded && state.teams.isEmpty)
                              ? _EmptyState(
                                  onAdd: () => showDialog(
                                    context: context,
                                    builder: (_) => TeamFormDialog(blocContext: context),
                                  ),
                                )
                              : GridView.builder(
                                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 0.72,
                                  ),
                                  itemCount: state is TeamsLoaded ? state.teams.length : 0,
                                  itemBuilder: (context, index) {
                                    final team = (state as TeamsLoaded).teams[index];
                                    return TeamCardWidget(team: team);
                                  },
                                ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => TeamFormDialog(blocContext: context),
        ),
        backgroundColor: AppColors.orangeDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'JOIN THE PARTY',
          style: GoogleFonts.alexandria(fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}

// ── Clear all points ───────────────────────────────────────────────────────────

class _ClearAllPointsButton extends StatelessWidget {
  final bool teamsLoaded;
  const _ClearAllPointsButton({required this.teamsLoaded});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: teamsLoaded ? () => _confirm(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.redError.withOpacity(0.5), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.restart_alt_rounded, size: 16, color: AppColors.redError),
            const SizedBox(width: 8),
            Text(
              'مسح النقاط',
              style: GoogleFonts.alexandria(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.redError,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('مسح جميع النقاط؟', style: GoogleFonts.alexandria(fontWeight: FontWeight.w700)),
        content: Text('سيتم إعادة تعيين نقاط جميع الفرق إلى صفر.', style: GoogleFonts.alexandria()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.alexandria()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.redError, foregroundColor: Colors.white),
            onPressed: () {
              context.read<TeamsBloc>().add(const ResetAllScores());
              Navigator.pop(ctx);
            },
            child: Text('مسح', style: GoogleFonts.alexandria(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Sync scores from last game ─────────────────────────────────────────────────

class _SyncLastGameButton extends StatefulWidget {
  const _SyncLastGameButton();

  @override
  State<_SyncLastGameButton> createState() => _SyncLastGameButtonState();
}

class _SyncLastGameButtonState extends State<_SyncLastGameButton> {
  bool _loading = false;

  Future<void> _sync() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      // Load the most recent competition result
      final results = await ResultLocalDataSource.instance.getAll();
      if (!mounted) return;
      if (results.isEmpty) {
        context.showSnackBar('لا توجد مباريات مسجلة', isError: true);
        return;
      }

      final lastGame = results.first;
      final teamsState = context.read<TeamsBloc>().state;
      if (teamsState is! TeamsLoaded) {
        context.showSnackBar('لم تُحمَّل الفرق بعد', isError: true);
        return;
      }

      // Build a score map from the last game: teamId → score
      final scoreMap = {for (final s in lastGame.teams) s.id: s.score};

      int updated = 0;
      for (final team in teamsState.teams) {
        final lastScore = scoreMap[team.id];
        if (lastScore != null && lastScore != team.score) {
          // Use SaveTeam with only the score changed — works with optimistic updates
          context.read<TeamsBloc>().add(
                SaveTeam(team.copyWith(score: lastScore)),
              );
          updated++;
        }
      }

      if (mounted) {
        if (updated == 0) {
          context.showSnackBar('النتائج مطابقة للعبة الأخيرة بالفعل');
        } else {
          final date = lastGame.completedAt;
          context.showSnackBar(
            '✅  تم تحديث $updated فريق من مباراة ${date.day}/${date.month}/${date.year}',
          );
        }
      }
    } catch (e) {
      if (mounted) context.showSnackBar('خطأ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _sync,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.blueContent.withOpacity(0.5), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blueContent),
              )
            else
              const Icon(Icons.history_rounded, size: 16, color: AppColors.blueContent),
            const SizedBox(width: 8),
            Text(
              _loading ? 'جارٍ التحديث…' : 'نتائج آخر مباراة',
              style: GoogleFonts.alexandria(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.blueContent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.groups_rounded, size: 80, color: Colors.white54),
          const SizedBox(height: 16),
          Text('لا توجد فرق بعد', style: GoogleFonts.alexandria(color: Colors.white70, fontSize: 18)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('إضافة فريق'),
          ),
        ],
      ),
    );
  }
}
