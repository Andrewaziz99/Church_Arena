import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';
import 'features/teams/presentation/bloc/teams_bloc.dart';
import 'features/questions/presentation/bloc/questions_bloc.dart';
import 'features/game/presentation/bloc/game_bloc.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'features/scoreboard/presentation/bloc/scoreboard_bloc.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => GetIt.I<TeamsBloc>()..add(const LoadTeams())),
        BlocProvider(create: (_) => GetIt.I<QuestionsBloc>()..add(const LoadQuestions())),
        BlocProvider(create: (_) => GetIt.I<GameBloc>()),
        BlocProvider(create: (_) => GetIt.I<SettingsBloc>()..add(const LoadSettings())),
        BlocProvider(create: (_) => GetIt.I<ScoreboardBloc>()),
      ],
      child: MaterialApp.router(
        title: 'Church Arena',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: appRouter,
      ),
    );
  }
}
