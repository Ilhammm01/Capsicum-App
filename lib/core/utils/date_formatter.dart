import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final timeStr = DateFormat('HH:mm').format(dateTime);

    if (targetDay == today) {
      return 'Hari ini, $timeStr';
    } else if (targetDay == yesterday) {
      return 'Kemarin, $timeStr';
    } else {
      return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(dateTime);
    }
  }

  static String formatFull(DateTime dateTime) {
    return DateFormat('EEEE, d MMMM yyyy — HH:mm', 'id_ID').format(dateTime);
  }

  static String formatDate(DateTime dateTime) {
    return DateFormat('d MMM yyyy', 'id_ID').format(dateTime);
  }
}
