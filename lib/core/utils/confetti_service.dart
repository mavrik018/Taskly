import 'package:flutter/material.dart';

class ConfettiService {
  ConfettiService._();

  /// Increments the task completion counter and triggers confetti if a milestone is reached.
  /// (Disabled per user request)
  static Future<void> notifyTaskCompleted(BuildContext context) async {
    // No-op
  }

  /// Triggers the full screen confetti particle overlay.
  /// (Disabled per user request)
  static void showConfetti(BuildContext context, int milestoneCount) {
    // No-op
  }
}
