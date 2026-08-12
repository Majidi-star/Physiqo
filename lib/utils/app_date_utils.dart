import 'package:flutter/widgets.dart';
import 'package:shamsi_date/shamsi_date.dart';

class AppDateUtils {
  static const List<String> faMonths = [
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'
  ];

  static const List<String> enMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  /// Returns true if the current locale is Persian
  static bool isFa(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'fa';
  }

  /// Returns the day number (e.g. "21" for Jalali or "12" for Gregorian)
  static String getDayNumber(DateTime date, bool useJalali) {
    if (useJalali) {
      final jalali = Jalali.fromDateTime(date);
      return jalali.day.toString();
    }
    return date.day.toString();
  }

  /// Returns a formatted string like "21 مرداد" or "Aug 12" based on locale
  static String formatMonthDay(DateTime date, bool useJalali) {
    if (useJalali) {
      final jalali = Jalali.fromDateTime(date);
      return '${jalali.day} ${faMonths[jalali.month - 1]}';
    } else {
      return '${enMonths[date.month - 1]} ${date.day}';
    }
  }

  /// Returns a full formatted string like "21 مرداد 1402" or "Aug 12 2023"
  static String formatFullDate(DateTime date, bool useJalali) {
    if (useJalali) {
      final jalali = Jalali.fromDateTime(date);
      return '${jalali.day} ${faMonths[jalali.month - 1]} ${jalali.year}';
    } else {
      return '${enMonths[date.month - 1]} ${date.day} ${date.year}';
    }
  }
}
