import 'dart:async';
import 'package:intl/intl.dart';

enum LogLevel { info, success, warning, error }

class ConnectionLogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;

  const ConnectionLogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
  });

  String get timeLabel => DateFormat('HH:mm:ss').format(timestamp);
}

/// In-memory ring-buffer of Supabase connection events.
/// Max 100 entries; newest first.
class ConnectionLogService {
  static final ConnectionLogService instance = ConnectionLogService._();
  ConnectionLogService._();

  static const int _maxEntries = 100;

  final List<ConnectionLogEntry> _entries = [];
  final StreamController<List<ConnectionLogEntry>> _controller =
      StreamController<List<ConnectionLogEntry>>.broadcast();

  List<ConnectionLogEntry> get entries => List.unmodifiable(_entries);
  Stream<List<ConnectionLogEntry>> get stream => _controller.stream;

  void log(String message, {LogLevel level = LogLevel.info}) {
    _entries.insert(
      0,
      ConnectionLogEntry(
          timestamp: DateTime.now(), level: level, message: message),
    );
    if (_entries.length > _maxEntries) _entries.removeLast();
    _controller.add(List.unmodifiable(_entries));
  }

  void clear() {
    _entries.clear();
    _controller.add(const []);
  }
}
