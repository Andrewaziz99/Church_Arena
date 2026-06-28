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
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error),
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
                body: Center(child: CircularProgressIndicator()));
          }

          // ── 3-round special screens ──────────────────────────────────────
          if (state is GameTeamTurn) {
            return _TeamTurnScreen(session: state.session);
          }
          if (state is GamePairDisplay) {
            return _PairDisplayScreen(session: state.session);
          }
          if (state is GameRoundTransition) {
            return _RoundTransitionScreen(
              teams: state.teams,
              completedRound: state.completedRound,
            );
          }
          if (state is GamePressureQuestion) {
            return _PressureQuestionScreen(session: state.session);
          }

          // ── Standard game layout ─────────────────────────────────────────
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
            const Icon(Icons.sports_esports,
                size: 80, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text(AppStrings.noGameRunning,
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 20)),
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

    final teamColor =
        buzzedTeam != null ? Color(buzzedTeam.color) : AppColors.primary;
    final teamName = buzzedTeam?.name ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
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
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: TeamScoresBar(
              teams: session.teams,
              buzzedTeamId: session.buzzedTeamId,
            ),
          ),
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
                          blurRadius: 30),
                    ],
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 1200.ms, color: Colors.white38),
                const SizedBox(height: 40),
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

// ── Team turn intro (R1 & R3) ─────────────────────────────────────────────────

class _TeamTurnScreen extends StatelessWidget {
  final GameSession session;
  const _TeamTurnScreen({required this.session});

  @override
  Widget build(BuildContext context) {
    final team = session.currentTeam;
    final teamColor =
        team != null ? Color(team.color) : AppColors.primary;
    final teamName = team?.name ?? '';

    // Round label
    final String roundLabel;
    if (session.roundType == RoundType.underPressure) {
      roundLabel = AppStrings.round3Name;
    } else {
      roundLabel = AppStrings.round1Name;
    }

    // For R1, show question progress
    String subtitle = '';
    if (session.roundType == RoundType.classic &&
        session.currentTeamIndex < session.teamQuestionsDone.length) {
      final done = session.teamQuestionsDone[session.currentTeamIndex];
      subtitle =
          'سؤال ${done + 1} / ${session.questionsPerTeam}';
    }
    if (session.roundType == RoundType.underPressure) {
      final contestants =
          session.currentTeamIndex < session.contestantsPerTeam.length
              ? session.contestantsPerTeam[session.currentTeamIndex]
              : 0;
      subtitle = '$contestants ${AppStrings.contestant}';
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background glow
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: [
                    teamColor.withValues(alpha: 0.45),
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),
          // Scores bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: TeamScoresBar(teams: session.teams),
          ),
          // Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Round badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 6),
                  decoration: BoxDecoration(
                    color: teamColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: teamColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    roundLabel,
                    style: TextStyle(
                        color: teamColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppStrings.teamTurnTitle,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 20),
                ),
                const SizedBox(height: 12),
                Text(
                  teamName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: teamColor,
                    fontSize: 80,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                          color: teamColor.withValues(alpha: 0.8),
                          blurRadius: 40),
                    ],
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 1400.ms, color: Colors.white24),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    subtitle,
                    style: TextStyle(
                        color: teamColor.withValues(alpha: 0.8),
                        fontSize: 22),
                    textDirection: TextDirection.rtl,
                  ),
                ],
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () => context
                      .read<GameBloc>()
                      .add(const ConfirmTeamTurn()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: teamColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 16),
                    textStyle: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    shadowColor: teamColor.withValues(alpha: 0.6),
                    elevation: 12,
                  ),
                  child: const Text(AppStrings.startTurn),
                ),
              ],
            ),
          ),
          // End game button top-right
          Positioned(
            top: 12,
            right: 12,
            child: TextButton.icon(
              onPressed: () => _confirmEnd(context),
              icon: const Icon(Icons.stop, color: AppColors.error),
              label: const Text(AppStrings.endGame,
                  style: TextStyle(color: AppColors.error)),
            ),
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
              child: const Text(AppStrings.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
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

// ── Pair display (R2) ─────────────────────────────────────────────────────────

class _PairDisplayScreen extends StatelessWidget {
  final GameSession session;
  const _PairDisplayScreen({required this.session});

  @override
  Widget build(BuildContext context) {
    final pair = session.currentPair;
    final teamA = pair?.$1;
    final teamB = pair?.$2;
    final colorA =
        teamA != null ? Color(teamA.color) : AppColors.primary;
    final colorB =
        teamB != null ? Color(teamB.color) : AppColors.accent;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Split gradient
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          colorA.withValues(alpha: 0.5),
                          Colors.black
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black,
                          colorB.withValues(alpha: 0.5)
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Scores bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: TeamScoresBar(teams: session.teams),
          ),
          // Pair info
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Round badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.white24),
                  ),
                  child: const Text(
                    AppStrings.round2Name,
                    style: TextStyle(
                        color: Colors.white70, fontSize: 15),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                const SizedBox(height: 40),
                // VS layout
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _TeamNameBlock(
                        name: teamA?.name ?? '?', color: colorA),
                    const SizedBox(width: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white12,
                        border: Border.all(
                            color: Colors.white38, width: 2),
                      ),
                      child: const Text(
                        AppStrings.vsLabel,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    _TeamNameBlock(
                        name: teamB?.name ?? '?', color: colorB),
                  ],
                ),
                const SizedBox(height: 52),
                ElevatedButton(
                  onPressed: () => context
                      .read<GameBloc>()
                      .add(const ConfirmPairDisplay()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 16),
                    textStyle: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(AppStrings.startTurn),
                ),
              ],
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: TextButton.icon(
              onPressed: () => _confirmEnd(context),
              icon: const Icon(Icons.stop, color: AppColors.error),
              label: const Text(AppStrings.endGame,
                  style: TextStyle(color: AppColors.error)),
            ),
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
              child: const Text(AppStrings.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
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

class _TeamNameBlock extends StatelessWidget {
  final String name;
  final Color color;
  const _TeamNameBlock({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.25),
            border: Border.all(color: color, width: 3),
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                  color: color,
                  fontSize: 28,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            shadows: [
              Shadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 20),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Round transition ──────────────────────────────────────────────────────────

class _RoundTransitionScreen extends StatelessWidget {
  final List<Team> teams;
  final int completedRound;
  const _RoundTransitionScreen(
      {required this.teams, required this.completedRound});

  @override
  Widget build(BuildContext context) {
    final isLast = completedRound == 3;
    final sorted = [...teams]..sort((a, b) => b.score.compareTo(a.score));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events,
                size: 72, color: AppColors.accent),
            const SizedBox(height: 16),
            Text(
              '${AppStrings.roundComplete} $completedRound! 🎉',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 32),
            // Scores
            Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: sorted.map((t) {
                  final color = Color(t.color);
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: color,
                          child: Text(
                            t.name.isNotEmpty
                                ? t.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(t.name,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18)),
                        ),
                        Text(
                          '${t.score}',
                          style: TextStyle(
                            color: color,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => context
                  .read<GameBloc>()
                  .add(const AdvanceRound()),
              icon: Icon(isLast
                  ? Icons.emoji_events
                  : Icons.arrow_forward),
              label: Text(isLast
                  ? AppStrings.finalResults
                  : AppStrings.nextRound),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isLast ? AppColors.accent : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 36, vertical: 14),
                textStyle: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Under Pressure question screen (R3) ──────────────────────────────────────

class _PressureQuestionScreen extends StatelessWidget {
  final GameSession session;
  const _PressureQuestionScreen({required this.session});

  @override
  Widget build(BuildContext context) {
    final currentTeam = session.currentTeam;
    final teamColor =
        currentTeam != null ? Color(currentTeam.color) : AppColors.primary;

    final contestantNum = session.currentContestantIndex + 1;
    final totalContestants = session.currentTeamContestants;

    final qIdx = session.r3CurrentQuestionIndex;
    final currentQ = (qIdx >= 0 && qIdx < session.questions.length)
        ? session.questions[qIdx]
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Artboard background
          Positioned.fill(
            child: Image.asset('assets/images/Artboard.png',
                fit: BoxFit.cover),
          ),
          Container(color: Colors.black.withValues(alpha: 0.55)),

          Positioned.fill(
            child: Column(
              children: [
                // Top bar
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  color: AppColors.surface,
                  child: Row(
                    children: [
                      // Team badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: teamColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: teamColor),
                        ),
                        child: Text(
                          currentTeam?.name ?? '',
                          style: TextStyle(
                              color: teamColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Contestant counter
                      Text(
                        '${AppStrings.contestant} $contestantNum / $totalContestants',
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14),
                        textDirection: TextDirection.rtl,
                      ),
                      const Spacer(),
                      // Shared timer (prominent)
                      TimerWidget(
                        remaining: session.timerRemaining,
                        total: session.sharedTimerSeconds,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                // R3 label
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  color: teamColor.withValues(alpha: 0.1),
                  child: const Text(
                    AppStrings.round3Name,
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                  ),
                ),
                // Question
                if (currentQ != null)
                  Expanded(
                    child: QuestionDisplayWidget(question: currentQ),
                  ),
                // Control bar: always show Correct / Wrong / Skip
                _PressureControlBar(
                  session: session,
                  currentQ: currentQ,
                ),
                TeamScoresBar(teams: session.teams),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PressureControlBar extends StatelessWidget {
  final GameSession session;
  final Question? currentQ;

  const _PressureControlBar({required this.session, this.currentQ});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          ElevatedButton.icon(
            onPressed: () => context
                .read<GameBloc>()
                .add(AnswerCorrect(currentQ?.points ?? 10)),
            icon: const Icon(Icons.check),
            label: const Text(AppStrings.correct),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success),
          ),
          ElevatedButton.icon(
            onPressed: () =>
                context.read<GameBloc>().add(const AnswerWrong()),
            icon: const Icon(Icons.close),
            label: const Text(AppStrings.wrong),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
          ),
          ElevatedButton.icon(
            onPressed: () =>
                context.read<GameBloc>().add(const NextQuestion()),
            icon: const Icon(Icons.skip_next),
            label: const Text(AppStrings.skipQuestion),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => context
                .read<GameBloc>()
                .add(const PauseTimer()),
            icon: const Icon(Icons.pause),
            label: const Text(AppStrings.pauseGame),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceLight),
          ),
          ElevatedButton.icon(
            onPressed: () => _confirmEnd(context),
            icon: const Icon(Icons.stop),
            label: const Text(AppStrings.endGame),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
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
              child: const Text(AppStrings.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
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
    final currentQ =
        session.currentQuestionIndex < session.questions.length
            ? session.questions[session.currentQuestionIndex]
            : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/Artboard.png',
                fit: BoxFit.cover),
          ),
          Container(color: Colors.black.withValues(alpha: 0.55)),

          Positioned.fill(
            child: Column(
              children: [
                _TopBar(session: session, timerActive: timerActive),
                if (isSecondTeamWaiting)
                  _SecondTeamBanner(session: session),
                if (showCorrectWrong && session.buzzedTeamId != null)
                  _BuzzedTeamBadge(
                    teams: session.teams,
                    buzzedTeamId: session.buzzedTeamId!,
                  ),
                if (currentQ != null)
                  Expanded(
                      child: QuestionDisplayWidget(question: currentQ)),
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
                    child: Icon(Icons.pause_circle_filled,
                        size: 120, color: AppColors.primary),
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
    final currentQ =
        session.currentQuestionIndex < session.questions.length
            ? session.questions[session.currentQuestionIndex]
            : null;
    final qNumber = session.currentQuestionIndex + 1;
    final total = session.questions.length;

    // R1: show which team's turn it is
    final currentTeam = (session.roundType == RoundType.classic)
        ? session.currentTeam
        : null;

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.home,
                color: AppColors.textSecondary),
            onPressed: () => context.go('/'),
          ),
          const SizedBox(width: 8),
          if (currentQ != null) ...[
            Chip(
              label: Text(currentQ.categoryId,
                  style: const TextStyle(fontSize: 12)),
              backgroundColor: AppColors.surfaceLight,
            ),
            const SizedBox(width: 8),
            _DiffBadge(difficulty: currentQ.difficulty),
          ],
          if (currentTeam != null) ...[
            const SizedBox(width: 8),
            _TeamChip(team: currentTeam),
          ],
          // R1 double badge
          if (session.isDoubleActive) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber),
              ),
              child: const Text(
                AppStrings.doubleActivated,
                style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
                textDirection: TextDirection.rtl,
              ),
            ),
          ],
          const Spacer(),
          Text(
            'Q $qNumber / $total',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 14),
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

class _TeamChip extends StatelessWidget {
  final Team team;
  const _TeamChip({required this.team});

  @override
  Widget build(BuildContext context) {
    final color = Color(team.color);
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
              radius: 7,
              backgroundColor: color,
              child: Text(
                team.name.isNotEmpty
                    ? team.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    fontSize: 8, color: Colors.white),
              )),
          const SizedBox(width: 6),
          Text(team.name,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ── Buzzed team badge ─────────────────────────────────────────────────────────

class _BuzzedTeamBadge extends StatelessWidget {
  final List<Team> teams;
  final String buzzedTeamId;

  const _BuzzedTeamBadge(
      {required this.teams, required this.buzzedTeamId});

  @override
  Widget build(BuildContext context) {
    final team = teams.firstWhere(
      (t) => t.id == buzzedTeamId,
      orElse: () => teams.first,
    );
    final color = Color(team.color);
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
            style: TextStyle(
                color: color.withValues(alpha: 0.8), fontSize: 14),
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
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.error.withValues(alpha: 0.15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber,
              color: AppColors.error, size: 18),
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
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold),
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
    final currentQ =
        session.currentQuestionIndex < session.questions.length
            ? session.questions[session.currentQuestionIndex]
            : null;

    // R1: can this team activate double?
    final currentTeam = session.currentTeam;
    final canDouble = session.roundType == RoundType.classic &&
        !showCorrectWrong &&
        currentTeam != null &&
        !session.doublesUsed.contains(currentTeam.id) &&
        !session.isDoubleActive;

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success),
            ),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<GameBloc>().add(const AnswerWrong()),
              icon: const Icon(Icons.close),
              label: const Text(AppStrings.wrong),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error),
            ),
          ],
          // Double-points button (R1 only)
          if (canDouble)
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<GameBloc>().add(const UseDouble()),
              icon: const Icon(Icons.close,
                  color: Colors.black), // × icon
              label: const Text(AppStrings.doublePoints,
                  style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                side: const BorderSide(color: Colors.orange),
              ),
            ),
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
                    isPaused
                        ? const ResumeTimer()
                        : const PauseTimer(),
                  ),
              icon: Icon(
                  isPaused ? Icons.play_arrow : Icons.pause),
              label: Text(isPaused
                  ? AppStrings.resumeGame
                  : AppStrings.pauseGame),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceLight),
            ),
          if (isPaused)
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<GameBloc>().add(const ResumeTimer()),
              icon: const Icon(Icons.play_arrow),
              label: const Text(AppStrings.resumeGame),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceLight),
            ),
          // Reset buzzer
          ElevatedButton.icon(
            onPressed: () =>
                context.read<GameBloc>().add(const ResetBuzzer()),
            icon: const Icon(Icons.refresh),
            label: const Text(AppStrings.resetBuzzer),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  AppColors.accent.withValues(alpha: 0.85),
              foregroundColor: Colors.black,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _confirmEnd(context),
            icon: const Icon(Icons.stop),
            label: const Text(AppStrings.endGame),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
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
              child: const Text(AppStrings.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
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
