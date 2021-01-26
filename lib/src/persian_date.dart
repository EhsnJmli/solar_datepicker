const String yyyy = 'yyyy'; // 4 عدد سال

const String yy = 'yy'; // 2 عدد سال

const String mm = 'mm'; // 2 عدد ماه اگر ماه تک رقمی باشد 0 در اول ان قرار میدهد

const String m = 'm'; // 1 عدد ماه اگر ماه تک رقمی باشد 0 قرار نمیدهد

const String mmCaps = 'MM'; // ماه به صورت حروفی کامل

const String M = 'M'; // ماه به صورت حروفی کوتاه

const String dd = 'dd'; // روز به صورت 2 عددی

const String d = 'd'; // روز به صورت تک رقمی برای روز های زیر 10

const String w = 'w'; // عدد هفته از ماه را بر میگرداند

const String dD = 'DD'; // نام روز

const String D = 'D'; // نام روز

const String hh =
    'hh'; // ساعت با دو رقم اگر ساعت تک رقمی باشد 0 ابتدای عدد قرار میدهد فرمت 12 ساعته

const String h = 'h'; // ساعت با تک رقم فرمت 12 ساعته

const String hhCaps = 'HH'; // ساعت با 2 رقم فرمت 24 ساعته

const String H = 'H'; // ساعت با تک رقم فرمت 24 ساعته

const String nn = 'nn'; // نمایشه دقیقه به صورت دو رقمی

const String n = 'n'; // نمایشه دقیقه به صورت تک رقمی

const String ss = 'ss'; // نمایش ثانیه دو رقمی

const String s = 's'; // نمایش ثانیه تک رقمی

const String sss = 'SSS'; // نمایش میلی ثانیه

const String S = 'S'; // نمایش میلی ثانیه

const String uuu = 'uuu'; // نمایش میکرو ثانیه

const String u = 'u'; // نمایش میکرو ثانیه

const String am = 'am'; // نمایش وقت به صورت کوتاه

const String amCaps = 'AM'; // نمایش وقت به صورت کامل

class SolarDate {
  SolarDate([String format]) {
    if (format != null) {
      _defaultVal = format;
    }

    _getNow = _now();
    _getDate = _now();
  }

  SolarDate.sDate({String defualtFormat, String gregorian}) {
    DateTime now;

    if (defualtFormat != null) {
      _defaultVal = defualtFormat;
    }

    if (gregorian != null) {
      now = DateTime.parse(gregorian);
      final list = gregorianToSolar(now.year, now.month, now.day);
      setWeekday = now.weekday;
      setYear = list[0];
      setMonth = list[1];
      setDay = list[2];
      setHour = now.hour;
      setMinute = now.minute;
      setSecond = now.second;
      setMicrosecond = now.microsecond;
      setMillisecond = now.millisecond;
      _getDate = _toFormat(_defaultVal);
    } else {
      _getDate = _now();
    }
  }

  int _year;
  int _month;
  int _day;
  int _weekday;
  int _hour;
  int _minute;
  int _second;
  int _millisecond;
  int _microsecond;
  String _getDate = '';
  String _getNow = '';

  String _defaultVal = 'yyyy-mm-dd hh:nn:ss SSS';

  String get getDate => _getDate;

  String get getNow => _getNow;

  String _now() {
    final now = DateTime.now();
    final list = gregorianToSolar(now.year, now.month, now.day);
    setWeekday = now.weekday;
    setYear = list[0];
    setMonth = list[1];
    setDay = list[2];
    setHour = now.hour;
    setMinute = now.minute;
    setSecond = now.second;
    setMicrosecond = now.microsecond;
    setMillisecond = now.millisecond;

    return _toFormat(_defaultVal);
  }

  List<String> monthShort = const <String>[
    'فرو',
    'ارد',
    'خرد',
    'تیر',
    'مرد',
    'شهر',
    'مهر',
    'آبا',
    'آذر',
    'دی',
    'بهم',
    'اسفن'
  ];

  List<String> monthLong = const <String>[
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
    'اسفند'
  ];

  List<String> dayShort = const [
    'د',
    'س',
    'چ',
    'پ',
    'ج',
    'ش',
    'ی',
  ];

  List<String> dayLong = const [
    'دوشنبه',
    'سه شنبه',
    'چهارشنبه',
    'پنج شنبه',
    'جمعه',
    'شنبه',
    'یکشنبه',
  ];

  List<String> solarHoliday = [
    '0101',
    '0102',
    '0103',
    '0104',
    '0112',
    '0113',
    '0314',
    '0315',
    '1122',
    '1229',
  ];

  dynamic gregorianToSolar(int y, int m, int d, [String separator]) {
    final sumMonthDay = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    var jY = 0;
    var inY = y;
    if (inY > 1600) {
      jY = 979;
      inY -= 1600;
    } else {
      jY = 0;
      inY -= 621;
    }
    final gy = (m > 2) ? inY + 1 : inY;
    var day = (365 * inY) +
        ((gy + 3) ~/ 4) -
        ((gy + 99) ~/ 100) +
        ((gy + 399) ~/ 400) -
        80 +
        d +
        sumMonthDay[m - 1];
    jY += 33 * (day.round() / 12053).floor();
    day %= 12053;
    jY += 4 * (day.round() / 1461).floor();
    day %= 1461;
    jY += ((day.round() - 1) / 365).floor();
    if (day > 365) {
      day = (day - 1).round() % 365;
    }
    int jm;
    int jd;
    final days = day.toInt();
    if (days < 186) {
      jm = 1 + (days ~/ 31);
      jd = 1 + (days % 31);
    } else {
      jm = 7 + ((days - 186) ~/ 30);
      jd = 1 + (days - 186) % 30;
    }
    dynamic persionDate;
    if (separator == null) {
      persionDate = [jY, jm, jd];
    } else {
      persionDate = '$jY$separator$jm$separator$jd';
    }
    return persionDate;
  }

  dynamic solarToGregorian(int y, int m, int d, [String separator]) {
    int gY;
    var inY = y;
    if (inY > 979) {
      gY = 1600;
      inY -= 979;
    } else {
      gY = 621;
    }

    var days = (365 * inY) +
        ((inY / 33).floor() * 8) +
        (((inY % 33) + 3) / 4) +
        78 +
        d +
        (m < 7 ? (m - 1) * 31 : ((m - 7) * 30) + 186);
    gY += 400 * (days ~/ 146097);
    days %= 146097;
    if (days.floor() > 36524) {
      gY += 100 * (--days ~/ 36524);
      days %= 36524;
      if (days >= 365) {
        days++;
      }
    }
    gY += 4 * (days ~/ 1461);
    days %= 1461;
    gY += (days - 1) ~/ 365;

    if (days > 365) {
      days = (days - 1) % 365;
    }
    var gD = (days + 1).floor();
    final montDays = [
      0,
      31,
      if ((gY % 4 == 0 && gY % 100 != 0) || gY % 400 == 0) 29 else 28,
      31,
      30,
      31,
      30,
      31,
      31,
      30,
      31,
      30,
      31
    ];
    var i = 0;
    for (; i <= 12; i++) {
      if (gD <= montDays[i]) {
        break;
      }
      gD -= montDays[i];
    }
    dynamic gregorianDate;
    if (separator == null) {
      gregorianDate = [gY, i, gD];
    } else {
      gregorianDate = '$gY$separator$i$separator$gD';
    }
    return gregorianDate;
  }

  Object parse(String formattedString, [String separator]) {
    final parse = DateTime.parse(formattedString);
    if (separator == null) {
      final parseList = gregorianToSolar(parse.year, parse.month, parse.day);
      parseList.add(parse.hour);
      parseList.add(parse.minute);
      parseList.add(parse.second);
      return parseList;
    } else {
      return '${gregorianToSolar(parse.year, parse.month, parse.day, separator)} ${parse.hour}:${parse.minute}:${parse.second}';
    }
  }

  String get weekdayName => dayLong[weekday - 1];

  String get monthName => monthLong[month - 1];

  int get year => _year;

  // ignore: avoid_setters_without_getters
  set setYear(int value) => _year = value;

  int get month => _month;

  // ignore: avoid_setters_without_getters
  set setMonth(int value) => _month = value;

  int get day => _day;

  // ignore: avoid_setters_without_getters
  set setDay(int value) => _day = value;

  int get weekday => _weekday;

  // ignore: avoid_setters_without_getters
  set setWeekday(int value) => _weekday = value;

  int get hour => _hour;

  // ignore: avoid_setters_without_getters
  set setHour(int value) => _hour = value;

  int get minute => _minute;

  bool get isHoliday {
    if (weekday == 5) {
      return true;
    } else if (solarHoliday
            .contains('${_digits(month, 2)}${_digits(day, 2)}')) {
      return true;
    } else {
      return false;
    }
  }

  // ignore: avoid_setters_without_getters
  set setMinute(int value) => _minute = value;

  int get second => _second;

  // ignore: avoid_setters_without_getters
  set setSecond(int value) => _second = value;

  int get microsecond => _microsecond;

  // ignore: avoid_setters_without_getters
  set setMicrosecond(int value) {
    _microsecond = value;
  }

  int get millisecond => _millisecond;

  // ignore: avoid_setters_without_getters
  set setMillisecond(int value) => _millisecond = value;

  String _toFormat(String format) {
    var newFormat = format;
    if (newFormat.contains(yyyy)) {
      newFormat = newFormat.replaceFirst(yyyy, _digits(year, 4));
    }
    if (newFormat.contains(yy)) {
      newFormat = newFormat.replaceFirst(yy, _digits(year % 100, 2));
    }
    if (newFormat.contains(mm)) {
      newFormat = newFormat.replaceFirst(mm, _digits(month, 2));
    }
    if (newFormat.contains(m)) {
      newFormat = newFormat.replaceFirst(m, month.toString());
    }
    if (newFormat.contains(mmCaps)) {
      newFormat = newFormat.replaceFirst(mmCaps, monthLong[month - 1]);
    }
    if (newFormat.contains(M)) {
      newFormat = newFormat.replaceFirst(M, monthShort[month - 1]);
    }
    if (newFormat.contains(dd)) {
      newFormat = newFormat.replaceFirst(dd, _digits(day, 2));
    }
    if (newFormat.contains(d)) {
      newFormat = newFormat.replaceFirst(d, day.toString());
    }
    if (newFormat.contains(w)) {
      newFormat = newFormat.replaceFirst(w, ((day + 7) ~/ 7).toString());
    }
    if (newFormat.contains(dD)) {
      newFormat = newFormat.replaceFirst(dD, dayLong[weekday - 1]);
    }
    if (newFormat.contains(D)) {
      newFormat = newFormat.replaceFirst(D, dayShort[weekday - 1]);
    }
    if (newFormat.contains(hhCaps)) {
      newFormat = newFormat.replaceFirst(hhCaps, _digits(hour, 2));
    }
    if (newFormat.contains(H)) {
      newFormat = newFormat.replaceFirst(H, hour.toString());
    }
    if (newFormat.contains(hh)) {
      newFormat = newFormat.replaceFirst(hh, _digits(hour % 12, 2));
    }
    if (newFormat.contains(h)) {
      newFormat = newFormat.replaceFirst(h, (hour % 12).toString());
    }
    if (newFormat.contains(amCaps)) {
      newFormat = newFormat.replaceFirst(
          amCaps, hour < 12 ? 'قبل از ظهر' : 'بعد از ظهر');
    }
    if (newFormat.contains(am)) {
      newFormat = newFormat.replaceFirst(am, hour < 12 ? 'ق.ظ' : 'ب.ظ');
    }
    if (newFormat.contains(nn)) {
      newFormat = newFormat.replaceFirst(nn, _digits(minute, 2));
    }
    if (newFormat.contains(n)) {
      newFormat = newFormat.replaceFirst(n, minute.toString());
    }
    if (newFormat.contains(ss)) {
      newFormat = newFormat.replaceFirst(ss, _digits(second, 2));
    }
    if (newFormat.contains(s)) {
      newFormat = newFormat.replaceFirst(s, second.toString());
    }
    if (newFormat.contains(sss)) {
      newFormat = newFormat.replaceFirst(sss, _digits(millisecond, 3));
    }
    if (newFormat.contains(S)) {
      newFormat = newFormat.replaceFirst(S, millisecond.toString());
    }
    if (newFormat.contains(uuu)) {
      newFormat = newFormat.replaceFirst(uuu, _digits(microsecond, 2));
    }
    if (newFormat.contains(u)) {
      newFormat = newFormat.replaceFirst(u, microsecond.toString());
    }
    return newFormat;
  }

  String parseToFormat(String parseDate, [String format]) {
    final parse = DateTime.parse(parseDate);
    final jParse = gregorianToSolar(parse.year, parse.month, parse.day);
    format ??= _defaultVal;

    var newFormat = format;

    // print(parse.weekday);

    if (newFormat.contains(yyyy)) {
      newFormat = newFormat.replaceFirst(yyyy, _digits(jParse[0], 4));
    }
    if (newFormat.contains(yy)) {
      newFormat = newFormat.replaceFirst(yy, _digits(jParse[0] % 100, 2));
    }
    if (newFormat.contains(mm)) {
      newFormat = newFormat.replaceFirst(mm, _digits(jParse[1], 2));
    }
    if (newFormat.contains(m)) {
      newFormat = newFormat.replaceFirst(m, jParse[1].toString());
    }
    if (newFormat.contains(mmCaps)) {
      newFormat = newFormat.replaceFirst(mmCaps, monthLong[jParse[1] - 1]);
    }
    if (newFormat.contains(M)) {
      newFormat = newFormat.replaceFirst(M, monthShort[jParse[1] - 1]);
    }
    if (newFormat.contains(dd)) {
      newFormat = newFormat.replaceFirst(dd, jParse[2].toString());
    }
    if (newFormat.contains(d)) {
      newFormat = newFormat.replaceFirst(d, _digits(jParse[2], 2));
    }
    if (newFormat.contains(w)) {
      newFormat = newFormat.replaceFirst(w, ((jParse[2] + 7) ~/ 7).toString());
    }
    if (newFormat.contains(dD)) {
      newFormat = newFormat.replaceFirst(dD, dayLong[parse.weekday - 1]);
    }
    if (newFormat.contains(D)) {
      newFormat = newFormat.replaceFirst(D, dayShort[parse.weekday - 1]);
    }
    if (newFormat.contains(hhCaps)) {
      newFormat = newFormat.replaceFirst(hhCaps, _digits(parse.hour, 2));
    }
    if (newFormat.contains(H)) {
      newFormat = newFormat.replaceFirst(H, parse.hour.toString());
    }
    if (newFormat.contains(hh)) {
      newFormat = newFormat.replaceFirst(hh, _digits(parse.hour % 12, 2));
    }
    if (newFormat.contains(h)) {
      newFormat = newFormat.replaceFirst(h, (parse.hour % 12).toString());
    }
    if (newFormat.contains(amCaps)) {
      newFormat = newFormat.replaceFirst(
          amCaps, parse.hour < 12 ? 'قبل از ظهر' : 'بعد از ظهر');
    }
    if (newFormat.contains(am)) {
      newFormat = newFormat.replaceFirst(am, parse.hour < 12 ? 'ق.ظ' : 'ب.ظ');
    }
    if (newFormat.contains(nn)) {
      newFormat = newFormat.replaceFirst(nn, _digits(parse.minute, 2));
    }
    if (newFormat.contains(n)) {
      newFormat = newFormat.replaceFirst(n, parse.minute.toString());
    }
    if (newFormat.contains(ss)) {
      newFormat = newFormat.replaceFirst(ss, _digits(parse.second, 2));
    }
    if (newFormat.contains(s)) {
      newFormat = newFormat.replaceFirst(s, parse.second.toString());
    }
    if (newFormat.contains(sss)) {
      newFormat = newFormat.replaceFirst(sss, _digits(parse.millisecond, 3));
    }
    if (newFormat.contains(S)) {
      newFormat = newFormat.replaceFirst(S, parse.millisecond.toString());
    }
    if (newFormat.contains(uuu)) {
      newFormat = newFormat.replaceFirst(uuu, _digits(parse.microsecond, 2));
    }
    if (newFormat.contains(u)) {
      newFormat = newFormat.replaceFirst(u, parse.microsecond.toString());
    }
    return newFormat;
  }

  String _digits(int value, int length) {
    var ret = '$value';
    if (ret.length < length) {
      ret = '0' * (length - ret.length) + ret;
    }
    return ret;
  }
}
