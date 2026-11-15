class PersianDateHelper {
  static const List<String> monthNames = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  static const List<String> weekDays = [
    'دوشنبه',
    'سه‌شنبه',
    'چهارشنبه',
    'پنج‌شنبه',
    'جمعه',
    'شنبه',
    'یکشنبه',
  ];

  /// Converts Gregorian DateTime to [year, month, day] in Solar Hijri (Jalali)
  static (int, int, int) gregorianToJalali(DateTime dt) {
    int gy = dt.year;
    int gm = dt.month;
    int gd = dt.day;

    final List<int> gDm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    int jy = (gy > 1600) ? 979 : 0;
    gy -= (gy > 1600) ? 1600 : 621;

    int days = (365 * gy + ((gy + 3) ~/ 4) - ((gy + 99) ~/ 100) + ((gy + 399) ~/ 400) - 80 + gd + gDm[gm - 1]);
    jy += 33 * (days ~/ 12053);
    days %= 12053;
    jy += 4 * (days ~/ 1461);
    days %= 1461;

    if (days > 365) {
      jy += ((days - 1) ~/ 365);
      days = (days - 1) % 365;
    }

    int jm, jd;
    if (days < 186) {
      jm = 1 + (days ~/ 31);
      jd = 1 + (days % 31);
    } else {
      jm = 7 + ((days - 186) ~/ 30);
      jd = 1 + ((days - 186) % 30);
    }

    return (jy, jm, jd);
  }

  /// Converts English numbers to Persian digits (e.g. 1405 -> ۱۴۰۵)
  static String toPersianDigits(dynamic input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    String res = input.toString();
    for (int i = 0; i < 10; i++) {
      res = res.replaceAll(english[i], persian[i]);
    }
    return res;
  }

  /// Human-readable date label for chat grouping
  static String formatJalaliHeader(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diffDays = today.difference(target).inDays;

    final (jy, jm, jd) = gregorianToJalali(dt);
    final monthName = monthNames[jm - 1];
    final dayStr = toPersianDigits(jd);
    final yearStr = toPersianDigits(jy);

    if (diffDays == 0) {
      return 'امروز — $dayStr $monthName';
    } else if (diffDays == 1) {
      return 'دیروز — $dayStr $monthName';
    } else {
      // weekday: 1 = Monday, 7 = Sunday
      final weekdayName = weekDays[dt.weekday - 1];
      return '$weekdayName $dayStr $monthName $yearStr';
    }
  }

  /// Formats time in HH:mm with Persian digits
  static String formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return toPersianDigits('$h:$m');
  }

  /// Unique date key for grouping (e.g. "1405-08-24")
  static String getDateKey(DateTime dt) {
    final (jy, jm, jd) = gregorianToJalali(dt);
    return '$jy-${jm.toString().padLeft(2, '0')}-${jd.toString().padLeft(2, '0')}';
  }
}
