import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static TextTheme _buildTextTheme() {
    final base = GoogleFonts.alexandriaTextTheme();
    return base.copyWith(
      displayLarge:   base.displayLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w900),
      displayMedium:  base.displayMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w900),
      displaySmall:   base.displaySmall?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
      headlineLarge:  base.headlineLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
      headlineMedium: base.headlineMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
      headlineSmall:  base.headlineSmall?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
      titleLarge:     base.titleLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
      titleMedium:    base.titleMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      titleSmall:     base.titleSmall?.copyWith(color: AppColors.textSecondary),
      bodyLarge:      base.bodyLarge?.copyWith(color: AppColors.textPrimary),
      bodyMedium:     base.bodyMedium?.copyWith(color: AppColors.textPrimary),
      bodySmall:      base.bodySmall?.copyWith(color: AppColors.textSecondary),
      labelLarge:     base.labelLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
      labelMedium:    base.labelMedium?.copyWith(color: AppColors.textSecondary),
      labelSmall:     base.labelSmall?.copyWith(color: AppColors.textSecondary),
    );
  }

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      surface: AppColors.surface,
      primary: AppColors.orangeDark,
      secondary: AppColors.blueContent,
      tertiary: AppColors.greenSuccess,
      error: AppColors.redError,
      onSurface: AppColors.textPrimary,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.white,
      outline: AppColors.border,
    ),
    textTheme: _buildTextTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.alexandria(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      margin: const EdgeInsets.all(8),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.orangeDark,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        textStyle: GoogleFonts.alexandria(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.5),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.orangeDark,
        side: const BorderSide(color: AppColors.orangeDark, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.blueContent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.blueContent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.redError),
      ),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textSecondary),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceLight,
      selectedColor: AppColors.orangeDark.withOpacity(0.2),
      labelStyle: const TextStyle(color: AppColors.textPrimary),
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    iconTheme: const IconThemeData(color: AppColors.textSecondary),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.orangeDark : AppColors.textSecondary,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.orangeBg : AppColors.border,
      ),
    ),
  );

  // Keep darkTheme as alias
  static ThemeData get darkTheme => lightTheme;

  static List<BoxShadow> cardShadow() => [
    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4)),
  ];

  static List<BoxShadow> neonShadow(Color color) => [
    BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, spreadRadius: 1),
    BoxShadow(color: color.withOpacity(0.2), blurRadius: 24, spreadRadius: 2),
  ];
}
