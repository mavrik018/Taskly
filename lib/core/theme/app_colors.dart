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

  // Priority level colors (Harmonious semantic HSL matched)
  static const Color priorityHigh = Color(0xFFEF4444);    // High (🔴)
  static const Color priorityMedium = Color(0xFFF59E0B);  // Medium (🟡)
  static const Color priorityLow = Color(0xFF10B981);     // Low (🟢)
  static const Color priorityNone = Color(0xFF71717A);    // Neutral/No Label
}
