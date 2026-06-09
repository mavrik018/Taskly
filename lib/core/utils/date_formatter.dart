import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String formatDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }

  static String formatTime(DateTime time) {
    return DateFormat.jm().format(time);
  }

  static String formatRelativeDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final difference = target.difference(today).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference > 1 && difference <= 7) {
      return DateFormat('EEEE').format(date); // e.g. "Wednesday"
    } else {
      return DateFormat.yMMMd().format(date);
    }
  }
}
