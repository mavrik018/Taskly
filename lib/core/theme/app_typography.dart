import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get display => GoogleFonts.inter(
        fontSize: 32.sp,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        height: 1.2,
      );

  static TextStyle get h1 => GoogleFonts.inter(
        fontSize: 24.sp,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.25,
      );

  static TextStyle get h2 => GoogleFonts.inter(
        fontSize: 20.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.3,
      );

  static TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 18.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.35,
      );

  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 15.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.4,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 15.sp,
        fontWeight: FontWeight.w400,
        height: 1.55,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 13.5.sp,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 11.5.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11.sp,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.4,
      );
}
