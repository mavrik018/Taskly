import 'package:flutter/animation.dart';

class AppAnimations {
  AppAnimations._();

  // Durations
  static const Duration micro = Duration(milliseconds: 100);
  static const Duration standard = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration long = Duration(milliseconds: 500);

  // Curves
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve spring = Curves.elasticOut;
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;
}
