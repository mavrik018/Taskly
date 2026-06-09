import 'package:flutter/rendering.dart' as rendering;
import 'package:flutter/widgets.dart';

class AppSemanticsService {
  AppSemanticsService._();

  static void announce(String message, {TextDirection textDirection = TextDirection.ltr}) {
    rendering.SemanticsService.announce(message, textDirection);
  }
}
