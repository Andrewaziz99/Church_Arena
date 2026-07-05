import 'package:flutter/foundation.dart';

// ── Payload sent from main window → TV window ─────────────────────────────────

enum TvPayloadType { question, reveal, buzzed, clear }

class TvPayload {
  final TvPayloadType type;
  final String text;
  final List<String> options;
  final String? correctAnswer;
  final int points;
  final int roundNumber;

  /// Seconds left on the main countdown (question / answer timer). Null hides
  /// the on-screen timer.
  final int? timerRemaining;
  /// Total length of that countdown, used to draw the progress ring.
  final int? timerTotal;

  /// Set only for [TvPayloadType.buzzed]: the team that hit the buzzer.
  final String? buzzedTeamName;
  final int? buzzedTeamColor;
  /// 3 → 2 → 1 countdown shown during the buzzed takeover.
  final int? buzzCountdown;

  const TvPayload({
    required this.type,
    this.text = '',
    this.options = const [],
    this.correctAnswer,
    this.points = 0,
    this.roundNumber = 1,
    this.timerRemaining,
    this.timerTotal,
    this.buzzedTeamName,
    this.buzzedTeamColor,
    this.buzzCountdown,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'text': text,
        'options': options,
        'correct_answer': correctAnswer,
        'points': points,
        'round_number': roundNumber,
        'timer_remaining': timerRemaining,
        'timer_total': timerTotal,
        'buzzed_team_name': buzzedTeamName,
        'buzzed_team_color': buzzedTeamColor,
        'buzz_countdown': buzzCountdown,
      };

  factory TvPayload.fromJson(Map<String, dynamic> j) => TvPayload(
        type: TvPayloadType.values.byName(j['type'] as String? ?? 'question'),
        text: j['text'] as String? ?? '',
        options: (j['options'] as List?)?.cast<String>() ?? [],
        correctAnswer: j['correct_answer'] as String?,
        points: j['points'] as int? ?? 0,
        roundNumber: j['round_number'] as int? ?? 1,
        timerRemaining: j['timer_remaining'] as int?,
        timerTotal: j['timer_total'] as int?,
        buzzedTeamName: j['buzzed_team_name'] as String?,
        buzzedTeamColor: j['buzzed_team_color'] as int?,
        buzzCountdown: j['buzz_countdown'] as int?,
      );
}

// ── Controller (lives in the TV sub-window) ───────────────────────────────────

/// Bridges IPC method calls to the TvScreen UI.
/// `TvApp` calls [update] / [clear] when messages arrive from the main window.
class TvController extends ChangeNotifier {
  static final instance = TvController._();
  TvController._();

  TvPayload? _payload;
  TvPayload? get payload => _payload;

  void update(TvPayload p) {
    _payload = p;
    notifyListeners();
  }

  void clear() {
    _payload = null;
    notifyListeners();
  }
}
