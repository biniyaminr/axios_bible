/// Ethiopian (Ge'ez) calendar conversion.
///
/// The Ethiopian year has 12 months of 30 days plus Pagume, a 13th month of
/// 5 days (6 in a leap year). Its epoch sits 7-8 years behind the Gregorian
/// one: the new year (Meskerem 1) falls on 11 September, or 12 September in
/// the year before a Gregorian leap year.
library;

/// Julian Day Number offset of the Amete Mihret (year of mercy) era, the
/// civil Ethiopian era. Meskerem 1, 1 E.C. is JDN 1724221 = this + 365.
const int _epochOffset = 1723856;

/// Ethiopian month names in Amharic, Meskerem (1) through Pagume (13).
const List<String> ethiopianMonthsAm = [
  'መስከረም',
  'ጥቅምት',
  'ኅዳር',
  'ታኅሣሥ',
  'ጥር',
  'የካቲት',
  'መጋቢት',
  'ሚያዝያ',
  'ግንቦት',
  'ሰኔ',
  'ሐምሌ',
  'ነሐሴ',
  'ጳጉሜን',
];

/// Ethiopian month names transliterated, for the English UI.
const List<String> ethiopianMonthsEn = [
  'Meskerem',
  'Tikimt',
  'Hidar',
  'Tahsas',
  'Tir',
  'Yekatit',
  'Megabit',
  'Miyazia',
  'Ginbot',
  'Sene',
  'Hamle',
  'Nehase',
  'Pagume',
];

/// Weekday names in Amharic, indexed by [DateTime.weekday] (1 = Monday).
const List<String> ethiopianWeekdaysAm = [
  'ሰኞ',
  'ማክሰኞ',
  'ረቡዕ',
  'ሐሙስ',
  'ዓርብ',
  'ቅዳሜ',
  'እሑድ',
];

/// A date in the Ethiopian calendar.
class EthiopianDate {
  final int year;

  /// 1..13, where 13 is Pagume.
  final int month;

  /// 1..30 (1..5 or 1..6 in Pagume).
  final int day;

  const EthiopianDate(this.year, this.month, this.day);

  /// Converts a Gregorian date to its Ethiopian equivalent.
  factory EthiopianDate.fromGregorian(DateTime date) =>
      _fromJdn(_gregorianToJdn(date.year, date.month, date.day));

  static EthiopianDate _fromJdn(int jdn) {
    // Unwind the 1461-day (4-year) cycle: three 365-day years followed by a
    // 366-day one. The r == 1460 case is Pagume 6, which the ~/1460 terms
    // fold back into the preceding year rather than starting a new one.
    final elapsed = jdn - _epochOffset;
    final r = elapsed % 1461;
    final n = (r % 365) + 365 * (r ~/ 1460);
    final year = 4 * (elapsed ~/ 1461) + (r ~/ 365) - (r ~/ 1460);
    final month = (n ~/ 30) + 1;
    final day = (n % 30) + 1;
    return EthiopianDate(year, month, day);
  }

  /// True in the year before a Gregorian leap year, when Pagume has 6 days.
  bool get isLeapYear => year % 4 == 3;

  int get daysInMonth => month == 13 ? (isLeapYear ? 6 : 5) : 30;

  /// Converts back to the Gregorian calendar.
  DateTime toGregorian() {
    final jdn =
        _epochOffset +
        365 +
        365 * (year - 1) +
        year ~/ 4 +
        30 * month +
        day -
        31;
    return _jdnToGregorian(jdn);
  }

  /// e.g. "ሐምሌ 8 ቀን 2018 ዓ.ም" (Amharic) or "Hamle 8, 2018 E.C." (English).
  String format({bool amharic = true}) {
    final name = amharic
        ? ethiopianMonthsAm[month - 1]
        : ethiopianMonthsEn[month - 1];
    return amharic ? '$name $day ቀን $year ዓ.ም' : '$name $day, $year E.C.';
  }

  @override
  String toString() => '$year-$month-$day';

  @override
  bool operator ==(Object other) =>
      other is EthiopianDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);
}

/// Gregorian calendar date -> Julian Day Number.
int _gregorianToJdn(int year, int month, int day) {
  final a = (14 - month) ~/ 12;
  final y = year + 4800 - a;
  final m = month + 12 * a - 3;
  return day +
      (153 * m + 2) ~/ 5 +
      365 * y +
      y ~/ 4 -
      y ~/ 100 +
      y ~/ 400 -
      32045;
}

/// Julian Day Number -> Gregorian calendar date.
DateTime _jdnToGregorian(int jdn) {
  final a = jdn + 32044;
  final b = (4 * a + 3) ~/ 146097;
  final c = a - (146097 * b) ~/ 4;
  final d = (4 * c + 3) ~/ 1461;
  final e = c - (1461 * d) ~/ 4;
  final m = (5 * e + 2) ~/ 153;
  final day = e - (153 * m + 2) ~/ 5 + 1;
  final month = m + 3 - 12 * (m ~/ 10);
  final year = 100 * b + d - 4800 + (m ~/ 10);
  return DateTime(year, month, day);
}
