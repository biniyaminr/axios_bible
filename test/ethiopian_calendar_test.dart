import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_bible/ethiopian_calendar.dart';

void main() {
  group('Gregorian -> Ethiopian', () {
    // Anchor dates verified against the Ethiopian civil calendar.
    final cases = <DateTime, EthiopianDate>{
      // Ethiopian new year (Meskerem 1) falls on 11 Sept in a common year.
      DateTime(2026, 9, 11): const EthiopianDate(2019, 1, 1),
      // ...and on 12 Sept in the year preceding a Gregorian leap year.
      DateTime(2027, 9, 12): const EthiopianDate(2020, 1, 1),
      // Ethiopian Christmas (Gena), Tahsas 29.
      DateTime(2027, 1, 7): const EthiopianDate(2019, 4, 29),
      // Millennium: 1 Meskerem 2000.
      DateTime(2007, 9, 12): const EthiopianDate(2000, 1, 1),
      DateTime(2026, 7, 15): const EthiopianDate(2018, 11, 8),
    };

    cases.forEach((gregorian, ethiopian) {
      test('${gregorian.toIso8601String().split('T').first} -> $ethiopian', () {
        expect(EthiopianDate.fromGregorian(gregorian), ethiopian);
      });
    });
  });

  test('round-trips every day across a four-year leap cycle', () {
    var date = DateTime(2024, 1, 1);
    final end = DateTime(2028, 1, 1);
    while (date.isBefore(end)) {
      final ethiopian = EthiopianDate.fromGregorian(date);
      expect(
        ethiopian.toGregorian(),
        date,
        reason: '$date round-tripped through $ethiopian',
      );
      // Month/day must always be in range.
      expect(ethiopian.month, inInclusiveRange(1, 13));
      expect(ethiopian.day, inInclusiveRange(1, ethiopian.daysInMonth));
      date = date.add(const Duration(days: 1));
    }
  });

  test('Pagume has 6 days only before a Gregorian leap year', () {
    // 2019 E.C. precedes Gregorian 2028 (leap), so Pagume 6 exists.
    expect(const EthiopianDate(2019, 13, 1).isLeapYear, isTrue);
    expect(const EthiopianDate(2019, 13, 1).daysInMonth, 6);
    expect(const EthiopianDate(2018, 13, 1).daysInMonth, 5);
  });

  test('formats in Amharic and English', () {
    final d = EthiopianDate.fromGregorian(DateTime(2026, 7, 15));
    expect(d.format(), 'ሐምሌ 8 ቀን 2018 ዓ.ም');
    expect(d.format(amharic: false), 'Hamle 8, 2018 E.C.');
  });
}
