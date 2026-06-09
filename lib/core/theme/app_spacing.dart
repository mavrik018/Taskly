import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppSpacing {
  AppSpacing._();

  static double get xxs => 4.0.w;
  static double get xs => 8.0.w;
  static double get sm => 12.0.w;
  static double get md => 16.0.w;
  static double get lg => 24.0.w;
  static double get xl => 32.0.w;
  static double get xxl => 48.0.w;
  static double get xxxl => 64.0.w;

  static double get h_xxs => 4.0.h;
  static double get h_xs => 8.0.h;
  static double get h_sm => 12.0.h;
  static double get h_md => 16.0.h;
  static double get h_lg => 24.0.h;
  static double get h_xl => 32.0.h;
  static double get h_xxl => 48.0.h;
  static double get h_xxxl => 64.0.h;

  // Horizontal Spacing widgets
  static Widget get widthXXS => SizedBox(width: 4.0.w);
  static Widget get widthXS => SizedBox(width: 8.0.w);
  static Widget get widthSM => SizedBox(width: 12.0.w);
  static Widget get widthMD => SizedBox(width: 16.0.w);
  static Widget get widthLG => SizedBox(width: 24.0.w);
  static Widget get widthXL => SizedBox(width: 32.0.w);

  // Vertical Spacing widgets
  static Widget get heightXXS => SizedBox(height: 4.0.h);
  static Widget get heightXS => SizedBox(height: 8.0.h);
  static Widget get heightSM => SizedBox(height: 12.0.h);
  static Widget get heightMD => SizedBox(height: 16.0.h);
  static Widget get heightLG => SizedBox(height: 24.0.h);
  static Widget get heightXL => SizedBox(height: 32.0.h);
}
