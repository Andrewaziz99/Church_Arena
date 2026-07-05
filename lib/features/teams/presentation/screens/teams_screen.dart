import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_nav_sidebar.dart';
import '../../../scoreboard/data/result_local_datasource.dart';
import '../../domain/entities/team.dart';
import '../bloc/teams_bloc.dart';
import '../widgets/team_card_widget.dart';
import '../widgets/team_form_dialog.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  /// null = show teams from every age category.
  String? _selectedSection;

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
                final allTeams =
                    state is TeamsLoaded ? state.teams : <Team>[];
                final teams = _selectedSection == null
                    ? allTeams
                    : allTeams
                        .where((t) => t.section == _selectedSection)
                        .toList();

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

                    const SizedBox(height: 16),

                    // ── Age-category filter ──────────────────────
                    if (allTeams.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _SectionFilterBar(
                          selected: _selectedSection,
                          allCount: allTeams.length,
                          counts: {
                            for (final s in AppStrings.sections)
                              s: allTeams.where((t) => t.section == s).length,
                          },
                          onSelect: (s) => setState(() => _selectedSection = s),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // ── Team cards ────────────────────────────────
                    Expanded(
                      child: state is TeamsLoading
                          ? const Center(child: CircularProgressIndicator())
                          : (state is TeamsLoaded && allTeams.isEmpty)
                              ? _EmptyState(
                                  onAdd: () => showDialog(
                                    context: context,
                                    builder: (_) => TeamFormDialog(blocContext: context),
                                  ),
                                )
                              : teams.isEmpty
                                  ? const _EmptyFilterState()
                                  : GridView.builder(
                                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 4,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                        childAspectRatio: 0.72,
                                      ),
                                      itemCount: teams.length,
                                      itemBuilder: (context, index) {
                                        final team = teams[index];
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

// ── Age-category filter bar ──────────────────────────────────────────────────

class _SectionFilterBar extends StatelessWidget {
  final String? selected;
  final int allCount;
  final Map<String, int> counts;
  final ValueChanged<String?> onSelect;

  const _SectionFilterBar({
    required this.selected,
    required this.allCount,
    required this.counts,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: AppStrings.allSections,
            count: allCount,
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
          for (final s in AppStrings.sections) ...[
            const SizedBox(width: 10),
            _FilterChip(
              label: s,
              count: counts[s] ?? 0,
              selected: selected == s,
              onTap: () => onSelect(s),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.orangeDark : AppColors.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? AppColors.orangeDark : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.alexandria(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: GoogleFonts.alexandria(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected
                    ? Colors.white.withOpacity(0.8)
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state (no filter match) ────────────────────────────────────────────

class _EmptyFilterState extends StatelessWidget {
  const _EmptyFilterState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.filter_alt_off_rounded, size: 64, color: Colors.white54),
          const SizedBox(height: 16),
          Text(
            'لا توجد فرق في هذه الفئة',
            style: GoogleFonts.alexandria(color: Colors.white70, fontSize: 16),
          ),
        ],
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
