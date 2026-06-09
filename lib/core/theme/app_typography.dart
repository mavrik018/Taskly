import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get display => GoogleFonts.inter(
        fontSize: 32.sp,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      );

  static TextStyle get h1 => GoogleFonts.inter(
        fontSize: 24.sp,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      );

  static TextStyle get h2 => GoogleFonts.inter(
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      );

  static TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16.sp,
        fontWeight: FontWeight.normal,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14.sp,
        fontWeight: FontWeight.normal,
      );

  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.2,
      );
}
