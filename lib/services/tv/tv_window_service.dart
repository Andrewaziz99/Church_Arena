import 'dart:convert';
import 'dart:ui';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:screen_retriever/screen_retriever.dart';

import '../../features/tv/tv_controller.dart';

/// Manages the TV presenter window lifecycle and IPC messaging.
///
/// Usage:
///   await TvWindowService.instance.open();       // open on secondary screen
///   TvWindowService.instance.showQuestion(p);    // send question
///   TvWindowService.instance.revealAnswer(p);    // reveal correct answer
///   TvWindowService.instance.clearScreen();      // clear / reset
///   await TvWindowService.instance.close();      // close window
class TvWindowService {
  static final instance = TvWindowService._();
  TvWindowService._();

  int? _windowId;

  /// `true` while the TV window is open.
  final isOpen = ValueNotifier<bool>(false);

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> open() async {
    if (_windowId != null) {
      // Already open — bring to front.
      await WindowController.fromWindowId(_windowId!).show();
      return;
    }

    final controller = await DesktopMultiWindow.createWindow(
      jsonEncode({'window': 'tv'}),
    );
    _windowId = controller.windowId;

    // Position on the secondary monitor (TV).  Falls back to primary if
    // there is only one monitor connected.
    try {
      final displays = await screenRetriever.getAllDisplays();
      final primary = await screenRetriever.getPrimaryDisplay();
      final tv = displays.firstWhere(
        (d) => d.id != primary.id,
        orElse: () => primary,
      );
      final pos = tv.visiblePosition ?? Offset.zero;
      final size = tv.visibleSize ?? tv.size;
      await controller.setFrame(
        Rect.fromLTWH(pos.dx, pos.dy, size.width, size.height),
      );
    } catch (e) {
      debugPrint('[TvWindowService] Screen detection error: $e');
      // If detection fails, just center the window.
      await controller.center();
      await controller.setFrame(
        const Rect.fromLTWH(0, 0, 1920, 1080),
      );
    }

    await controller.setTitle('Church Arena — TV Presenter');
    await controller.show();
    isOpen.value = true;
  }

  Future<void> close() async {
    final id = _windowId;
    if (id == null) return;
    try {
      await WindowController.fromWindowId(id).close();
    } catch (_) {}
    _windowId = null;
    isOpen.value = false;
  }

  // ── IPC helpers ───────────────────────────────────────────────────────────

  Future<void> showQuestion(TvPayload payload) =>
      _send('showQuestion', payload.toJson());

  Future<void> revealAnswer(TvPayload payload) =>
      _send('revealAnswer', payload.toJson());

  Future<void> clearScreen() => _send('clearScreen', {});

  Future<void> _send(String method, Map<String, dynamic> data) async {
    final id = _windowId;
    if (id == null) return;
    try {
      await DesktopMultiWindow.invokeMethod(id, method, jsonEncode(data));
    } catch (e) {
      debugPrint('[TvWindowService] $method error: $e');
      // Window was closed externally.
      _windowId = null;
      isOpen.value = false;
    }
  }
}
