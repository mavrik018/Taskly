import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_radius.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.lightTextPrimary,
      scaffoldBackgroundColor: AppColors.lightBackground,
      cardColor: AppColors.lightSurface,
      dividerColor: AppColors.lightBorder,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightTextPrimary,
        onPrimary: AppColors.lightBackground,
        secondary: AppColors.lightTextSecondary,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
        outline: AppColors.lightBorder,
      ),
      textTheme: TextTheme(
        displayLarge:
            AppTypography.display.copyWith(color: AppColors.lightTextPrimary),
        headlineLarge:
            AppTypography.h1.copyWith(color: AppColors.lightTextPrimary),
        headlineMedium:
            AppTypography.h2.copyWith(color: AppColors.lightTextPrimary),
        titleLarge: AppTypography.titleLarge
            .copyWith(color: AppColors.lightTextPrimary),
        titleMedium: AppTypography.titleMedium
            .copyWith(color: AppColors.lightTextPrimary),
        bodyLarge:
            AppTypography.bodyLarge.copyWith(color: AppColors.lightTextPrimary),
        bodyMedium: AppTypography.bodyMedium
            .copyWith(color: AppColors.lightTextPrimary),
        labelLarge: AppTypography.labelLarge
            .copyWith(color: AppColors.lightTextPrimary),
        labelMedium: AppTypography.labelMedium
            .copyWith(color: AppColors.lightTextSecondary),
        bodySmall:
            AppTypography.caption.copyWith(color: AppColors.lightTextSecondary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLG,
          side: const BorderSide(color: AppColors.lightBorder, width: 1.0),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurface,
        side: const BorderSide(color: AppColors.lightBorder),
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.lightTextPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.lightTextPrimary),
        centerTitle: false,
        titleTextStyle: AppTypography.h1.copyWith(
          color: AppColors.lightTextPrimary,
          fontWeight: FontWeight.w900,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        filled: false,
        hintStyle: AppTypography.bodyLarge.copyWith(
          color: AppColors.lightTextSecondary.withOpacity(0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightTextPrimary,
          foregroundColor: AppColors.lightBackground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderLG,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.lightTextPrimary,
        foregroundColor: AppColors.lightBackground,
        elevation: 6,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.darkTextPrimary,
      scaffoldBackgroundColor: AppColors.darkBackground,
      cardColor: AppColors.darkSurface,
      dividerColor: AppColors.darkBorder,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkTextPrimary,
        onPrimary: AppColors.darkBackground,
        secondary: AppColors.darkTextSecondary,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        outline: AppColors.darkBorder,
      ),
      textTheme: TextTheme(
        displayLarge:
            AppTypography.display.copyWith(color: AppColors.darkTextPrimary),
        headlineLarge:
            AppTypography.h1.copyWith(color: AppColors.darkTextPrimary),
        headlineMedium:
            AppTypography.h2.copyWith(color: AppColors.darkTextPrimary),
        titleLarge:
            AppTypography.titleLarge.copyWith(color: AppColors.darkTextPrimary),
        titleMedium: AppTypography.titleMedium
            .copyWith(color: AppColors.darkTextPrimary),
        bodyLarge:
            AppTypography.bodyLarge.copyWith(color: AppColors.darkTextPrimary),
        bodyMedium:
            AppTypography.bodyMedium.copyWith(color: AppColors.darkTextPrimary),
        labelLarge:
            AppTypography.labelLarge.copyWith(color: AppColors.darkTextPrimary),
        labelMedium: AppTypography.labelMedium
            .copyWith(color: AppColors.darkTextSecondary),
        bodySmall:
            AppTypography.caption.copyWith(color: AppColors.darkTextSecondary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLG,
          side: const BorderSide(color: AppColors.darkBorder, width: 1.0),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurface,
        side: const BorderSide(color: AppColors.darkBorder),
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
        centerTitle: false,
        titleTextStyle: AppTypography.h1.copyWith(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.w900,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        filled: false,
        hintStyle: AppTypography.bodyLarge.copyWith(
          color: AppColors.darkTextSecondary.withOpacity(0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkTextPrimary,
          foregroundColor: AppColors.darkBackground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderLG,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkTextPrimary,
        foregroundColor: AppColors.darkBackground,
        elevation: 6,
      ),
    );
  }
}
