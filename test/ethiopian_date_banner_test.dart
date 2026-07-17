import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_bible/ethiopian_date_banner.dart';
import 'package:amharic_bible/l10n/app_localizations.dart';

Widget _wrap(Locale locale, DateTime date) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: locale,
  home: Scaffold(body: EthiopianDateBanner(date: date)),
);

void main() {
  testWidgets('shows the Ge\'ez date in Amharic with weekday', (tester) async {
    // 15 July 2026 is a Wednesday -> ረቡዕ, Hamle 8 2018 E.C.
    await tester.pumpWidget(_wrap(const Locale('am'), DateTime(2026, 7, 15)));
    await tester.pump();

    expect(find.text('ረቡዕ • ሐምሌ 8 ቀን 2018 ዓ.ም'), findsOneWidget);
  });

  testWidgets('transliterates the date for the English UI', (tester) async {
    await tester.pumpWidget(_wrap(const Locale('en'), DateTime(2026, 7, 15)));
    await tester.pump();

    expect(find.text('Hamle 8, 2018 E.C.'), findsOneWidget);
    // The Gregorian line stays alongside it.
    expect(find.textContaining('2026'), findsOneWidget);
  });
}
