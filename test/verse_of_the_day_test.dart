import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:amharic_bible/bible_provider.dart';
import 'package:amharic_bible/user_data_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await UserDataStore.instance.reset();
  });

  // The daily verse rotates through 8 curated references by date seed, so a
  // broken book lookup only surfaces on the days that pick it. Assert every
  // curated verse resolves in both bundled translations instead of waiting.
  for (final translation in ['am_1954', 'en_kjv']) {
    test('every daily verse resolves in $translation', () async {
      final provider = BibleProvider();
      await provider.init();
      await provider.changeTranslation(translation);

      for (final ref in provider.dailyVerseRefs) {
        final resolved = provider.dailyVerseFor(ref);
        expect(
          resolved['text'],
          isNot('Verse not found'),
          reason:
              '${ref['book']} ${ref['chapter']}:${ref['verse']} '
              'did not resolve in $translation',
        );
        expect(resolved['text']!.trim(), isNotEmpty);
        // The reference must display the translation's own book name.
        expect(provider.currentBible.containsKey(resolved['book']), isTrue);
      }
    });
  }

  test('Amharic Psalms resolves to መዝሙረ ዳዊት, not a substring miss', () async {
    final provider = BibleProvider();
    await provider.init();
    await provider.changeTranslation('am_1954');

    final psalm = provider.dailyVerseFor(const {
      'book': 'Psalms',
      'chapter': '23',
      'verse': '1',
    });

    expect(psalm['book'], 'መዝሙረ ዳዊት');
    expect(psalm['text'], isNot('Verse not found'));
    expect(psalm['reference'], startsWith('መዝሙረ ዳዊት 23:1'));
  });
}
