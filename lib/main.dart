import 'package:church_arena/services/sync/supabase_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'core/database/database_helper.dart';
import 'injection/injection.dart';
import 'services/audio/audio_service.dart';

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
  await initSupabase();
  configureDependencies();
  await GetIt.I<AudioService>().initialize();
  runApp(const App());
}
