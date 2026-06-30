import 'dart:async';

/// Broadcast bus that notifies BLoCs when a remote Supabase change has been
/// merged into local SQLite.  Emits the table name so subscribers can decide
/// whether to reload.
///
/// Recognised table tokens: 'teams' | 'questions'
/// ('questions' covers both the questions and categories tables.)
class RemoteSyncBus {
  static final RemoteSyncBus instance = RemoteSyncBus._();
  RemoteSyncBus._();

  final StreamController<String> _controller =
      StreamController<String>.broadcast();

  Stream<String> get stream => _controller.stream;

  void notify(String table) {
    if (!_controller.isClosed) _controller.add(table);
  }

  void dispose() => _controller.close();
}
