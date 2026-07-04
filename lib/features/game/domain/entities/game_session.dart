import 'package:equatable/equatable.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../questions/domain/entities/question.dart';

enum GameStatus { idle, active, paused, buzzed, ended }

/// Which of the three competition rounds is currently active.
enum RoundType { classic, penaltyShootout, underPressure }

class GameSession extends Equatable {
  // ── Core ──────────────────────────────────────────────────────────────────
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

  // ── Round metadata ────────────────────────────────────────────────────────
  final RoundType roundType;
  final int roundNumber;

  // ── Round 1: Classic ─────────────────────────────────────────────────────
  /// Number of questions directed at each team.
  final int questionsPerTeam;
  /// Which team's turn it currently is (index into [teams]).
  final int currentTeamIndex;
  /// How many questions each team has completed (parallel to [teams]).
  final List<int> teamQuestionsDone;
  /// Team IDs that have already activated their "double points" bonus.
  final List<String> doublesUsed;
  /// Whether the double-points bonus is active for the current question.
  final bool isDoubleActive;

  // ── Round 2: Penalty ─────────────────────────────────────────────────────
  /// Flat list of team IDs paired for R2: [pair0_a, pair0_b, pair1_a, pair1_b, …].
  final List<String> teamPairsList;
  /// Index of the current pair (0-based).
  final int currentPairIndex;
  /// How many questions each pair plays before moving to the next pair.
  final int r2QuestionsPerPair;

  // ── Round 3: Under Pressure ───────────────────────────────────────────────
  /// Number of contestants per team (parallel to [teams]).
  final List<int> contestantsPerTeam;
  /// Index of the current contestant within the current team.
  final int currentContestantIndex;
  /// The total shared timer duration for a team (seconds).
  final int sharedTimerSeconds;

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
    this.roundType = RoundType.classic,
    this.roundNumber = 1,
    this.questionsPerTeam = 5,
    this.currentTeamIndex = 0,
    this.teamQuestionsDone = const [],
    this.doublesUsed = const [],
    this.isDoubleActive = false,
    this.teamPairsList = const [],
    this.currentPairIndex = 0,
    this.r2QuestionsPerPair = 1,
    this.contestantsPerTeam = const [],
    this.currentContestantIndex = 0,
    this.sharedTimerSeconds = 45,
  });

  // ── Computed helpers ──────────────────────────────────────────────────────

  Team? get currentTeam =>
      (currentTeamIndex >= 0 && currentTeamIndex < teams.length)
          ? teams[currentTeamIndex]
          : null;

  /// R2: returns the (teamA, teamB) pair for [currentPairIndex], or null.
  (Team, Team)? get currentPair {
    final aIdx = currentPairIndex * 2;
    final bIdx = aIdx + 1;
    if (bIdx >= teamPairsList.length) return null;
    Team find(String id) =>
        teams.firstWhere((t) => t.id == id, orElse: () => teams.first);
    return (find(teamPairsList[aIdx]), find(teamPairsList[bIdx]));
  }

  int get totalPairs => teamPairsList.length ~/ 2;

  /// R3: question list offset for the start of [currentTeamIndex]'s questions.
  int get r3QuestionOffset {
    int offset = 0;
    for (int i = 0; i < currentTeamIndex; i++) {
      if (i < contestantsPerTeam.length) offset += contestantsPerTeam[i];
    }
    return offset;
  }

  int get r3CurrentQuestionIndex => r3QuestionOffset + currentContestantIndex;

  int get currentTeamContestants =>
      (currentTeamIndex < contestantsPerTeam.length)
          ? contestantsPerTeam[currentTeamIndex]
          : 0;

  // ── copyWith ──────────────────────────────────────────────────────────────

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
    RoundType? roundType,
    int? roundNumber,
    int? questionsPerTeam,
    int? currentTeamIndex,
    List<int>? teamQuestionsDone,
    List<String>? doublesUsed,
    bool? isDoubleActive,
    List<String>? teamPairsList,
    int? currentPairIndex,
    int? r2QuestionsPerPair,
    List<int>? contestantsPerTeam,
    int? currentContestantIndex,
    int? sharedTimerSeconds,
  }) {
    return GameSession(
      id: id ?? this.id,
      teams: teams ?? this.teams,
      questions: questions ?? this.questions,
      currentQuestionIndex:
          currentQuestionIndex ?? this.currentQuestionIndex,
      status: status ?? this.status,
      timerSeconds: timerSeconds ?? this.timerSeconds,
      timerRemaining: timerRemaining ?? this.timerRemaining,
      buzzedTeamId: buzzedTeamId == _sentinel
          ? this.buzzedTeamId
          : buzzedTeamId as String?,
      usedQuestionIds: usedQuestionIds ?? this.usedQuestionIds,
      firstWrongTeamId: firstWrongTeamId == _sentinel
          ? this.firstWrongTeamId
          : firstWrongTeamId as String?,
      roundType: roundType ?? this.roundType,
      roundNumber: roundNumber ?? this.roundNumber,
      questionsPerTeam: questionsPerTeam ?? this.questionsPerTeam,
      currentTeamIndex: currentTeamIndex ?? this.currentTeamIndex,
      teamQuestionsDone: teamQuestionsDone ?? this.teamQuestionsDone,
      doublesUsed: doublesUsed ?? this.doublesUsed,
      isDoubleActive: isDoubleActive ?? this.isDoubleActive,
      teamPairsList: teamPairsList ?? this.teamPairsList,
      currentPairIndex: currentPairIndex ?? this.currentPairIndex,
      r2QuestionsPerPair: r2QuestionsPerPair ?? this.r2QuestionsPerPair,
      contestantsPerTeam: contestantsPerTeam ?? this.contestantsPerTeam,
      currentContestantIndex:
          currentContestantIndex ?? this.currentContestantIndex,
      sharedTimerSeconds: sharedTimerSeconds ?? this.sharedTimerSeconds,
    );
  }

  @override
  List<Object?> get props => [
        id,
        teams,
        questions,
        currentQuestionIndex,
        status,
        timerSeconds,
        timerRemaining,
        buzzedTeamId,
        usedQuestionIds,
        firstWrongTeamId,
        roundType,
        roundNumber,
        questionsPerTeam,
        currentTeamIndex,
        teamQuestionsDone,
        doublesUsed,
        isDoubleActive,
        teamPairsList,
        currentPairIndex,
        r2QuestionsPerPair,
        contestantsPerTeam,
        currentContestantIndex,
        sharedTimerSeconds,
      ];
}

const _sentinel = Object();
