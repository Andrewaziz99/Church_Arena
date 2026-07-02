// Manual DI configuration — no build_runner required.
import 'package:get_it/get_it.dart';

import '../core/database/database_helper.dart';
// ── Game ───────────────────────────────────────────────────────────────────────
import '../features/game/data/repositories/game_repository_impl.dart';
import '../features/game/domain/repositories/game_repository.dart';
import '../features/game/presentation/bloc/game_bloc.dart';
// ── Questions ──────────────────────────────────────────────────────────────────
import '../features/questions/data/datasources/question_local_datasource.dart';
import '../features/questions/data/repositories/question_repository_impl.dart';
import '../features/questions/domain/repositories/question_repository.dart';
import '../features/questions/domain/usecases/clear_all_questions_usecase.dart';
import '../features/questions/domain/usecases/delete_question_usecase.dart';
import '../features/questions/domain/usecases/get_categories_usecase.dart';
import '../features/questions/domain/usecases/get_questions_usecase.dart';
import '../features/questions/domain/usecases/import_questions_usecase.dart';
import '../features/questions/domain/usecases/reorder_questions_usecase.dart';
import '../features/questions/domain/usecases/save_category_usecase.dart';
import '../features/questions/domain/usecases/save_question_usecase.dart';
import '../features/questions/presentation/bloc/questions_bloc.dart';
// ── Scoreboard ─────────────────────────────────────────────────────────────────
import '../features/scoreboard/presentation/bloc/scoreboard_bloc.dart';
// ── Settings ───────────────────────────────────────────────────────────────────
import '../features/settings/data/repositories/settings_repository_impl.dart';
import '../features/settings/domain/repositories/settings_repository.dart';
import '../features/settings/domain/usecases/get_settings_usecase.dart';
import '../features/settings/domain/usecases/save_settings_usecase.dart';
import '../features/settings/presentation/bloc/settings_bloc.dart';
// ── Teams ──────────────────────────────────────────────────────────────────────
import '../features/teams/data/datasources/team_local_datasource.dart';
import '../features/teams/data/repositories/team_repository_impl.dart';
import '../features/teams/domain/repositories/team_repository.dart';
import '../features/teams/domain/usecases/delete_team_usecase.dart';
import '../features/teams/domain/usecases/get_teams_usecase.dart';
import '../features/teams/domain/usecases/reset_score_usecase.dart';
import '../features/teams/domain/usecases/save_team_usecase.dart';
import '../features/teams/domain/usecases/update_score_usecase.dart';
import '../features/teams/presentation/bloc/teams_bloc.dart';
import '../services/arduino/arduino_service.dart';
import '../services/audio/audio_service.dart';

void $initGetIt(GetIt g) {
  // Core
  if (!g.isRegistered<DatabaseHelper>()) {
    g.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper.instance);
  }
  if (!g.isRegistered<ArduinoService>()) {
    g.registerLazySingleton<ArduinoService>(() => ArduinoService());
  }
  if (!g.isRegistered<AudioService>()) {
    g.registerLazySingleton<AudioService>(() => AudioService());
  }

  // Teams
  if (!g.isRegistered<TeamLocalDataSource>()) {
    g.registerLazySingleton<TeamLocalDataSource>(
        () => TeamLocalDataSource(g<DatabaseHelper>()));
  }
  if (!g.isRegistered<TeamRepository>()) {
    g.registerLazySingleton<TeamRepository>(
        () => TeamRepositoryImpl(g<TeamLocalDataSource>()));
  }
  if (!g.isRegistered<GetTeamsUseCase>()) {
    g.registerLazySingleton<GetTeamsUseCase>(
        () => GetTeamsUseCase(g<TeamRepository>()));
  }
  if (!g.isRegistered<SaveTeamUseCase>()) {
    g.registerLazySingleton<SaveTeamUseCase>(
        () => SaveTeamUseCase(g<TeamRepository>()));
  }
  if (!g.isRegistered<DeleteTeamUseCase>()) {
    g.registerLazySingleton<DeleteTeamUseCase>(
        () => DeleteTeamUseCase(g<TeamRepository>()));
  }
  if (!g.isRegistered<UpdateScoreUseCase>()) {
    g.registerLazySingleton<UpdateScoreUseCase>(
        () => UpdateScoreUseCase(g<TeamRepository>()));
  }
  if (!g.isRegistered<ResetScoreUseCase>()) {
    g.registerLazySingleton<ResetScoreUseCase>(
        () => ResetScoreUseCase(g<TeamRepository>()));
  }
  if (!g.isRegistered<TeamsBloc>()) {
    g.registerFactory<TeamsBloc>(() => TeamsBloc(
          getTeams: g<GetTeamsUseCase>(),
          saveTeam: g<SaveTeamUseCase>(),
          deleteTeam: g<DeleteTeamUseCase>(),
          updateScore: g<UpdateScoreUseCase>(),
          resetScore: g<ResetScoreUseCase>(),
        ));
  }

  // Questions
  if (!g.isRegistered<QuestionLocalDataSource>()) {
    g.registerLazySingleton<QuestionLocalDataSource>(
        () => QuestionLocalDataSource(g<DatabaseHelper>()));
  }
  if (!g.isRegistered<QuestionRepository>()) {
    g.registerLazySingleton<QuestionRepository>(
        () => QuestionRepositoryImpl(g<QuestionLocalDataSource>()));
  }
  if (!g.isRegistered<GetQuestionsUseCase>()) {
    g.registerLazySingleton<GetQuestionsUseCase>(
        () => GetQuestionsUseCase(g<QuestionRepository>()));
  }
  if (!g.isRegistered<SaveQuestionUseCase>()) {
    g.registerLazySingleton<SaveQuestionUseCase>(
        () => SaveQuestionUseCase(g<QuestionRepository>()));
  }
  if (!g.isRegistered<DeleteQuestionUseCase>()) {
    g.registerLazySingleton<DeleteQuestionUseCase>(
        () => DeleteQuestionUseCase(g<QuestionRepository>()));
  }
  if (!g.isRegistered<ImportQuestionsUseCase>()) {
    g.registerLazySingleton<ImportQuestionsUseCase>(
        () => ImportQuestionsUseCase(g<QuestionRepository>()));
  }
  if (!g.isRegistered<GetCategoriesUseCase>()) {
    g.registerLazySingleton<GetCategoriesUseCase>(
        () => GetCategoriesUseCase(g<QuestionRepository>()));
  }
  if (!g.isRegistered<SaveCategoryUseCase>()) {
    g.registerLazySingleton<SaveCategoryUseCase>(
        () => SaveCategoryUseCase(g<QuestionRepository>()));
  }
  if (!g.isRegistered<ClearAllQuestionsUseCase>()) {
    g.registerLazySingleton<ClearAllQuestionsUseCase>(
        () => ClearAllQuestionsUseCase(g<QuestionRepository>()));
  }
  if (!g.isRegistered<ReorderQuestionsUseCase>()) {
    g.registerLazySingleton<ReorderQuestionsUseCase>(
        () => ReorderQuestionsUseCase(g<QuestionRepository>()));
  }
  if (!g.isRegistered<QuestionsBloc>()) {
    g.registerFactory<QuestionsBloc>(() => QuestionsBloc(
          getQuestions: g<GetQuestionsUseCase>(),
          saveQuestion: g<SaveQuestionUseCase>(),
          deleteQuestion: g<DeleteQuestionUseCase>(),
          importQuestions: g<ImportQuestionsUseCase>(),
          getCategories: g<GetCategoriesUseCase>(),
          saveCategory: g<SaveCategoryUseCase>(),
          clearAllQuestions: g<ClearAllQuestionsUseCase>(),
          reorderQuestions: g<ReorderQuestionsUseCase>(),
        ));
  }

  // Game
  if (!g.isRegistered<GameRepository>()) {
    g.registerLazySingleton<GameRepository>(() => GameRepositoryImpl());
  }
  if (!g.isRegistered<GameBloc>()) {
    g.registerFactory<GameBloc>(() => GameBloc(
          repository: g<GameRepository>(),
          audioService: g<AudioService>(),
          arduinoService: g<ArduinoService>(),
        ));
  }

  // Settings
  if (!g.isRegistered<SettingsRepository>()) {
    g.registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl());
  }
  if (!g.isRegistered<GetSettingsUseCase>()) {
    g.registerLazySingleton<GetSettingsUseCase>(
        () => GetSettingsUseCase(g<SettingsRepository>()));
  }
  if (!g.isRegistered<SaveSettingsUseCase>()) {
    g.registerLazySingleton<SaveSettingsUseCase>(
        () => SaveSettingsUseCase(g<SettingsRepository>()));
  }
  if (!g.isRegistered<SettingsBloc>()) {
    g.registerFactory<SettingsBloc>(() => SettingsBloc(
          getSettings: g<GetSettingsUseCase>(),
          saveSettings: g<SaveSettingsUseCase>(),
          arduinoService: g<ArduinoService>(),
        ));
  }

  // Scoreboard
  if (!g.isRegistered<ScoreboardBloc>()) {
    g.registerFactory<ScoreboardBloc>(() => ScoreboardBloc());
  }
}
