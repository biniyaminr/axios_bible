import 'dart:ui' show Locale;

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:amharic_bible/book_catalog.dart';
import 'package:amharic_bible/bible_provider.dart';
import 'package:amharic_bible/l10n/app_localizations.dart';
import 'package:amharic_bible/prayer_provider.dart';
import 'package:amharic_bible/reading_plans.dart';
import 'package:amharic_bible/user_data_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // Let unawaited writes from the previous test's provider drain before
    // wiping the DB, then start each test from a clean slate.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await UserDataStore.instance.reset();
  });

  test('loads translation catalog from bundled manifest', () async {
    final provider = BibleProvider();
    await provider.loadTranslationCatalog();

    expect(provider.availableTranslations.length, greaterThan(100));

    final ids = provider.availableTranslations.map((v) => v.id).toSet();
    expect(
      ids.length,
      provider.availableTranslations.length,
      reason: 'translation ids must be unique',
    );
  });

  test('loads default Amharic and KJV bibles offline', () async {
    final provider = BibleProvider();
    await provider.init();

    expect(provider.isLoading, false);
    expect(provider.error, isNull);
    expect(provider.books.length, 66);
    expect(provider.verses, isNotEmpty);

    // Switching between the two defaults keeps the book position by index.
    await provider.changeTranslation('en_kjv');
    expect(provider.currentTranslation.id, 'en_kjv');
    expect(provider.verses, isNotEmpty);
  });

  test('installs a bundled translation from the store and reads it', () async {
    final provider = BibleProvider();
    await provider.init();

    final bsb = provider.availableTranslations.firstWhere((v) => v.id == 'BSB');
    expect(provider.isInstalled(bsb), false);

    await provider.downloadTranslation(bsb);
    expect(provider.isInstalled(bsb), true);

    await provider.changeTranslation('BSB');
    expect(provider.currentTranslation.id, 'BSB');
    expect(provider.verses, isNotEmpty);

    // Uninstalling switches back to the Amharic default.
    await provider.removeTranslation(bsb);
    expect(provider.isInstalled(bsb), false);
    expect(provider.currentTranslation.id, 'am_1954');
  });

  test('search finds verses in the current translation', () async {
    final provider = BibleProvider();
    await provider.init();
    await provider.changeTranslation('en_kjv');

    final results = provider.searchBible('In the beginning God created');
    expect(results, isNotEmpty);
    expect(results.first['book'], 'Genesis');
  });

  test('resolveBookId maps English, Amharic, and roman-numeral names', () {
    expect(resolveBookId('Genesis'), 'GEN');
    expect(resolveBookId('ኦሪት ዘፍጥረት'), 'GEN');
    expect(resolveBookId('የማቴዎስ ወንጌል'), 'MAT');
    expect(resolveBookId('Matthew'), 'MAT');
    expect(resolveBookId('I Samuel'), '1SA');
    expect(resolveBookId('1 Samuel'), '1SA');
    expect(resolveBookId('መጽሐፈ ነገሥት ቀዳማዊ።'), '1KI');
    expect(resolveBookId('Revelation of John'), 'REV');
    expect(resolveBookId('የዮሐንስ ራእይ'), 'REV');
    expect(resolveBookId('Some Unknown Book'), isNull);
  });

  test(
    'switching to a translation with Apocrypha keeps the same book',
    () async {
      final provider = BibleProvider();
      await provider.init();

      // Open Matthew in Amharic (book index 39 of 66).
      provider.selectBook('የማቴዎስ ወንጌል');
      provider.selectChapter(5);

      // KJVA has 80 books; index 39 is "I Esdras". Canonical mapping must
      // land on Matthew instead.
      final kjva = provider.availableTranslations.firstWhere(
        (v) => v.id == 'KJVA',
      );
      await provider.downloadTranslation(kjva);
      await provider.changeTranslation('KJVA');

      expect(resolveBookId(provider.selectedBook), 'MAT');
      expect(provider.selectedChapter, 5);
      expect(provider.verses, isNotEmpty);

      // And back: Amharic should return to Matthew, not a shifted book.
      await provider.changeTranslation('am_1954');
      expect(provider.selectedBook, 'የማቴዎስ ወንጌል');
    },
  );

  test('reading progress is recorded when chapters are opened', () async {
    final provider = BibleProvider();
    await provider.init();

    final book = provider.books.first;
    provider.selectBook(book);
    provider.selectChapter(1);

    expect(provider.readChapters.contains('${book}_1'), true);
    expect(provider.getBookProgress(book, 50), greaterThan(0));
  });

  test(
    'notes, highlights, and bookmarks persist across store reloads',
    () async {
      final store = UserDataStore.instance;

      final id = await store.insertNote({
        'reference': 'Genesis_1_1',
        'text': 'In the beginning',
        'userNote': 'My first note',
        'category': 'Personal',
        'timestamp': DateTime.now().toIso8601String(),
      });
      await store.setHighlight('Genesis_1_1', 0xFFFFD700);
      final bookmarkId = await store.insertBookmark({
        'book': 'Genesis',
        'chapter': 1,
        'verseNum': '1',
        'text': 'In the beginning',
      });
      await store.addReadChapter('Genesis_1');

      final notes = await store.loadNotes();
      expect(notes.single['userNote'], 'My first note');
      expect(notes.single['id'], id);

      expect(await store.loadHighlights(), {'Genesis_1_1': 0xFFFFD700});
      final bookmarks = await store.loadBookmarks();
      expect(bookmarks.single['id'], bookmarkId);
      expect(await store.loadReadChapters(), {'Genesis_1'});

      await store.deleteNote(id);
      await store.deleteBookmark(bookmarkId);
      await store.removeHighlight('Genesis_1_1');
      expect(await store.loadNotes(), isEmpty);
      expect(await store.loadBookmarks(), isEmpty);
      expect(await store.loadHighlights(), isEmpty);
    },
  );

  test('UI localizations resolve for English and Amharic', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final am = lookupAppLocalizations(const Locale('am'));

    expect(en.navBible, 'Bible');
    expect(am.navBible, 'መጽሐፍ ቅዱስ');
    expect(en.chapterLabel(5), 'Chapter 5');
    expect(am.chapterLabel(5), 'ምዕራፍ 5');
    expect(am.translationsSummary(142, 4), contains('142'));

    // Reminder strings exist in both languages.
    expect(en.dailyReminder, isNotEmpty);
    expect(am.dailyReminder, isNotEmpty);
    expect(en.reminderNotificationTitle, isNotEmpty);
    expect(am.reminderNotificationBody, isNotEmpty);
    expect(en.notificationsDenied, isNotEmpty);
  });

  test('prayer list persists, answers, and deletes', () async {
    final prayers = PrayerProvider();
    await prayers.addPrayer('  For my family  ');
    await prayers.addPrayer('For Ethiopia');
    await prayers.addPrayer('   '); // whitespace-only is ignored

    expect(prayers.active.length, 2);
    expect(prayers.answered, isEmpty);
    // Newest first, and text is trimmed.
    expect(prayers.active.first.text, 'For Ethiopia');
    expect(prayers.active.last.text, 'For my family');

    final id = prayers.active.first.id;
    await prayers.setAnswered(id, true);
    expect(prayers.active.length, 1);
    expect(prayers.answered.single.id, id);
    expect(prayers.answered.single.answeredAt, isNotNull);

    // Un-answering moves it back to active.
    await prayers.setAnswered(id, false);
    expect(prayers.active.length, 2);

    await prayers.deletePrayer(id);
    expect(prayers.active.length, 1);

    // Survives a fresh provider (reload from SQLite).
    final reloaded = PrayerProvider();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(reloaded.active.single.text, 'For my family');
  });

  test('user_data.db upgrades from v2 to v3 keeping existing data', () async {
    // Recreate the schema an existing user has (v2: no prayers table).
    final path = p.join(await getDatabasesPath(), 'user_data.db');
    final v2 = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE notes(id INTEGER PRIMARY KEY '
          'AUTOINCREMENT, reference TEXT NOT NULL, text TEXT NOT NULL '
          "DEFAULT '', user_note TEXT NOT NULL, category TEXT NOT NULL "
          "DEFAULT 'Personal', timestamp TEXT NOT NULL)",
        );
        await db.execute(
          'CREATE TABLE highlights(verse_key TEXT PRIMARY KEY, color INTEGER '
          'NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE bookmarks(id INTEGER PRIMARY KEY '
          'AUTOINCREMENT, book TEXT NOT NULL, chapter INTEGER NOT NULL, '
          "verse_num TEXT NOT NULL, text TEXT NOT NULL DEFAULT '')",
        );
        await db.execute(
          'CREATE TABLE read_chapters(chapter_key TEXT '
          'PRIMARY KEY)',
        );
        await db.execute(
          'CREATE TABLE started_plans(plan_id TEXT PRIMARY KEY, '
          'started_at TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE plan_progress(plan_id TEXT NOT NULL, '
          'day INTEGER NOT NULL, completed_at TEXT NOT NULL, '
          'PRIMARY KEY(plan_id, day))',
        );
      },
    );
    await v2.insert('read_chapters', {'chapter_key': 'Genesis_1'});
    await v2.close();

    // Opening through the store runs onUpgrade and adds the prayers table.
    final store = UserDataStore.instance;
    expect(await store.loadReadChapters(), {'Genesis_1'});
    final id = await store.insertPrayer('For wisdom', DateTime.now());
    expect((await store.loadPrayers()).single['id'], id);
  });

  test(
    'NASV (modern Amharic) installs, reads, and has the Great Commission',
    () async {
      final provider = BibleProvider();
      await provider.init();

      final nasv = provider.availableTranslations.firstWhere(
        (v) => v.id == 'NASV',
      );
      expect(nasv.isBundled, true);
      expect(nasv.name, 'አዲሱ መደበኛ ትርጉም');

      await provider.downloadTranslation(nasv);
      await provider.changeTranslation('NASV');
      expect(provider.currentTranslation.id, 'NASV');
      expect(provider.books.length, 66);

      // Book keys reuse the 1954 titles, so canonical mapping works.
      provider.selectBook('የማቴዎስ ወንጌል');
      provider.selectChapter(28);
      expect(provider.verses.length, 20);

      // Matthew 28:19 is empty in the bundled 1954 data but must exist here.
      final bible = provider.currentBible;
      final v19 = bible['የማቴዎስ ወንጌል']?['28']?['19'] as String?;
      expect(v19, isNotNull);
      expect(v19!.trim(), isNotEmpty);

      // Every curated daily verse must resolve in the new translation too.
      for (final ref in provider.dailyVerseRefs) {
        final v = provider.dailyVerseFor(ref);
        expect(
          v['text'],
          isNot('Verse not found'),
          reason:
              '${ref['book']} ${ref['chapter']}:${ref['verse']} '
              'missing in NASV',
        );
        expect(v['text']!.trim(), isNotEmpty);
      }
    },
  );

  test('every curated daily verse resolves in both bundled defaults', () async {
    final provider = BibleProvider();
    await provider.init();

    for (final translation in ['am_1954', 'en_kjv']) {
      await provider.changeTranslation(translation);
      for (final ref in provider.dailyVerseRefs) {
        final v = provider.dailyVerseFor(ref);
        expect(
          v['text'],
          isNot('Verse not found'),
          reason:
              '${ref['book']} ${ref['chapter']}:${ref['verse']} missing in '
              '$translation',
        );
        expect(v['text']!.trim(), isNotEmpty);
      }
    }
  });

  test('verse of the day is deterministic per date', () async {
    final provider = BibleProvider();
    await provider.init();

    final date = DateTime(2026, 7, 16);
    final a = provider.verseOfTheDayFor(date);
    final b = provider.verseOfTheDayFor(date);
    expect(a['reference'], b['reference']);
    expect(a['text'], isNot('Verse not found'));

    // A week of verses is what gets scheduled as notifications — each day
    // must produce a non-empty verse.
    for (var i = 0; i < 7; i++) {
      final v = provider.verseOfTheDayFor(date.add(Duration(days: i)));
      expect(v['text']!.trim(), isNotEmpty);
      expect(v['reference'], isNot('...'));
    }
  });

  test(
    'verse-of-day notification settings default off at 6:30 and update',
    () async {
      final provider = BibleProvider();
      expect(provider.votdEnabled, false);
      expect(provider.votdTime, const TimeOfDay(hour: 6, minute: 30));

      final enabled = await provider.setVotdEnabled(true);
      expect(enabled, true);
      expect(provider.votdEnabled, true);

      await provider.setVotdTime(const TimeOfDay(hour: 5, minute: 45));
      expect(provider.votdTime, const TimeOfDay(hour: 5, minute: 45));

      await provider.setVotdEnabled(false);
      expect(provider.votdEnabled, false);
    },
  );

  test('openSavedReference resolves bookmarks across translations', () async {
    final provider = BibleProvider();
    await provider.init();

    // Bookmark saved while reading Amharic…
    expect(provider.openSavedReference('የማቴዎስ ወንጌል', 5), true);

    // …still opens after switching to KJV (raw key no longer exists).
    await provider.changeTranslation('en_kjv');
    expect(provider.currentBible.containsKey('የማቴዎስ ወንጌል'), false);
    expect(provider.openSavedReference('የማቴዎስ ወንጌል', 5), true);
    expect(provider.selectedBook, 'Matthew');
    expect(provider.selectedChapter, 5);

    // Unknown book name fails without changing the selection.
    expect(provider.openSavedReference('Nonsense Book', 3), false);
    expect(provider.selectedBook, 'Matthew');
  });

  test('recent searches persist, dedupe, and cap at 8', () async {
    final provider = BibleProvider();
    await provider.loadRecentSearches();
    expect(provider.recentSearches, isEmpty);

    for (var i = 1; i <= 10; i++) {
      await provider.addRecentSearch('query $i');
    }
    await provider.addRecentSearch('query 9'); // duplicate moves to front
    await provider.addRecentSearch('   '); // blank ignored

    expect(provider.recentSearches.length, 8);
    expect(provider.recentSearches.first, 'query 9');
    expect(provider.recentSearches.contains('query 1'), false);

    // Round-trips through SharedPreferences.
    final reloaded = BibleProvider();
    await reloaded.loadRecentSearches();
    expect(reloaded.recentSearches, provider.recentSearches);
  });

  test('daily reminder settings default off at 7:00 and update', () async {
    final provider = BibleProvider();
    expect(provider.reminderEnabled, false);
    expect(provider.reminderTime, const TimeOfDay(hour: 7, minute: 0));

    // Without a notification backend (unit test) enabling still succeeds —
    // the service treats "no platform" as granted.
    final enabled = await provider.setReminderEnabled(true);
    expect(enabled, true);
    expect(provider.reminderEnabled, true);

    await provider.setReminderTime(const TimeOfDay(hour: 20, minute: 30));
    expect(provider.reminderTime, const TimeOfDay(hour: 20, minute: 30));

    await provider.setReminderEnabled(false);
    expect(provider.reminderEnabled, false);
  });

  test('built-in reading plans cover every chapter exactly once', () {
    final bibleYear = builtInPlans.firstWhere((p) => p.id == 'bible_in_a_year');
    expect(bibleYear.totalDays, 365);

    final all = bibleYear.schedule.expand((d) => d).toList();
    final totalChapters = canonicalBooks.fold<int>(0, (sum, b) => sum + b.$2);
    expect(all.length, totalChapters); // 1,189 chapters
    expect(
      all.map((r) => '${r.bookId}_${r.chapter}').toSet().length,
      totalChapters,
    );
    // Starts at Genesis 1, ends at Revelation 22.
    expect(all.first.bookId, 'GEN');
    expect(all.first.chapter, 1);
    expect(all.last.bookId, 'REV');
    expect(all.last.chapter, 22);
    // Every day has at least one reading.
    expect(bibleYear.schedule.every((d) => d.isNotEmpty), true);

    final proverbs = builtInPlans.firstWhere((p) => p.id == 'proverbs_31');
    expect(proverbs.totalDays, 31);
    expect(proverbs.schedule.every((d) => d.length == 1), true);
  });

  test('plan progress and streak persist through the store', () async {
    final plans = ReadingPlanProvider();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await plans.startPlan('gospels_30');
    await plans.toggleDay('gospels_30', 0);
    await plans.toggleDay('gospels_30', 1);

    expect(plans.isStarted('gospels_30'), true);
    expect(plans.completedDays('gospels_30'), {0, 1});
    expect(
      plans.currentDay(builtInPlans.firstWhere((p) => p.id == 'gospels_30')),
      2,
    );
    expect(plans.streak, 1); // both completions happened today

    // A fresh provider reloads the same state from SQLite.
    final reloaded = ReadingPlanProvider();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(reloaded.isStarted('gospels_30'), true);
    expect(reloaded.completedDays('gospels_30'), {0, 1});

    // Unchecking removes the day.
    await plans.toggleDay('gospels_30', 1);
    expect(plans.completedDays('gospels_30'), {0});
  });

  test('streak counts consecutive days ending today or yesterday', () {
    final plans = ReadingPlanProvider();
    final now = DateTime.now();
    DateTime daysAgo(int n) => now.subtract(Duration(days: n));

    plans.completionDatesForTest = [now, daysAgo(1), daysAgo(2)];
    expect(plans.streak, 3);

    plans.completionDatesForTest = [daysAgo(1), daysAgo(2)];
    expect(plans.streak, 2); // survives until the end of today

    plans.completionDatesForTest = [daysAgo(2), daysAgo(3)];
    expect(plans.streak, 0); // broken

    plans.completionDatesForTest = [];
    expect(plans.streak, 0);
  });

  test(
    'openReading jumps to a plan reading in the current translation',
    () async {
      final provider = BibleProvider();
      await provider.init();

      // Amharic is active; MAT should resolve to የማቴዎስ ወንጌል.
      expect(provider.openReading('MAT', 5), true);
      expect(provider.selectedBook, 'የማቴዎስ ወንጌል');
      expect(provider.selectedChapter, 5);
      expect(provider.bookNameForId('MAT'), 'የማቴዎስ ወንጌል');

      // Unknown book falls back gracefully.
      expect(provider.openReading('XYZ', 1), false);
      expect(provider.bookNameForId('GEN'), 'ኦሪት ዘፍጥረት');
    },
  );

  test('legacy SharedPreferences data migrates into SQLite once', () async {
    SharedPreferences.setMockInitialValues({
      'journal_notes':
          '[{"reference":"Genesis_1_1","text":"v","userNote":"old note",'
          '"category":"Sermon","timestamp":"2025-01-01T00:00:00.000"}]',
      'read_chapters': ['Genesis_1', 'Exodus_2'],
    });
    await UserDataStore.instance.reset();

    final notes = await UserDataStore.instance.loadNotes();
    expect(notes.single['userNote'], 'old note');
    expect(notes.single['category'], 'Sermon');
    expect(await UserDataStore.instance.loadReadChapters(), {
      'Genesis_1',
      'Exodus_2',
    });

    // Old keys are cleaned up and the migration doesn't run twice.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('journal_notes'), isNull);
    expect(prefs.getStringList('read_chapters'), isNull);
    expect(prefs.getBool('sqlite_migrated_v1'), true);
  });
}
