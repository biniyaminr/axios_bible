import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amharic_bible/bible_games.dart' show dateKey;
import 'package:amharic_bible/bible_provider.dart';
import 'package:amharic_bible/l10n/app_localizations.dart';
import 'package:amharic_bible/prayer_moment_screen.dart';
import 'package:amharic_bible/prayer_provider.dart';

// Like search_back_test: no sqflite setup on purpose — the providers catch
// and log the missing-database errors, and wiring the real store into
// widget tests deadlocks (see repo gotchas).

Widget _wrap(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => BibleProvider()),
      ChangeNotifierProvider(create: (_) => PrayerProvider()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('shouldShowPrayerMoment: once per day and only when enabled', () async {
    expect(await shouldShowPrayerMoment(false), false);
    expect(await shouldShowPrayerMoment(true), true);

    await markPrayerMomentSeen();
    expect(await shouldShowPrayerMoment(true), false);

    // A stale date from yesterday shows again.
    SharedPreferences.setMockInitialValues({
      'prayer_moment_last_date': dateKey(
        DateTime.now().subtract(const Duration(days: 1)),
      ),
    });
    expect(await shouldShowPrayerMoment(true), true);
  });

  testWidgets('Amen dismisses the Prayer Moment and marks it seen', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const PrayerMomentScreen()));
    await tester.pump();

    expect(find.text('Amen'), findsOneWidget);

    await tester.tap(find.text('Amen'));
    // Allow the async mark + pop to complete without waiting on the
    // repeating breathing animation.
    await tester.pump(const Duration(milliseconds: 50));

    expect(await shouldShowPrayerMoment(true), false);
  });
}
