import 'package:flutter/material.dart';
import 'package:apptobe/core/theme/app_colors.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryAccent,
      secondary: AppColors.actionBlue,
      background: AppColors.lightBackground,
      surface: AppColors.lightSurface,
      onPrimary: AppColors.lightTextPrimary,
      onSecondary: AppColors.lightTextPrimary,
      onBackground: AppColors.lightTextPrimary,
      onSurface: AppColors.lightTextPrimary,
      error: AppColors.errorRed,
      onError: AppColors.lightTextPrimary,
    ),
    cardTheme: const CardThemeData(elevation: 2),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary),
      bodyMedium: TextStyle(fontSize: 16, color: AppColors.lightTextSecondary),
      labelLarge: TextStyle(fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary),
      labelMedium: TextStyle(fontSize: 14, color: AppColors.lightTextPrimary),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryAccent,
      secondary: AppColors.actionBlue,
      background: AppColors.background,
      surface: AppColors.surface,
      onPrimary: AppColors.textPrimary,
      onSecondary: AppColors.textPrimary,
      onBackground: AppColors.textPrimary,
      onSurface: AppColors.textPrimary,
      error: AppColors.errorRed,
      onError: AppColors.textPrimary,
    ),
    cardTheme: const CardThemeData(elevation: 2),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      bodyMedium: TextStyle(fontSize: 16, color: AppColors.textSecondary),
      labelLarge: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      labelMedium: TextStyle(fontSize: 14, color: AppColors.textPrimary),
    ),
  );
}