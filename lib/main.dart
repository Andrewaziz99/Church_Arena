import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'core/database/database_helper.dart';
import 'injection/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  const WindowOptions windowOptions = WindowOptions(
    minimumSize: Size(1280, 720),
    size: Size(1600, 900),
    title: 'Church Arena',
    backgroundColor: Color(0xFF050A18),
    titleBarStyle: TitleBarStyle.normal,
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  // Initialize sqflite database (singleton, creates tables on first run)
  await DatabaseHelper.instance.database;
  configureDependencies();
  runApp(const App());
}
