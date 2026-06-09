import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppRadius {
  AppRadius._();

  static double get sm => 4.0.r;
  static double get md => 8.0.r;
  static double get lg => 12.0.r;
  static double get xl => 16.0.r;
  static double get xxl => 24.0.r;
  static double get full => 999.0.r;

  static BorderRadius get borderSM => BorderRadius.all(Radius.circular(sm));
  static BorderRadius get borderMD => BorderRadius.all(Radius.circular(md));
  static BorderRadius get borderLG => BorderRadius.all(Radius.circular(lg));
  static BorderRadius get borderXL => BorderRadius.all(Radius.circular(xl));
  static BorderRadius get borderXXL => BorderRadius.all(Radius.circular(xxl));
  static BorderRadius get borderCircular => BorderRadius.all(Radius.circular(full));
}
