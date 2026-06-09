import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_radius.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.lightBackground,
      cardColor: AppColors.lightSurface,
      dividerColor: AppColors.lightBorder,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: AppColors.lightBackground,
        onSurface: AppColors.lightTextPrimary,
        outline: AppColors.lightBorder,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.display.copyWith(color: AppColors.lightTextPrimary),
        headlineLarge: AppTypography.h1.copyWith(color: AppColors.lightTextPrimary),
        headlineMedium: AppTypography.h2.copyWith(color: AppColors.lightTextPrimary),
        titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.lightTextPrimary),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.lightTextPrimary),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextPrimary),
        labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.lightTextPrimary),
        labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.lightTextSecondary),
        bodySmall: AppTypography.caption.copyWith(color: AppColors.lightTextSecondary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLG,
          side: const BorderSide(color: AppColors.lightBorder, width: 1.0),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
        centerTitle: false,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.darkBackground,
      cardColor: AppColors.darkSurface,
      dividerColor: AppColors.darkBorder,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: AppColors.darkBackground,
        onSurface: AppColors.darkTextPrimary,
        outline: AppColors.darkBorder,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.display.copyWith(color: AppColors.darkTextPrimary),
        headlineLarge: AppTypography.h1.copyWith(color: AppColors.darkTextPrimary),
        headlineMedium: AppTypography.h2.copyWith(color: AppColors.darkTextPrimary),
        titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.darkTextPrimary),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.darkTextPrimary),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextPrimary),
        labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.darkTextPrimary),
        labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.darkTextSecondary),
        bodySmall: AppTypography.caption.copyWith(color: AppColors.darkTextSecondary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLG,
          side: const BorderSide(color: AppColors.darkBorder, width: 1.0),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
        centerTitle: false,
      ),
    );
  }
}
