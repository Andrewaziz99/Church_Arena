import 'package:flutter/foundation.dart';

// ── Payload sent from main window → TV window ─────────────────────────────────

enum TvPayloadType { question, reveal, clear }

class TvPayload {
  final TvPayloadType type;
  final String text;
  final List<String> options;
  final String? correctAnswer;
  final int points;
  final int roundNumber;

  const TvPayload({
    required this.type,
    this.text = '',
    this.options = const [],
    this.correctAnswer,
    this.points = 0,
    this.roundNumber = 1,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'text': text,
        'options': options,
        'correct_answer': correctAnswer,
        'points': points,
        'round_number': roundNumber,
      };

  factory TvPayload.fromJson(Map<String, dynamic> j) => TvPayload(
        type: TvPayloadType.values.byName(j['type'] as String? ?? 'question'),
        text: j['text'] as String? ?? '',
        options: (j['options'] as List?)?.cast<String>() ?? [],
        correctAnswer: j['correct_answer'] as String?,
        points: j['points'] as int? ?? 0,
        roundNumber: j['round_number'] as int? ?? 1,
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
