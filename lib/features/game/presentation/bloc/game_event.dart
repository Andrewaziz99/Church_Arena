part of 'game_bloc.dart';

abstract class GameEvent extends Equatable {
  const GameEvent();
}

// ── Single-round (legacy) ─────────────────────────────────────────────────────

class StartGame extends GameEvent {
  final List<Team> teams;
  final List<Question> questions;
  final int timerSeconds;
  const StartGame(this.teams, this.questions, this.timerSeconds);
  @override
  List<Object> get props => [teams, questions, timerSeconds];
}

// ── 3-round competition ───────────────────────────────────────────────────────

/// Starts a full 3-round competition. R2 and R3 data are held by the bloc
/// until each round transition.
class StartCompetition extends GameEvent {
  final List<Team> teams;

  // Round 1
  final List<Question> round1Questions;
  final int round1Timer;
  final int questionsPerTeam;

  // Round 2
  final List<Question> round2Questions;
  final int round2Timer;

  // Round 3
  final List<Question> round3Questions;
  final int sharedTimer;
  /// Parallel to [teams]: how many contestants each team sends in R3.
  final List<int> contestantsPerTeam;

  const StartCompetition({
    required this.teams,
    required this.round1Questions,
    required this.round1Timer,
    required this.questionsPerTeam,
    required this.round2Questions,
    required this.round2Timer,
    required this.round3Questions,
    required this.sharedTimer,
    required this.contestantsPerTeam,
  });

  @override
  List<Object> get props => [
        teams,
        round1Questions,
        round1Timer,
        questionsPerTeam,
        round2Questions,
        round2Timer,
        round3Questions,
        sharedTimer,
        contestantsPerTeam,
      ];
}

/// R1: activate double-points for the current team's current question.
class UseDouble extends GameEvent {
  const UseDouble();
  @override
  List<Object> get props => [];
}

/// R1 / R3: controller dismisses the team-turn intro screen → show question.
class ConfirmTeamTurn extends GameEvent {
  const ConfirmTeamTurn();
  @override
  List<Object> get props => [];
}

/// R2: controller dismisses the pair display screen → show question.
class ConfirmPairDisplay extends GameEvent {
  const ConfirmPairDisplay();
  @override
  List<Object> get props => [];
}

/// Advances from the current round transition screen to the next round.
class AdvanceRound extends GameEvent {
  const AdvanceRound();
  @override
  List<Object> get props => [];
}

// ── Shared game controls ──────────────────────────────────────────────────────

class NextQuestion extends GameEvent {
  const NextQuestion();
  @override
  List<Object> get props => [];
}

class BuzzerPressed extends GameEvent {
  final String teamId;
  const BuzzerPressed(this.teamId);
  @override
  List<Object> get props => [teamId];
}

/// Internal: tick for the 3-second buzz-display countdown.
class BuzzCountdownTick extends GameEvent {
  const BuzzCountdownTick();
  @override
  List<Object> get props => [];
}

/// Sends a reset signal to the Arduino and unlocks the buzzer.
class ResetBuzzer extends GameEvent {
  const ResetBuzzer();
  @override
  List<Object> get props => [];
}

class AnswerCorrect extends GameEvent {
  final int points;
  const AnswerCorrect(this.points);
  @override
  List<Object> get props => [points];
}

class AnswerWrong extends GameEvent {
  const AnswerWrong();
  @override
  List<Object> get props => [];
}

class PauseTimer extends GameEvent {
  const PauseTimer();
  @override
  List<Object> get props => [];
}

class ResumeTimer extends GameEvent {
  const ResumeTimer();
  @override
  List<Object> get props => [];
}

class TimerTick extends GameEvent {
  const TimerTick();
  @override
  List<Object> get props => [];
}

class EndGame extends GameEvent {
  const EndGame();
  @override
  List<Object> get props => [];
}

/// Controller pressed "Show Answer" in the both-wrong screen.
class RevealAnswer extends GameEvent {
  const RevealAnswer();
  @override
  List<Object> get props => [];
}

/// Controller pressed "Next Question" without revealing, in the both-wrong screen.
class SkipAfterBothWrong extends GameEvent {
  const SkipAfterBothWrong();
  @override
  List<Object> get props => [];
}

/// Fired by a Timer (or the Skip button) to advance after the answer reveal.
class AnswerRevealTick extends GameEvent {
  const AnswerRevealTick();
  @override
  List<Object> get props => [];
}
