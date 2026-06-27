import 'package:equatable/equatable.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../questions/domain/entities/question.dart';

enum GameStatus { idle, active, paused, buzzed, ended }

class GameSession extends Equatable {
  final String id;
  final List<Team> teams;
  final List<Question> questions;
  final int currentQuestionIndex;
  final GameStatus status;
  final int timerSeconds;
  final int timerRemaining;
  final String? buzzedTeamId;
  final List<String> usedQuestionIds;

  const GameSession({
    required this.id,
    required this.teams,
    required this.questions,
    required this.currentQuestionIndex,
    required this.status,
    required this.timerSeconds,
    required this.timerRemaining,
    this.buzzedTeamId,
    this.usedQuestionIds = const [],
  });

  GameSession copyWith({
    String? id,
    List<Team>? teams,
    List<Question>? questions,
    int? currentQuestionIndex,
    GameStatus? status,
    int? timerSeconds,
    int? timerRemaining,
    Object? buzzedTeamId = _sentinel,
    List<String>? usedQuestionIds,
  }) {
    return GameSession(
      id: id ?? this.id,
      teams: teams ?? this.teams,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      status: status ?? this.status,
      timerSeconds: timerSeconds ?? this.timerSeconds,
      timerRemaining: timerRemaining ?? this.timerRemaining,
      buzzedTeamId: buzzedTeamId == _sentinel ? this.buzzedTeamId : buzzedTeamId as String?,
      usedQuestionIds: usedQuestionIds ?? this.usedQuestionIds,
    );
  }

  @override
  List<Object?> get props => [id, teams, questions, currentQuestionIndex,
        status, timerSeconds, timerRemaining, buzzedTeamId, usedQuestionIds];
}

const _sentinel = Object();
