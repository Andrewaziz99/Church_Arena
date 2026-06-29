import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand palette ─────────────────────────────────────────────
  static const Color orangeBg       = Color(0xFFF9A825); // Golden orange — large backgrounds
  static const Color orangeDark     = Color(0xFF835400); // Dark brown-orange — primary controls
  static const Color orangeDeep     = Color(0xFF674100); // Deeper brown
  static const Color blueContent   = Color(0xFF00629E); // Cerulean blue — content stage
  static const Color blueLight     = Color(0xFF62B4FE); // Light blue — containers
  static const Color greenSuccess  = Color(0xFF006E1C); // Lime green — success / accents
  static const Color greenLight    = Color(0xFF6FCD6E); // Light green
  static const Color redError      = Color(0xFFBA1A1A); // Error red

  // ── Surface / background ──────────────────────────────────────
  static const Color background    = Color(0xFFF9A825); // App main background
  static const Color surface       = Color(0xFFFFFFFF); // White cards
  static const Color surfaceLight  = Color(0xFFF3F3F4); // Light surface
  static const Color surfaceDim    = Color(0xFFDADADA); // Dim surface

  // ── Text ─────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF1A1C1C);
  static const Color textSecondary = Color(0xFF524434);
  static const Color textOnDark    = Color(0xFFFFFFFF);

  // ── Borders ───────────────────────────────────────────────────
  static const Color border        = Color(0xFFD7C3AE);
  static const Color borderBlue    = Color(0xFF62B4FE);

  // ── Semantic aliases (backward compat) ────────────────────────
  static const Color primary       = orangeDark;
  static const Color accent        = orangeBg;
  static const Color success       = greenSuccess;
  static const Color error         = redError;

  // ── Scoreboard (dark cinematic display) ───────────────────────
  static const Color scoreboardBg  = Color(0xFF0D1526);
  static const Color scoreboardCard= Color(0xFF1A2A42);

  // ── Team color palette ────────────────────────────────────────
  static const List<Color> teamColors = [
    Color(0xFF00629E), // Blue
    Color(0xFFF9A825), // Orange
    Color(0xFF006E1C), // Green
    Color(0xFFBA1A1A), // Red
    Color(0xFF835400), // Brown
    Color(0xFF6A0DAD), // Purple
    Color(0xFF00897B), // Teal
    Color(0xFFE91E63), // Pink
  ];
}
