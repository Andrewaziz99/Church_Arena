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
  /// Set when the first team answers wrong — waiting for a second team to try.
  final String? firstWrongTeamId;

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
    this.firstWrongTeamId,
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
    Object? firstWrongTeamId = _sentinel,
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
      firstWrongTeamId: firstWrongTeamId == _sentinel
          ? this.firstWrongTeamId
          : firstWrongTeamId as String?,
    );
  }

  @override
  List<Object?> get props => [
        id, teams, questions, currentQuestionIndex,
        status, timerSeconds, timerRemaining,
        buzzedTeamId, usedQuestionIds, firstWrongTeamId,
      ];
}

const _sentinel = Object();
