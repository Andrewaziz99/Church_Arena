import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../questions/domain/entities/question.dart';
import '../../../scoreboard/presentation/bloc/scoreboard_bloc.dart';
import '../../../teams/domain/entities/team.dart';
import '../../domain/entities/game_session.dart';
import '../bloc/game_bloc.dart';
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
        final s = bloc.state;
        if (s is GameIdle || s is GameEnded) {
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
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
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
          if (state is GameIdle) return _IdleScreen();
          if (state is GameLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (state is GameWaitingBuzz) {
            return _GameLayout(
              session: state.session,
              timerActive: false,
              showCorrectWrong: false,
            );
          }
          if (state is GameBuzzedDisplay) {
            return _BuzzedDisplayScreen(
              session: state.session,
              secondsLeft: state.secondsLeft,
            );
          }
          if (state is GameInProgress) {
            return _GameLayout(
              session: state.session,
              timerActive: true,
              showCorrectWrong: state.session.buzzedTeamId != null,
            );
          }
          if (state is GameWaitingSecondTeam) {
            return _GameLayout(
              session: state.session,
              timerActive: false,
              showCorrectWrong: false,
              isSecondTeamWaiting: true,
            );
          }
          if (state is GamePaused) {
            return _GameLayout(
              session: state.session,
              timerActive: false,
              showCorrectWrong: false,
              isPaused: true,
            );
          }
          return _IdleScreen();
        },
      ),
    );
  }
}

// ── Idle ──────────────────────────────────────────────────────────────────────

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

// ── 3-second buzz display ─────────────────────────────────────────────────────

class _BuzzedDisplayScreen extends StatelessWidget {
  final GameSession session;
  final int secondsLeft;

  const _BuzzedDisplayScreen({
    required this.session,
    required this.secondsLeft,
  });

  @override
  Widget build(BuildContext context) {
    final buzzedTeam = session.buzzedTeamId != null
        ? session.teams.firstWhere(
            (t) => t.id == session.buzzedTeamId,
            orElse: () => session.teams.first,
          )
        : null;

    final teamColor = buzzedTeam != null ? Color(buzzedTeam.color) : AppColors.primary;
    final teamName = buzzedTeam?.name ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Coloured background glow
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.85,
                  colors: [
                    teamColor.withValues(alpha: 0.55),
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),
          // Team scores bar at bottom
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: TeamScoresBar(
              teams: session.teams,
              buzzedTeamId: session.buzzedTeamId,
            ),
          ),
          // Team name + countdown centred
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  teamName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: teamColor,
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: teamColor.withValues(alpha: 0.8),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 1200.ms, color: Colors.white38),
                const SizedBox(height: 40),
                // Countdown circle
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: teamColor, width: 4),
                    color: teamColor.withValues(alpha: 0.15),
                  ),
                  child: Center(
                    child: Text(
                      '$secondsLeft',
                      style: TextStyle(
                        color: teamColor,
                        fontSize: 54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ).animate(key: ValueKey(secondsLeft)).scale(
                      begin: const Offset(1.3, 1.3),
                      end: const Offset(1.0, 1.0),
                      duration: 300.ms,
                      curve: Curves.easeOut,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Main game layout ──────────────────────────────────────────────────────────

class _GameLayout extends StatelessWidget {
  final GameSession session;
  final bool timerActive;
  final bool showCorrectWrong;
  final bool isPaused;
  final bool isSecondTeamWaiting;

  const _GameLayout({
    required this.session,
    required this.timerActive,
    required this.showCorrectWrong,
    this.isPaused = false,
    this.isSecondTeamWaiting = false,
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
          // Artboard background
          Positioned.fill(
            child: Image.asset('assets/images/Artboard.png', fit: BoxFit.cover),
          ),
          Container(color: Colors.black.withValues(alpha: 0.55)),

          Positioned.fill(
            child: Column(
              children: [
                _TopBar(
                  session: session,
                  timerActive: timerActive,
                ),
                // Second-team banner
                if (isSecondTeamWaiting)
                  _SecondTeamBanner(session: session),
                // Buzzed team indicator (during answering)
                if (showCorrectWrong && session.buzzedTeamId != null)
                  _BuzzedTeamBadge(
                    teams: session.teams,
                    buzzedTeamId: session.buzzedTeamId!,
                  ),
                if (currentQ != null)
                  Expanded(
                    child: QuestionDisplayWidget(question: currentQ),
                  ),
                _ControlBar(
                  session: session,
                  showCorrectWrong: showCorrectWrong,
                  isPaused: isPaused,
                  timerActive: timerActive,
                ),
                TeamScoresBar(
                  teams: session.teams,
                  buzzedTeamId: session.buzzedTeamId,
                ),
              ],
            ),
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

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final GameSession session;
  final bool timerActive;

  const _TopBar({required this.session, required this.timerActive});

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
              label: Text(currentQ.categoryId, style: const TextStyle(fontSize: 12)),
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
          if (timerActive)
            TimerWidget(
              remaining: session.timerRemaining,
              total: session.timerSeconds,
            )
          else
            const SizedBox(width: 60),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── Buzzed team badge ─────────────────────────────────────────────────────────

class _BuzzedTeamBadge extends StatelessWidget {
  final List<Team> teams;
  final String buzzedTeamId;

  const _BuzzedTeamBadge({required this.teams, required this.buzzedTeamId});

  @override
  Widget build(BuildContext context) {
    final team = teams.firstWhere(
      (t) => t.id == buzzedTeamId,
      orElse: () => teams.first,
    );
    final color = Color(team.color);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: color.withValues(alpha: 0.2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.record_voice_over, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            team.name,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            AppStrings.buzzed,
            style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ── Second-team banner ────────────────────────────────────────────────────────

class _SecondTeamBanner extends StatelessWidget {
  final GameSession session;

  const _SecondTeamBanner({required this.session});

  @override
  Widget build(BuildContext context) {
    final firstWrongTeam = session.firstWrongTeamId != null
        ? session.teams.firstWhere(
            (t) => t.id == session.firstWrongTeamId,
            orElse: () => session.teams.first,
          )
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.error.withValues(alpha: 0.15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          if (firstWrongTeam != null)
            Text(
              '${firstWrongTeam.name} أجاب خطأ — فرصة للفريق الآخر!',
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textDirection: TextDirection.rtl,
            ),
        ],
      ),
    );
  }
}

// ── Difficulty badge ──────────────────────────────────────────────────────────

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

// ── Control bar ───────────────────────────────────────────────────────────────

class _ControlBar extends StatelessWidget {
  final GameSession session;
  final bool showCorrectWrong;
  final bool isPaused;
  final bool timerActive;

  const _ControlBar({
    required this.session,
    required this.showCorrectWrong,
    required this.isPaused,
    required this.timerActive,
  });

  @override
  Widget build(BuildContext context) {
    final currentQ = session.currentQuestionIndex < session.questions.length
        ? session.questions[session.currentQuestionIndex]
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          if (showCorrectWrong) ...[
            ElevatedButton.icon(
              onPressed: () => context
                  .read<GameBloc>()
                  .add(AnswerCorrect(currentQ?.points ?? 10)),
              icon: const Icon(Icons.check),
              label: const Text(AppStrings.correct),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            ),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<GameBloc>().add(const AnswerWrong()),
              icon: const Icon(Icons.close),
              label: const Text(AppStrings.wrong),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            ),
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
          if (timerActive)
            ElevatedButton.icon(
              onPressed: () => context.read<GameBloc>().add(
                    isPaused ? const ResumeTimer() : const PauseTimer(),
                  ),
              icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
              label: Text(isPaused ? AppStrings.resumeGame : AppStrings.pauseGame),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceLight),
            ),
          // Reset buzzer — always visible
          ElevatedButton.icon(
            onPressed: () =>
                context.read<GameBloc>().add(const ResetBuzzer()),
            icon: const Icon(Icons.refresh),
            label: const Text(AppStrings.resetBuzzer),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent.withValues(alpha: 0.85),
              foregroundColor: Colors.black,
            ),
          ),
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
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
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
