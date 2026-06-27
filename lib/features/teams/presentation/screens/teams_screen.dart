import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/team.dart';
import '../bloc/teams_bloc.dart';
import '../widgets/team_card_widget.dart';
import '../widgets/team_form_dialog.dart';

class TeamsScreen extends StatelessWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.teamsManager),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => TeamFormDialog(blocContext: context),
        ),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.background,
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<TeamsBloc, TeamsState>(
        listener: (context, state) {
          if (state is TeamsError) {
            context.showSnackBar(state.message, isError: true);
          }
        },
        builder: (context, state) {
          if (state is TeamsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TeamsLoaded) {
            if (state.teams.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.group_off,
                      size: 80,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      AppStrings.noTeamsYet,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => TeamFormDialog(blocContext: context),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text(AppStrings.addTeam),
                    ),
                  ],
                ),
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.8,
              ),
              itemCount: state.teams.length,
              itemBuilder: (context, index) => TeamCardWidget(
                team: state.teams[index],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
