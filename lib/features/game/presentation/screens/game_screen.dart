import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_nav_sidebar.dart';
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
                children: sorted.map<Widget>((t) {
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
    final currentQ = session.currentQuestionIndex < session.questions.length
        ? session.questions[session.currentQuestionIndex]
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: Stack(
        children: [
          Row(
            children: [
              // ── Left sidebar ──────────────────────────────────
              const AppNavSidebar(activeRoute: '/game'),

              // ── Center content ────────────────────────────────
              Expanded(
                child: Column(
                  children: [
                    _GameTopBar(session: session),
                    if (isSecondTeamWaiting) _SecondTeamBanner(session: session),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Question card
                            if (currentQ != null)
                              Expanded(
                                child: _QuestionCard(
                                  question: currentQ,
                                  buzzedTeamId: session.buzzedTeamId,
                                  teams: session.teams,
                                ),
                              ),

                            // Team buzz cards
                            if (session.teams.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 155,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: session.teams.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                                  itemBuilder: (context, i) {
                                    final team = session.teams[i];
                                    final isBuzzed = session.buzzedTeamId == team.id;
                                    final color = Color(team.color);
                                    final initials = team.name.split(' ').take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      width: 130,
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: isBuzzed ? AppColors.orangeBg : AppColors.border,
                                          width: isBuzzed ? 3 : 1.5,
                                        ),
                                        boxShadow: isBuzzed
                                            ? [BoxShadow(color: AppColors.orangeBg.withOpacity(0.5), blurRadius: 18, spreadRadius: 1)]
                                            : null,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          children: [
                                            if (isBuzzed)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: AppColors.orangeBg,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text('BUZZED FIRST!', style: GoogleFonts.alexandria(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.orangeDark)),
                                              )
                                            else
                                              const SizedBox(height: 17),
                                            const SizedBox(height: 6),
                                            Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: color.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(13),
                                                border: Border.all(color: color.withOpacity(0.45)),
                                              ),
                                              child: Center(
                                                child: Text(initials, style: GoogleFonts.alexandria(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(team.name, style: GoogleFonts.alexandria(fontSize: 12, fontWeight: FontWeight.w700, color: isBuzzed ? AppColors.orangeDark : AppColors.textPrimary), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                                            Text('${team.score}', style: GoogleFonts.alexandria(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.blueContent)),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Right panel ───────────────────────────────────
              _RightPanel(
                session: session,
                showCorrectWrong: showCorrectWrong,
                isPaused: isPaused,
                timerActive: timerActive,
                currentQ: currentQ,
              ),
            ],
          ),

          // Pause overlay
          if (isPaused)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Icon(Icons.pause_circle_filled, size: 120, color: AppColors.blueContent),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Question card ─────────────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  final Question question;
  final String? buzzedTeamId;
  final List<Team> teams;

  const _QuestionCard({required this.question, this.buzzedTeamId, required this.teams});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative blobs
            Positioned(top: -30, right: -30, child: Container(width: 140, height: 140, decoration: BoxDecoration(color: AppColors.orangeBg.withOpacity(0.25), shape: BoxShape.circle))),
            Positioned(bottom: -20, left: -20, child: Container(width: 100, height: 100, decoration: BoxDecoration(color: AppColors.greenLight.withOpacity(0.22), shape: BoxShape.circle))),
            // Bottom accent bar
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(height: 4, decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.greenSuccess, AppColors.orangeBg]))),
            ),
            // Content
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.greenSuccess, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome, size: 13, color: Colors.white),
                          const SizedBox(width: 6),
                          Text('CURRENT CHALLENGE', style: GoogleFonts.alexandria(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      question.text,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.alexandria(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.4),
                      textDirection: TextDirection.rtl,
                    ),
                    // ── Multiple choice options ────────────────────
                    if (question.options.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 4.2,
                        ),
                        itemCount: question.options.length.clamp(0, 4),
                        itemBuilder: (_, i) {
                          const letters = ['A', 'B', 'C', 'D'];
                          const colors = [Color(0xFF1565C0), Color(0xFF2E7D32), Color(0xFF6A1B9A), Color(0xFFE65100)];
                          final c = colors[i % colors.length];
                          return Container(
                            decoration: BoxDecoration(
                              color: c.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: c.withOpacity(0.45), width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  decoration: BoxDecoration(
                                    color: c.withOpacity(0.35),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(11),
                                      bottomLeft: Radius.circular(11),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(letters[i], style: GoogleFonts.alexandria(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Text(
                                      question.options[i],
                                      style: GoogleFonts.alexandria(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                      textAlign: TextAlign.center,
                                      textDirection: TextDirection.rtl,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Game top bar ──────────────────────────────────────────────────────────────

class _GameTopBar extends StatelessWidget {
  final GameSession session;
  const _GameTopBar({required this.session});

  @override
  Widget build(BuildContext context) {
    final qNumber = session.currentQuestionIndex + 1;
    final total = session.questions.length;
    final now = TimeOfDay.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Container(
      height: 56,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text('VIBRANT QUIZ FESTIVAL', style: GoogleFonts.alexandria(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: 0.5)),
          const SizedBox(width: 14),
          Container(width: 1, height: 22, color: AppColors.border),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
            child: Text('ROUND 2', style: GoogleFonts.alexandria(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 0.5)),
          ),
          const SizedBox(width: 10),
          Text('Question $qNumber/$total', style: GoogleFonts.alexandria(fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          const Icon(Icons.flash_on_rounded, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          const Icon(Icons.sync_rounded, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          const Icon(Icons.wifi_rounded, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: AppColors.orangeBg, borderRadius: BorderRadius.circular(24)),
            child: Text(timeStr, style: GoogleFonts.alexandria(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.orangeDark)),
          ),
        ],
      ),
    );
  }
}

// ── Right control panel ───────────────────────────────────────────────────────

class _RightPanel extends StatelessWidget {
  final GameSession session;
  final bool showCorrectWrong;
  final bool isPaused;
  final bool timerActive;
  final Question? currentQ;

  const _RightPanel({
    required this.session,
    required this.showCorrectWrong,
    required this.isPaused,
    required this.timerActive,
    this.currentQ,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 272,
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Timer card ────────────────────────────────────
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8EC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.orangeBg.withOpacity(0.4)),
            ),
            child: Column(
              children: [
                Text('TIME REMAINING', style: GoogleFonts.alexandria(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1)),
                const SizedBox(height: 14),
                SizedBox(
                  width: 110,
                  height: 110,
                  child: TimerWidget(
                    remaining: session.timerRemaining,
                    total: session.timerSeconds,
                  ),
                ),
              ],
            ),
          ),

          // ── Buttons ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                // ── Double points (R1 only) ───────────────────────
                if (session.roundType == RoundType.classic &&
                    session.buzzedTeamId == null &&
                    session.currentTeam != null &&
                    !session.doublesUsed.contains(session.currentTeam!.id) &&
                    !session.isDoubleActive) ...[
                  _PanelBtn(
                    label: AppStrings.doublePoints,
                    icon: Icons.close_fullscreen_rounded,
                    bgColor: AppColors.orangeBg,
                    fgColor: AppColors.orangeDark,
                    onTap: () => context.read<GameBloc>().add(const UseDouble()),
                  ),
                  const SizedBox(height: 8),
                ],
                if (session.isDoubleActive) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.orangeBg.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.orangeBg),
                    ),
                    child: Text(
                      AppStrings.doubleActivated,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.alexandria(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.orangeDark),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                _PanelBtn(
                  label: 'Show Answer',
                  icon: Icons.visibility_rounded,
                  bgColor: AppColors.orangeDark,
                  fgColor: Colors.white,
                  onTap: () => context.read<GameBloc>().add(const NextQuestion()),
                ),
                const SizedBox(height: 8),
                _PanelBtn(
                  label: 'Reset Buzzer',
                  icon: Icons.refresh_rounded,
                  bgColor: Colors.transparent,
                  fgColor: AppColors.textPrimary,
                  border: AppColors.border,
                  onTap: () => context.read<GameBloc>().add(const ResetBuzzer()),
                  ),
                if (showCorrectWrong) ...[
                  const SizedBox(height: 8),
                  _PanelBtn(
                    label: 'Correct ✓',
                    icon: Icons.check_circle_rounded,
                    bgColor: AppColors.greenSuccess,
                    fgColor: Colors.white,
                    onTap: () => context.read<GameBloc>().add(AnswerCorrect(currentQ?.points ?? 10)),
                  ),
                  const SizedBox(height: 8),
                  _PanelBtn(
                    label: 'Incorrect ✗',
                    icon: Icons.cancel_rounded,
                    bgColor: AppColors.redError,
                    fgColor: Colors.white,
                    onTap: () => context.read<GameBloc>().add(const AnswerWrong()),
                  ),
                ],
                const SizedBox(height: 16),
                _PanelBtn(
                  label: 'End Game',
                  icon: Icons.stop_circle_rounded,
                  bgColor: Colors.transparent,
                  fgColor: AppColors.redError,
                  border: AppColors.redError,
                  onTap: () => context.read<GameBloc>().add(const EndGame()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Panel button ──────────────────────────────────────────────────────────────

class _PanelBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color fgColor;
  final Color? border;
  final VoidCallback onTap;

  const _PanelBtn({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.fgColor,
    required this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: border != null ? Border.all(color: border!) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: fgColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.alexandria(fontSize: 13, fontWeight: FontWeight.w700, color: fgColor),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Second-team-waiting banner ────────────────────────────────────────────────

class _SecondTeamBanner extends StatelessWidget {
  final GameSession session;
  const _SecondTeamBanner({required this.session});

  @override
  Widget build(BuildContext context) {
    final second = session.teams.firstWhere(
      (t) => t.id != session.buzzedTeamId,
      orElse: () => session.teams.first,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: AppColors.blueContent.withValues(alpha: 0.1),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top_rounded, size: 16, color: AppColors.blueContent),
          const SizedBox(width: 8),
          Text(
            '${second.name} is waiting to answer',
            style: GoogleFonts.alexandria(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.blueContent),
          ),
        ],
      ),
    );
  }
}
