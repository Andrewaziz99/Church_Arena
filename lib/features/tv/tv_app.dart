import 'dart:convert';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'tv_controller.dart';
import 'tv_screen.dart';

/// The Flutter app that runs inside the TV sub-window.
/// Receives IPC method calls from the main window and updates [TvController].
class TvApp extends StatefulWidget {
  final int windowId;
  const TvApp({super.key, required this.windowId});

  @override
  State<TvApp> createState() => _TvAppState();
}

class _TvAppState extends State<TvApp> {
  @override
  void initState() {
    super.initState();
    // Register IPC handler — main window calls these methods
    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      switch (call.method) {
        case 'showQuestion':
        case 'revealAnswer':
          final data =
              jsonDecode(call.arguments as String) as Map<String, dynamic>;
          TvController.instance.update(TvPayload.fromJson(data));
        case 'clearScreen':
          TvController.instance.clear();
      }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Church Arena — TV',
      theme: ThemeData.dark(useMaterial3: true),
      home: const TvScreen(),
    );
  }
}
