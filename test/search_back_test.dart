import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amharic_bible/bible_provider.dart';
import 'package:amharic_bible/l10n/app_localizations.dart';
import 'package:amharic_bible/search_screen.dart';

// These tests only exercise the AppBar, so they deliberately do not set up
// sqflite: BibleProvider's constructor fires unawaited store reads that are
// caught and logged when no databaseFactory exists. Wiring the real store up
// here and resetting it between tests deadlocks the second test.

Widget _wrap(Widget child, BibleProvider provider) {
  return ChangeNotifierProvider<BibleProvider>.value(
    value: provider,
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

  testWidgets('Search shows a back button that invokes onBack', (tester) async {
    var backPressed = 0;
    await tester.pumpWidget(
      _wrap(SearchScreen(onBack: () => backPressed++), BibleProvider()),
    );
    await tester.pump();

    // Search is a tab in an IndexedStack: nothing to pop, so the AppBar will
    // not supply a back button on its own.
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();

    expect(backPressed, 1);
  });

  testWidgets('Search omits the back button when no handler is given', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const SearchScreen(), BibleProvider()));
    await tester.pump();

    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });
}
