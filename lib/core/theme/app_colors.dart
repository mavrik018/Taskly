import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary brand colors
  static const Color primary = Color(0xFF6366F1); // Vibrant Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);

  // Light Theme palette
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF18181B);
  static const Color lightTextSecondary = Color(0xFF71717A);
  static const Color lightBorder = Color(0xFFE4E4E7);

  // Dark Theme palette
  static const Color darkBackground = Color(0xFF09090B); // True black/obsidian
  static const Color darkSurface = Color(0xFF18181B);
  static const Color darkTextPrimary = Color(0xFFF4F4F5);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);
  static const Color darkBorder = Color(0xFF27272A);

  // Priority level colors (Harmonious semantic HSL matched with high contrast)
  static const Color priorityHigh = Color(0xFFE11D48);    // High (Rose-Red)
  static const Color priorityMedium = Color(0xFFD97706);  // Medium (Amber)
  static const Color priorityLow = Color(0xFF059669);     // Low (Emerald)
  static const Color priorityNone = Color(0xFF71717A);    // Neutral/No Label
}
