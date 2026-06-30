import 'dart:async';
import 'package:church_arena/services/sync/supabase_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'core/database/database_helper.dart';
import 'core/utils/app_logger.dart';
import 'features/questions/data/datasources/question_local_datasource.dart';
import 'features/teams/data/datasources/team_local_datasource.dart';
import 'injection/injection.dart';
import 'services/audio/audio_service.dart';
import 'services/sync/supabase_realtime_manager.dart';

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

  // SQLite — must succeed; if it fails the app can't run at all.
  try {
    await DatabaseHelper.instance.database;
  } catch (e) {
    AppLogger.e('Database init failed: $e');
  }

  // Supabase — optional; skips if credentials are placeholders or offline.
  try {
    await initSupabase();
  } catch (e) {
    AppLogger.e('Supabase init failed: $e');
  }

  // DI wiring.
  configureDependencies();

  // Audio — optional; Windows plugin may silently no-op.
  try {
    await GetIt.I<AudioService>().initialize();
  } catch (e) {
    AppLogger.e('AudioService init failed: $e');
  }

  // Realtime two-way sync — non-blocking; runs in background.
  unawaited(
    SupabaseRealtimeManager.instance.start(
      teamDs: GetIt.I<TeamLocalDataSource>(),
      questionDs: GetIt.I<QuestionLocalDataSource>(),
    ),
  );

  // runApp is always reached regardless of any init failures above.
  runApp(const App());
}
