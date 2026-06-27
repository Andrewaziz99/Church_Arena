import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../questions/domain/entities/question.dart';
import '../../../scoreboard/presentation/bloc/scoreboard_bloc.dart';
import '../bloc/game_bloc.dart';
import '../widgets/buzzer_animation_widget.dart';
import '../widgets/question_display_widget.dart';
import '../widgets/team_scores_bar.dart';
import '../widgets/timer_widget.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final bloc = context.read<GameBloc>();
        final currentState = bloc.state;
        if (currentState is GameIdle || currentState is GameEnded) {
          if (context.mounted) context.pop();
          return;
        }
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(AppStrings.endGame),
            content: const Text(AppStrings.confirmEndGame),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(AppStrings.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(AppStrings.confirm),
              ),
            ],
          ),
        );
        if (confirmed == true && context.mounted) {
          context.read<GameBloc>().add(const EndGame());
        }
      },
      child: BlocConsumer<GameBloc, GameState>(
        listener: (context, state) {
          if (state is GameError) {
            context.showSnackBar(state.message, isError: true);
          }
          if (state is GameEnded) {
            context.read<ScoreboardBloc>().add(LoadScoreboard(state.teams));
            context.go('/scoreboard');
          }
        },
        builder: (context, state) {
          if (state is GameIdle) {
            return _IdleScreen();
          }
          if (state is GameLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (state is GameInProgress) {
            return _GameLayout(session: state.session, isBuzzed: false);
          }
          if (state is GameBuzzed) {
            return _GameLayout(session: state.session, isBuzzed: true);
          }
          if (state is GamePaused) {
            return _GameLayout(
              session: state.session,
              isBuzzed: false,
              isPaused: true,
            );
          }
          return _IdleScreen();
        },
      ),
    );
  }
}

class _IdleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.game),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_esports, size: 80, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text(
              AppStrings.noGameRunning,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 20),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.home),
              label: const Text(AppStrings.backToDashboard),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameLayout extends StatelessWidget {
  final dynamic session;
  final bool isBuzzed;
  final bool isPaused;

  const _GameLayout({
    required this.session,
    required this.isBuzzed,
    this.isPaused = false,
  });

  @override
  Widget build(BuildContext context) {
    final currentQ = session.currentQuestionIndex < session.questions.length
        ? session.questions[session.currentQuestionIndex]
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Artboard behind question area ──────────────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/images/Artboard.png',
              fit: BoxFit.cover,
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.55)),

          // Positioned.fill gives the Column tight bounds so Expanded works
          Positioned.fill(
            child: Column(
              children: [
                _TopBar(session: session),
                if (currentQ != null)
                  Expanded(
                    child: QuestionDisplayWidget(question: currentQ),
                  ),
                _ControlBar(
                  session: session,
                  isBuzzed: isBuzzed,
                  isPaused: isPaused,
                ),
                TeamScoresBar(
                  teams: session.teams,
                  buzzedTeamId: session.buzzedTeamId,
                ),
              ],
            ),
          ),
          if (isBuzzed && session.buzzedTeamId != null)
            BuzzerAnimationWidget(
              teamId: session.buzzedTeamId!,
              teams: session.teams,
            ),
          if (isPaused)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black45,
                  child: const Center(
                    child: Icon(
                      Icons.pause_circle_filled,
                      size: 120,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final dynamic session;
  const _TopBar({required this.session});

  @override
  Widget build(BuildContext context) {
    final currentQ = session.currentQuestionIndex < session.questions.length
        ? session.questions[session.currentQuestionIndex]
        : null;
    final qNumber = session.currentQuestionIndex + 1;
    final total = session.questions.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.home, color: AppColors.textSecondary),
            onPressed: () => context.go('/'),
          ),
          const SizedBox(width: 8),
          if (currentQ != null) ...[
            Chip(
              label: Text(
                currentQ.categoryId,
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: AppColors.surfaceLight,
            ),
            const SizedBox(width: 8),
            _DiffBadge(difficulty: currentQ.difficulty),
          ],
          const Spacer(),
          Text(
            'Q $qNumber / $total',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(width: 16),
          TimerWidget(
            remaining: session.timerRemaining,
            total: session.timerSeconds,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _DiffBadge extends StatelessWidget {
  final DifficultyLevel difficulty;
  const _DiffBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    switch (difficulty) {
      case DifficultyLevel.easy:
        color = AppColors.success;
        label = 'Easy';
      case DifficultyLevel.hard:
        color = AppColors.error;
        label = 'Hard';
      case DifficultyLevel.medium:
        color = AppColors.accent;
        label = 'Medium';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ControlBar extends StatelessWidget {
  final dynamic session;
  final bool isBuzzed;
  final bool isPaused;

  const _ControlBar({
    required this.session,
    required this.isBuzzed,
    required this.isPaused,
  });

  @override
  Widget build(BuildContext context) {
    final currentQ = session.currentQuestionIndex < session.questions.length
        ? session.questions[session.currentQuestionIndex]
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isBuzzed) ...[
            ElevatedButton.icon(
              onPressed: () => context.read<GameBloc>().add(
                    AnswerCorrect(currentQ?.points ?? 10),
                  ),
              icon: const Icon(Icons.check),
              label: const Text(AppStrings.correct),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<GameBloc>().add(const AnswerWrong()),
              icon: const Icon(Icons.close),
              label: const Text(AppStrings.wrong),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            ),
            const SizedBox(width: 12),
          ],
          ElevatedButton.icon(
            onPressed: () =>
                context.read<GameBloc>().add(const NextQuestion()),
            icon: const Icon(Icons.skip_next),
            label: const Text(AppStrings.nextQuestion),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
            ),
          ),
          const SizedBox(width: 12),
          if (!isBuzzed)
            ElevatedButton.icon(
              onPressed: () => context.read<GameBloc>().add(
                    isPaused ? const ResumeTimer() : const PauseTimer(),
                  ),
              icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
              label: Text(isPaused ? AppStrings.resumeGame : AppStrings.pauseGame),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceLight,
              ),
            ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _confirmEnd(context),
            icon: const Icon(Icons.stop),
            label: const Text(AppStrings.endGame),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          ),
        ],
      ),
    );
  }

  void _confirmEnd(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.endGame),
        content: const Text(AppStrings.confirmEndGame),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              context.read<GameBloc>().add(const EndGame());
              Navigator.pop(ctx);
            },
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
    );
  }
}
