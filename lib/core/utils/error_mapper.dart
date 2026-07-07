class ErrorMapper {
  /// Maps authentication exceptions to a user-friendly message.
  static String getAuthErrorMessage(dynamic error) {
    final msg = error.toString().toLowerCase();

    if (msg.contains('socket') ||
        msg.contains('network') ||
        msg.contains('connection') ||
        msg.contains('failed host') ||
        msg.contains('handshake') ||
        msg.contains('timeout')) {
      return 'A connection error occurred. Please check your internet connection and try again.';
    }

    if (msg.contains('invalid credential') ||
        msg.contains('invalid login') ||
        msg.contains('invalid_grant')) {
      return 'Invalid email or password. Please try again.';
    }

    if (msg.contains('already registered') ||
        msg.contains('email in use') ||
        msg.contains('user already exists') ||
        msg.contains('signup-failed')) {
      return 'An account with this email already exists.';
    }

    if (msg.contains('weak password') || msg.contains('password should be')) {
      return 'The password provided is too weak. Please choose a stronger one (at least 6 characters).';
    }

    if (msg.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }

    return 'An unexpected error occurred during authentication. Please try again.';
  }

  /// Maps AI related exceptions (Smart parsing, breakdown, weekly review) to user-friendly messages.
  static String getAIErrorMessage(dynamic error) {
    final msg = error.toString().toLowerCase();

    if (msg.contains('socket') ||
        msg.contains('network') ||
        msg.contains('connection') ||
        msg.contains('failed host') ||
        msg.contains('handshake') ||
        msg.contains('timeout')) {
      return 'A connection error occurred. Please check your internet connection to use AI features.';
    }

    if (msg.contains('rate limit') ||
        msg.contains('cooldown') ||
        msg.contains('too many requests')) {
      return 'AI assistant is resting. Please wait a moment before trying again.';
    }

    if (msg.contains('premium')) {
      return 'This feature requires a premium subscription.';
    }

    if (msg.contains('weekly_limit_reached')) {
      return 'You have already generated your weekly summary for this week. Please wait until next week to generate a new one.';
    }

    return 'Could not process AI request at this moment. Please try again.';
  }

  /// Maps project creation/deletion related exceptions to user-friendly messages.
  static String getProjectErrorMessage(dynamic error) {
    final msg = error.toString().toLowerCase();

    if (msg.contains('limit') || msg.contains('free tier')) {
      return 'Project limit reached. Please upgrade your subscription to create more projects.';
    }

    if (msg.contains('socket') ||
        msg.contains('network') ||
        msg.contains('connection') ||
        msg.contains('failed host')) {
      return 'A connection error occurred. Please check your internet connection.';
    }

    return 'Could not update project list. Please try again.';
  }
}
