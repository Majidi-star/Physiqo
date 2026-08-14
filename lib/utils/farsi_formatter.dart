class FarsiFormatter {
  FarsiFormatter._();

  /// Fixes common stuck Farsi words by inserting Zero-Width Non-Joiner (ZWNJ / نیم‌فاصله).
  static String format(String text) {
    if (text.isEmpty) return text;

    var formatted = text;

    // Suffixes: ها, های, ای, ایم, اید, اند, تر, ترین
    // ZWNJ is \u200C
    formatted = formatted
      .replaceAll('برنامههای', 'برنامه‌های')
      .replaceAll('برنامهها', 'برنامه‌ها')
      .replaceAll('برنامهریزی', 'برنامه‌ریزی')
      .replaceAll('برنامه ریزی', 'برنامه‌ریزی')
      .replaceAll('حرکتهای', 'حرکت‌های')
      .replaceAll('حرکتها', 'حرکت‌ها')
      .replaceAll('تمرینهای', 'تمرین‌های')
      .replaceAll('تمرینها', 'تمرین‌ها')
      .replaceAll('دورههای', 'دوره‌های')
      .replaceAll('دورهها', 'دوره‌ها')
      .replaceAll('گزینههای', 'گزینه‌های')
      .replaceAll('گزینهها', 'گزینه‌ها')
      .replaceAll('جلسههای', 'جلسه‌های')
      .replaceAll('جلسهها', 'جلسه‌ها')
      .replaceAll('هفتههای', 'هفته‌های')
      .replaceAll('هفتهها', 'هفته‌ها')
      .replaceAll('وعدههای', 'وعده‌های')
      .replaceAll('وعدهها', 'وعده‌ها')
      .replaceAll('دقیقههای', 'دقیقه‌های')
      .replaceAll('دقیقهها', 'دقیقه‌ها')
      .replaceAll('ثانیههای', 'ثانیه‌های')
      .replaceAll('ثانیهها', 'ثانیه‌ها')
      .replaceAll('شانههای', 'شانه‌های')
      .replaceAll('شانهها', 'شانه‌ها')
      .replaceAll('رسانههای', 'رسانه‌های')
      .replaceAll('رسانهها', 'رسانه‌ها')
      .replaceAll('جلوگیریهای', 'جلوگیری‌های')
      .replaceAll('جلوگیریها', 'جلوگیری‌ها');

    return formatted;
  }

  /// Formats numbers with Farsi digits if the active language is Farsi (fa).
  static String formatNumber(num number, String langCode) {
    final str = number.toString();
    if (langCode != 'fa') return str;
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const farsi = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var result = str;
    for (int i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], farsi[i]);
    }
    return result;
  }
}
