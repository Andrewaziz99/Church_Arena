import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_nav_sidebar.dart';
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
