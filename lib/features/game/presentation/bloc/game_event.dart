part of 'game_bloc.dart';

abstract class GameEvent extends Equatable {
  const GameEvent();
}

class StartGame extends GameEvent {
  final List<Team> teams;
  final List<Question> questions;
  final int timerSeconds;
  const StartGame(this.teams, this.questions, this.timerSeconds);
  @override
  List<Object> get props => [teams, questions, timerSeconds];
}

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

class StopTimer extends GameEvent {
  const StopTimer();
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
