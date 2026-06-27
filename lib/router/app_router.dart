import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/teams/presentation/screens/teams_screen.dart';
import '../features/questions/presentation/screens/questions_screen.dart';
import '../features/game/presentation/screens/game_screen.dart';
import '../features/game/presentation/screens/game_setup_screen.dart';
import '../features/scoreboard/presentation/screens/scoreboard_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'dashboard',
      builder: (_, __) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/teams',
      name: 'teams',
      builder: (_, __) => const TeamsScreen(),
    ),
    GoRoute(
      path: '/questions',
      name: 'questions',
      builder: (_, __) => const QuestionsScreen(),
    ),
    GoRoute(
      path: '/game/setup',
      name: 'game-setup',
      builder: (_, state) => GameSetupScreen(
        preselectedCategoryName: state.uri.queryParameters['category'],
      ),
    ),
    GoRoute(
      path: '/game',
      name: 'game',
      builder: (_, __) => const GameScreen(),
    ),
    GoRoute(
      path: '/scoreboard',
      name: 'scoreboard',
      builder: (_, __) => const ScoreboardScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (_, __) => const SettingsScreen(),
    ),
  ],
);
