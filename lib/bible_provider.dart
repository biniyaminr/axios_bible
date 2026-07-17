import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bible_version.dart';
import 'book_catalog.dart';
import 'l10n/app_localizations.dart';
import 'notification_service.dart';
import 'user_data_store.dart';

export 'bible_version.dart';

/// State management for Bible data and user selections
class BibleProvider extends ChangeNotifier {
  final List<BibleVersion> _availableTranslations = [
    BibleVersion(
      id: 'am_1954',
      name: 'Amharic 1954',
      shortName: 'AM',
      filename: 'amharic_bible.json',
      isBundled: true,
    ),
    BibleVersion(
      id: 'en_kjv',
      name: 'English KJV',
      shortName: 'KJV',
      filename: 'english_kjv_bible.json',
      isBundled: true,
    ),
  ];

  /// Ids of translations the user has added from the Translation Store.
  /// The two defaults are always available and are not tracked here.
  List<String> installedTranslations = [];
  Set<String> downloadingVersions = {};
  String _selectedVersionId = 'am_1954';
  String? _parallelVersionId;

  bool get isEnglishToggle => _selectedVersionId != 'am_1954';

  String _selectedBook = '';
  int _selectedChapter = 1;
  bool _isLoading = true;
  String? _error;

  // Selection State
  final Set<String> _selectedVerses = {};

  // Active Search State (TOTAL ALIGNMENT)
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> get searchResults => _searchResults;

  String _currentSearchQuery = "";
  String get currentSearchQuery => _currentSearchQuery;

  // Flattening mechanism to act as 'currentVerses' inside performSearch
  List<Map<String, dynamic>> get currentVerses {
    List<Map<String, dynamic>> all = [];
    if (currentBible.isEmpty) return all;
    currentBible.forEach((bookName, bookContent) {
      if (bookContent is Map) {
        bookContent.forEach((chapterName, chapter) {
          final chapterNum = int.tryParse(chapterName.toString()) ?? 1;
          if (chapter is Map) {
            chapter.forEach((verseKey, verseValue) {
              if (verseValue != null &&
                  verseValue.toString().trim().isNotEmpty) {
                all.add({
                  'book': bookName,
                  'chapter': chapterNum.toString(),
                  'verse': verseKey.toString(),
                  'text': verseValue.toString(),
                });
              }
            });
          } else if (chapter is List) {
            for (int i = 0; i < chapter.length; i++) {
              if (chapter[i] != null &&
                  chapter[i].toString().trim().isNotEmpty) {
                int verseNum = chapter[0] == null ? i : (i + 1);
                all.add({
                  'book': bookName,
                  'chapter': chapterNum.toString(),
                  'verse': verseNum.toString(),
                  'text': chapter[i].toString(),
                });
              }
            }
          }
        });
      }
    });
    return all;
  }

  void performSearch(String query, {int filterIndex = 0}) {
    _currentSearchQuery = query;
    if (query.isEmpty) {
      _searchResults = [];
    } else {
      final lowerQuery = query.toLowerCase();

      _searchResults = currentVerses.where((verse) {
        final text = verse['text'].toString().toLowerCase();
        final chapter = verse['chapter'].toString().toLowerCase();
        final book = verse['book'].toString().toLowerCase();

        // 0=ጥቅሶች (Verses/Quotes), 1=ምዕራፎች (Chapters/Books), 2=ጽሑፎች (Topics/Texts)
        switch (filterIndex) {
          case 0:
            return text.contains(lowerQuery) ||
                verse['verse'].toString().toLowerCase().contains(lowerQuery);
          case 1:
            return chapter.contains(lowerQuery) || book.contains(lowerQuery);
          case 2:
            return text.contains(lowerQuery);
          default:
            return text.contains(lowerQuery);
        }
      }).toList();
    }
    notifyListeners();
  }

  void clearActiveSearchQuery() {
    _currentSearchQuery = "";
    _searchResults = [];
    notifyListeners();
  }

  // Highlights State
  Map<String, int> _highlights = {};

  // Bookmarks State
  List<Map<String, dynamic>> _bookmarks = [];

  // Daily Verses Curated List (66-book canon, standard versification so the
  // same reference resolves in every translation).
  final List<Map<String, String>> _dailyVerses = [
    {'book': 'Psalms', 'chapter': '23', 'verse': '1'},
    {'book': 'Jeremiah', 'chapter': '29', 'verse': '11'},
    {'book': 'John', 'chapter': '3', 'verse': '16'},
    {'book': 'Philippians', 'chapter': '4', 'verse': '13'},
    {'book': 'Proverbs', 'chapter': '3', 'verse': '5'},
    {'book': 'Isaiah', 'chapter': '41', 'verse': '10'},
    {'book': 'Matthew', 'chapter': '11', 'verse': '28'},
    {'book': 'Romans', 'chapter': '8', 'verse': '28'},
    {'book': 'Genesis', 'chapter': '1', 'verse': '1'},
    {'book': 'Joshua', 'chapter': '1', 'verse': '9'},
    {'book': 'Psalms', 'chapter': '46', 'verse': '1'},
    {'book': 'Psalms', 'chapter': '119', 'verse': '105'},
    {'book': 'Psalms', 'chapter': '121', 'verse': '1'},
    {'book': 'Proverbs', 'chapter': '18', 'verse': '10'},
    {'book': 'Isaiah', 'chapter': '40', 'verse': '31'},
    {'book': 'Isaiah', 'chapter': '53', 'verse': '5'},
    {'book': 'Lamentations', 'chapter': '3', 'verse': '22'},
    {'book': 'Micah', 'chapter': '6', 'verse': '8'},
    {'book': 'Zephaniah', 'chapter': '3', 'verse': '17'},
    {'book': 'Matthew', 'chapter': '5', 'verse': '16'},
    {'book': 'Matthew', 'chapter': '6', 'verse': '33'},
    {'book': 'Acts', 'chapter': '1', 'verse': '8'},
    {'book': 'Matthew', 'chapter': '28', 'verse': '19'},
    {'book': 'John', 'chapter': '1', 'verse': '1'},
    {'book': 'John', 'chapter': '8', 'verse': '32'},
    {'book': 'John', 'chapter': '14', 'verse': '6'},
    {'book': 'Romans', 'chapter': '5', 'verse': '8'},
    {'book': 'Romans', 'chapter': '10', 'verse': '9'},
    {'book': 'Romans', 'chapter': '12', 'verse': '2'},
    {'book': '1 Corinthians', 'chapter': '13', 'verse': '4'},
    {'book': '2 Corinthians', 'chapter': '5', 'verse': '17'},
    {'book': 'Galatians', 'chapter': '2', 'verse': '20'},
    {'book': 'Galatians', 'chapter': '5', 'verse': '22'},
    {'book': 'Ephesians', 'chapter': '2', 'verse': '8'},
    {'book': 'Philippians', 'chapter': '4', 'verse': '6'},
    {'book': 'Colossians', 'chapter': '3', 'verse': '23'},
    {'book': '2 Timothy', 'chapter': '1', 'verse': '7'},
    {'book': 'Hebrews', 'chapter': '11', 'verse': '1'},
    {'book': 'James', 'chapter': '1', 'verse': '5'},
    {'book': '1 Peter', 'chapter': '5', 'verse': '7'},
    {'book': '1 John', 'chapter': '4', 'verse': '19'},
  ];

  // Journal Notes State
  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> get notes => _notes;

  // Settings State
  ThemeMode _themeMode = ThemeMode.system;
  double _fontSize = 18.0;
  double _audioSpeed = 1.0;
  double _lineSpacing = 1.65;

  // Reading Progress State
  Set<String> _readChapters = {};
  Set<String> get readChapters => _readChapters;

  String? _lastReadBook;
  int? _lastReadChapter;

  String? get lastReadBook => _lastReadBook;
  int? get lastReadChapter => _lastReadChapter;

  void updateLastRead() {
    if (_selectedBook.isNotEmpty) {
      _lastReadBook = _selectedBook;
      _lastReadChapter = _selectedChapter;
      markChapterAsRead(_selectedBook, _selectedChapter);
      saveSettings();
    }
  }

  Future<void> loadReadChapters() async {
    try {
      _readChapters = await UserDataStore.instance.loadReadChapters();
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading read chapters: $e");
    }
  }

  void markChapterAsRead(String book, int chapter) async {
    final key = "${book}_$chapter";
    if (!_readChapters.contains(key)) {
      _readChapters.add(key);
      try {
        await UserDataStore.instance.addReadChapter(key);
      } catch (e) {
        debugPrint("Error saving read chapters: $e");
      }
      notifyListeners();
    }
  }

  double getBookProgress(String book, int totalChapters) {
    if (totalChapters <= 0) return 0.0;
    int readCount = 0;
    for (int i = 1; i <= totalChapters; i++) {
      if (_readChapters.contains("${book}_$i")) {
        readCount++;
      }
    }
    return readCount / totalChapters;
  }

  String getBookStatus(String book, int totalChapters) {
    final progress = getBookProgress(book, totalChapters);
    if (progress == 1.0) {
      return 'COMPLETED';
    } else if (progress > 0) {
      return 'IN PROGRESS';
    } else {
      return 'NOT STARTED';
    }
  }

  int getCollectionCompletionPercentage(
    List<Map<String, dynamic>> collectionBooks,
  ) {
    if (collectionBooks.isEmpty) return 0;
    int totalChaptersAvailable = 0;
    int totalChaptersRead = 0;

    for (var bookData in collectionBooks) {
      final String bookName = bookData['title'] as String;
      final int totalChapters = bookData['chapters'] as int;

      totalChaptersAvailable += totalChapters;
      for (int i = 1; i <= totalChapters; i++) {
        if (_readChapters.contains("${bookName}_$i")) {
          totalChaptersRead++;
        }
      }
    }

    if (totalChaptersAvailable == 0) return 0;
    return ((totalChaptersRead / totalChaptersAvailable) * 100).round();
  }

  BibleProvider() {
    loadSettings();
    loadHighlights();
    loadBookmarks();
    loadReadChapters();
    _loadNotes();
  }

  Future<void> init() async {
    await loadTranslationCatalog();
    await checkInstalledTranslations();
    await loadBibleData();
    await loadRecentSearches();

    // Auto-load the first chapter if the screen would be blank
    if (verses.isEmpty && books.isNotEmpty) {
      selectBook(books.first);
      selectChapter(1);
    }

    // Refresh the rolling week of verse-of-the-day notifications now that
    // the Bible text is available. Fire-and-forget.
    if (_votdEnabled) _scheduleVotd();
  }

  /// Loads the translation manifest and registers every catalog entry.
  /// Bundled entries ship in assets/bible_data/; remote entries are
  /// downloaded on demand from `remoteBaseUrl` + filename.
  Future<void> loadTranslationCatalog() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/bible_data/manifest.json',
      );
      final Map<String, dynamic> manifest = json.decode(raw);
      final List<dynamic> entries = manifest['translations'] ?? [];
      final remoteBaseUrl = manifest['remoteBaseUrl']?.toString() ?? '';
      final existingIds = _availableTranslations.map((v) => v.id).toSet();

      for (final entry in entries) {
        final id = entry['id']?.toString();
        if (id == null || existingIds.contains(id)) continue;
        final filename = entry['filename']?.toString() ?? '$id.json';
        final isBundled = entry['bundled'] == true;
        _availableTranslations.add(
          BibleVersion(
            id: id,
            name: entry['name']?.toString() ?? id,
            shortName: entry['shortName']?.toString() ?? id,
            filename: filename,
            isBundled: isBundled,
            downloadUrl: isBundled ? '' : '$remoteBaseUrl$filename',
          ),
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading translation manifest: $e");
    }
  }

  Future<void> checkInstalledTranslations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      installedTranslations =
          prefs.getStringList('installed_translations') ?? [];
      notifyListeners();
    } catch (e) {
      debugPrint("Error checking installed translations: $e");
    }
  }

  bool isInstalled(BibleVersion version) {
    return version.id == 'am_1954' ||
        version.id == 'en_kjv' ||
        installedTranslations.contains(version.id);
  }

  Future<void> _saveInstalledTranslations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'installed_translations',
        installedTranslations,
      );
    } catch (e) {
      debugPrint("Error saving installed translations: $e");
    }
  }

  /// Installs a translation: bundled versions load straight from assets,
  /// remote versions are downloaded and cached on disk.
  /// Returns true on success.
  Future<bool> downloadTranslation(BibleVersion version) async {
    if (downloadingVersions.contains(version.id)) return false;

    downloadingVersions.add(version.id);
    notifyListeners();
    try {
      if (version.isBundled) {
        version.data ??= _transformBibleData(
          json.decode(await rootBundle.loadString(version.assetPath)),
        );
      } else {
        final path = (await getApplicationDocumentsDirectory()).path;
        final file = File('$path/${version.filename}');
        if (!await file.exists()) {
          final response = await http.get(Uri.parse(version.downloadUrl));
          if (response.statusCode != 200) {
            throw Exception('HTTP ${response.statusCode}');
          }
          await file.writeAsString(response.body);
        }
      }
      if (!installedTranslations.contains(version.id)) {
        installedTranslations.add(version.id);
        await _saveInstalledTranslations();
      }
      return true;
    } catch (e) {
      debugPrint("Error downloading translation: $e");
      return false;
    } finally {
      downloadingVersions.remove(version.id);
      notifyListeners();
    }
  }

  Future<void> removeTranslation(BibleVersion version) async {
    if (version.id == 'am_1954' || version.id == 'en_kjv') return;
    installedTranslations.remove(version.id);
    if (_selectedVersionId == version.id) {
      await changeTranslation('am_1954');
    }
    if (_parallelVersionId == version.id) {
      _parallelVersionId = null;
      _parallelBible = {};
    }
    version.data = null; // Free memory; asset stays in the bundle.
    if (!version.isBundled) {
      // Delete the downloaded file so it stops taking up disk space.
      try {
        final file = await _getLocalFile(version.filename);
        if (await file.exists()) await file.delete();
      } catch (e) {
        debugPrint("Error deleting translation file: $e");
      }
    }
    await _saveInstalledTranslations();
    notifyListeners();
  }

  Future<void> loadBibleData() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Load both translations in parallel
      final results = await Future.wait([
        rootBundle.loadString('assets/bible_data/amharic_bible.json'),
        rootBundle.loadString('assets/bible_data/english_kjv_bible.json'),
      ]);

      final amVersion = _availableTranslations.firstWhere(
        (v) => v.id == 'am_1954',
      );
      final kjvVersion = _availableTranslations.firstWhere(
        (v) => v.id == 'en_kjv',
      );

      amVersion.data = _transformBibleData(json.decode(results[0]));
      kjvVersion.data = _transformBibleData(json.decode(results[1]));

      // Set initial data
      _handleTranslationSwitch(_selectedVersionId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading Bible data: $e");
      _error = "Failed to load offline Bible data.";
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changeTranslation(String newVersionId) async {
    if (_selectedVersionId == newVersionId) return;

    final version = _availableTranslations.firstWhere(
      (v) => v.id == newVersionId,
    );

    // Load data if not already loaded
    if (version.data == null) {
      try {
        if (version.isBundled) {
          final raw = await rootBundle.loadString(version.assetPath);
          version.data = _transformBibleData(json.decode(raw));
        } else {
          // Check local storage for downloaded translations
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/${version.filename}');
          if (await file.exists()) {
            final content = await file.readAsString();
            version.data = _transformBibleData(json.decode(content));
          } else {
            debugPrint("Translation file not found: ${version.filename}");
            return;
          }
        }
      } catch (e) {
        debugPrint("Error switching translation: $e");
        return;
      }
    }

    // Attempt to maintain book/chapter context before officially switching ID
    _handleTranslationSwitch(newVersionId);

    _selectedVersionId = newVersionId;
    // Upcoming verse notifications carry verse text, so they follow the
    // newly selected translation. Fire-and-forget.
    if (_votdEnabled) _scheduleVotd();
    notifyListeners();
  }

  void toggleTranslation() {
    final nextId = _selectedVersionId == 'am_1954' ? 'en_kjv' : 'am_1954';
    changeTranslation(nextId);
  }

  // Getters
  List<BibleVersion> get availableTranslations => _availableTranslations;
  BibleVersion get currentTranslation =>
      _availableTranslations.firstWhere((v) => v.id == _selectedVersionId);
  BibleVersion? get parallelTranslation {
    if (_parallelVersionId == null) return null;
    return _availableTranslations.firstWhere((v) => v.id == _parallelVersionId);
  }

  bool get isAmharic => _selectedVersionId == 'am_1954';
  bool get isEnglish => _selectedVersionId != 'am_1954';
  String get currentLanguage => currentTranslation.name;
  String get selectedBook => _selectedBook;
  int get selectedChapter => _selectedChapter;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get books => currentBible.keys.toList();

  /// Index of the first New Testament book, found by canonical ID so that
  /// translations with extra books (KJVA puts 14 Apocrypha books between
  /// Malachi and Matthew) split in the right place. Deuterocanonical books
  /// sit with the Old Testament, as they do in the Ethiopian canon.
  /// Falls back to 39 when no book name resolves (language without aliases).
  int get _newTestamentStart {
    final all = books;
    for (var i = 0; i < all.length; i++) {
      if (isNewTestamentBook(all[i]) == true) return i;
    }
    return all.length > 39 ? 39 : all.length;
  }

  List<String> get oldTestamentBooks {
    return books.take(_newTestamentStart).toList();
  }

  List<String> get newTestamentBooks {
    return books.skip(_newTestamentStart).toList();
  }

  Set<String> get selectedVerses => _selectedVerses;
  List<Map<String, dynamic>> get bookmarks => _bookmarks;
  ThemeMode get themeMode => _themeMode;
  double get fontSize => _fontSize;
  double get audioSpeed => _audioSpeed;
  double get lineSpacing => _lineSpacing;

  Map<String, dynamic> _parallelBible = {};
  Map<String, dynamic> get parallelBible => _parallelBible;

  bool _isSplitScreen = false;
  bool get isSplitScreen => _isSplitScreen;

  void toggleSplitScreen() {
    _isSplitScreen = !_isSplitScreen;
    if (_isSplitScreen && _parallelVersionId == null) {
      // Default secondary translation
      _parallelVersionId = _selectedVersionId == 'am_1954'
          ? 'en_kjv'
          : 'am_1954';
      loadTranslation(_parallelVersionId!, isParallel: true);
    }
    notifyListeners();
  }

  void setParallelVersion(String id) {
    if (_parallelVersionId != id) {
      _parallelVersionId = id;
      loadTranslation(id, isParallel: true);
    }
  }

  /// App UI language: 'system', 'en', or 'am'.
  String _appLanguage = 'system';
  String get appLanguage => _appLanguage;

  /// Locale override for MaterialApp; null follows the device locale.
  Locale? get appLocale =>
      _appLanguage == 'system' ? null : Locale(_appLanguage);

  void setAppLanguage(String language) {
    if (_appLanguage != language) {
      _appLanguage = language;
      saveSettings();
      // Scheduled notification text is baked in at schedule time, so it has
      // to be re-scheduled to pick up the new language.
      if (_reminderEnabled) _scheduleReminder();
      if (_votdEnabled) _scheduleVotd();
      notifyListeners();
    }
  }

  // --- Daily reading reminder ---
  bool _reminderEnabled = false;
  int _reminderHour = 7;
  int _reminderMinute = 0;

  bool get reminderEnabled => _reminderEnabled;
  TimeOfDay get reminderTime =>
      TimeOfDay(hour: _reminderHour, minute: _reminderMinute);

  /// Localizations matching the app language, for text that is rendered
  /// outside the widget tree (scheduled notifications).
  AppLocalizations _reminderL10n() {
    var locale = appLocale ?? PlatformDispatcher.instance.locale;
    if (!AppLocalizations.supportedLocales.any(
      (l) => l.languageCode == locale.languageCode,
    )) {
      locale = const Locale('en');
    }
    return lookupAppLocalizations(Locale(locale.languageCode));
  }

  Future<void> _scheduleReminder() async {
    final l10n = _reminderL10n();
    await NotificationService.instance.scheduleDailyReminder(
      hour: _reminderHour,
      minute: _reminderMinute,
      title: l10n.reminderNotificationTitle,
      body: l10n.reminderNotificationBody,
    );
  }

  /// Enables or disables the daily reminder. Returns false when the OS
  /// denied notification permission (the toggle stays off).
  Future<bool> setReminderEnabled(bool enabled) async {
    if (enabled) {
      final granted = await NotificationService.instance.requestPermissions();
      if (!granted) {
        if (_reminderEnabled) {
          _reminderEnabled = false;
          saveSettings();
          notifyListeners();
        }
        return false;
      }
      _reminderEnabled = true;
      await _scheduleReminder();
    } else {
      _reminderEnabled = false;
      await NotificationService.instance.cancelDailyReminder();
    }
    saveSettings();
    notifyListeners();
    return true;
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    if (_reminderHour == time.hour && _reminderMinute == time.minute) return;
    _reminderHour = time.hour;
    _reminderMinute = time.minute;
    if (_reminderEnabled) await _scheduleReminder();
    saveSettings();
    notifyListeners();
  }

  // --- Verse-of-the-day notification ---
  bool _votdEnabled = false;
  int _votdHour = 6;
  int _votdMinute = 30;

  bool get votdEnabled => _votdEnabled;
  TimeOfDay get votdTime => TimeOfDay(hour: _votdHour, minute: _votdMinute);

  /// (Re)schedules the next week of verse notifications from the curated
  /// list, in the current translation and app language. No-op while the
  /// Bible is still loading — [init] calls it again once data is ready.
  Future<void> _scheduleVotd() async {
    if (currentBible.isEmpty) return;
    final l10n = _reminderL10n();
    final today = DateTime.now();
    final entries = <({String title, String body})>[
      for (var i = 0; i < NotificationService.votdDays; i++)
        () {
          final v = verseOfTheDayFor(today.add(Duration(days: i)));
          return (
            title: '${l10n.verseOfTheDay} • ${v['reference']}',
            body: v['text'] ?? '',
          );
        }(),
    ];
    await NotificationService.instance.scheduleVerseOfDay(
      hour: _votdHour,
      minute: _votdMinute,
      entries: entries,
    );
  }

  /// Enables or disables the daily verse notification. Returns false when
  /// the OS denied notification permission.
  Future<bool> setVotdEnabled(bool enabled) async {
    if (enabled) {
      final granted = await NotificationService.instance.requestPermissions();
      if (!granted) {
        if (_votdEnabled) {
          _votdEnabled = false;
          saveSettings();
          notifyListeners();
        }
        return false;
      }
      _votdEnabled = true;
      await _scheduleVotd();
    } else {
      _votdEnabled = false;
      await NotificationService.instance.cancelVerseOfDay();
    }
    saveSettings();
    notifyListeners();
    return true;
  }

  Future<void> setVotdTime(TimeOfDay time) async {
    if (_votdHour == time.hour && _votdMinute == time.minute) return;
    _votdHour = time.hour;
    _votdMinute = time.minute;
    if (_votdEnabled) await _scheduleVotd();
    saveSettings();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      saveSettings();
      notifyListeners();
    }
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }

  void setFontSize(double size) {
    if (_fontSize != size) {
      _fontSize = size;
      saveSettings();
      notifyListeners();
    }
  }

  void setAudioSpeed(double speed) {
    if (_audioSpeed != speed) {
      _audioSpeed = speed;
      saveSettings();
      notifyListeners();
    }
  }

  void setLineSpacing(double spacing) {
    if (_lineSpacing != spacing) {
      _lineSpacing = spacing;
      saveSettings();
      notifyListeners();
    }
  }

  Future<void> loadSettings() async {
    try {
      final file = await _getLocalFile('settings.json');
      if (await file.exists()) {
        final String contents = await file.readAsString();
        final Map<String, dynamic> decoded = json.decode(contents);

        if (decoded.containsKey('themeMode')) {
          final themeIndex = decoded['themeMode'] as int;
          _themeMode = ThemeMode.values[themeIndex];
        }
        if (decoded.containsKey('fontSize')) {
          _fontSize = (decoded['fontSize'] as num).toDouble();
        }
        if (decoded.containsKey('audioSpeed')) {
          _audioSpeed = (decoded['audioSpeed'] as num).toDouble();
        }
        if (decoded.containsKey('lineSpacing')) {
          _lineSpacing = (decoded['lineSpacing'] as num).toDouble();
        }
        if (decoded.containsKey('lastReadBook')) {
          _lastReadBook = decoded['lastReadBook'] as String?;
        }
        if (decoded.containsKey('lastReadChapter')) {
          _lastReadChapter = decoded['lastReadChapter'] as int?;
        }
        if (decoded.containsKey('appLanguage')) {
          _appLanguage = decoded['appLanguage'] as String;
        }
        if (decoded.containsKey('reminderEnabled')) {
          _reminderEnabled = decoded['reminderEnabled'] as bool;
        }
        if (decoded.containsKey('reminderHour')) {
          _reminderHour = decoded['reminderHour'] as int;
        }
        if (decoded.containsKey('reminderMinute')) {
          _reminderMinute = decoded['reminderMinute'] as int;
        }
        if (decoded.containsKey('votdEnabled')) {
          _votdEnabled = decoded['votdEnabled'] as bool;
        }
        if (decoded.containsKey('votdHour')) {
          _votdHour = decoded['votdHour'] as int;
        }
        if (decoded.containsKey('votdMinute')) {
          _votdMinute = decoded['votdMinute'] as int;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading settings: $e");
    }
  }

  Future<void> saveSettings() async {
    try {
      final file = await _getLocalFile('settings.json');
      final settings = {
        'themeMode': _themeMode.index,
        'fontSize': _fontSize,
        'audioSpeed': _audioSpeed,
        'lineSpacing': _lineSpacing,
        'lastReadBook': _lastReadBook,
        'lastReadChapter': _lastReadChapter,
        'appLanguage': _appLanguage,
        'reminderEnabled': _reminderEnabled,
        'reminderHour': _reminderHour,
        'reminderMinute': _reminderMinute,
        'votdEnabled': _votdEnabled,
        'votdHour': _votdHour,
        'votdMinute': _votdMinute,
      };
      await file.writeAsString(json.encode(settings));
    } catch (e) {
      debugPrint("Error saving settings: $e");
    }
  }

  // --- Journal Features ---
  Future<void> _loadNotes() async {
    try {
      _notes = await UserDataStore.instance.loadNotes();
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading notes: $e");
    }
  }

  void saveNote({
    required String verseId,
    required String text,
    required String content,
    String category = "Personal",
  }) async {
    if (content.trim().isEmpty) return;

    final note = <String, dynamic>{
      'reference': verseId, // Using verseId directly
      'text': text,
      'userNote': content,
      'category': category,
      'timestamp': DateTime.now().toIso8601String(),
    };
    _notes.insert(0, note);
    notifyListeners();

    try {
      note['id'] = await UserDataStore.instance.insertNote(note);
    } catch (e) {
      debugPrint("Error saving note: $e");
    }
  }

  bool hasNote(String verseId) {
    return _notes.any((note) => note['reference'] == verseId);
  }

  void deleteNote(int index) {
    if (index >= 0 && index < _notes.length) {
      final note = _notes.removeAt(index);
      final id = note['id'];
      if (id is int) {
        UserDataStore.instance.deleteNote(id);
      }
      notifyListeners();
    }
  }

  void toggleVerseSelection(String verseNum) {
    if (_selectedVerses.contains(verseNum)) {
      _selectedVerses.remove(verseNum);
    } else {
      _selectedVerses.add(verseNum);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedVerses.clear();
    notifyListeners();
  }

  String _getVerseKey(String verse) =>
      "${_selectedBook}_${_selectedChapter}_$verse";

  Color? getHighlightColor(String verse) {
    final colorValue = _highlights[_getVerseKey(verse)];
    if (colorValue != null) {
      return Color(colorValue);
    }
    return null;
  }

  Future<void> loadHighlights() async {
    try {
      _highlights = await UserDataStore.instance.loadHighlights();
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading highlights: $e");
    }
  }

  void applyHighlight(int colorValue) {
    for (String verse in _selectedVerses) {
      final key = _getVerseKey(verse);
      _highlights[key] = colorValue;
      UserDataStore.instance
          .setHighlight(key, colorValue)
          .catchError((e) => debugPrint("Error saving highlight: $e"));
    }
    clearSelection();
  }

  void removeHighlight() {
    for (String verse in _selectedVerses) {
      final key = _getVerseKey(verse);
      _highlights.remove(key);
      UserDataStore.instance
          .removeHighlight(key)
          .catchError((e) => debugPrint("Error removing highlight: $e"));
    }
    clearSelection();
  }

  Future<void> loadBookmarks() async {
    try {
      _bookmarks = await UserDataStore.instance.loadBookmarks();
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading bookmarks: $e");
    }
  }

  void toggleBookmarks() async {
    for (String verse in _selectedVerses) {
      final existsIndex = _bookmarks.indexWhere(
        (b) =>
            b['book'] == _selectedBook &&
            b['chapter'] == _selectedChapter &&
            b['verseNum'] == verse,
      );

      if (existsIndex != -1) {
        final removed = _bookmarks.removeAt(existsIndex);
        final id = removed['id'];
        if (id is int) {
          UserDataStore.instance
              .deleteBookmark(id)
              .catchError((e) => debugPrint("Error removing bookmark: $e"));
        }
      } else {
        final bookmark = {
          'book': _selectedBook,
          'chapter': _selectedChapter,
          'verseNum': verse,
          'text': verses[verse].toString(),
        };
        _bookmarks.add(bookmark);
        try {
          bookmark['id'] = await UserDataStore.instance.insertBookmark(
            bookmark,
          );
        } catch (e) {
          debugPrint("Error saving bookmark: $e");
        }
      }
    }
    clearSelection();
  }

  void removeBookmark(Map<String, dynamic> bookmark) {
    _bookmarks.remove(bookmark);
    final id = bookmark['id'];
    if (id is int) {
      UserDataStore.instance
          .deleteBookmark(id)
          .catchError((e) => debugPrint("Error removing bookmark: $e"));
    }
    notifyListeners();
  }

  bool isBookmarked(String verseNum) {
    return _bookmarks.any(
      (b) =>
          b['book'] == _selectedBook &&
          b['chapter'] == _selectedChapter &&
          b['verseNum'] == verseNum,
    );
  }

  String getSelectedText() {
    if (_selectedVerses.isEmpty) return '';

    final sortedVerses = _selectedVerses.toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    final currentVersesMap = verses;
    final StringBuffer textBuffer = StringBuffer();

    for (var vNum in sortedVerses) {
      if (currentVersesMap.containsKey(vNum)) {
        textBuffer.write('${currentVersesMap[vNum]} ');
      }
    }

    final String combinedText = textBuffer.toString().trim();
    return combinedText;
  }

  String getSelectedReference() {
    if (_selectedVerses.isEmpty) return '';

    final sortedVerses = _selectedVerses.toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    final verseRange = sortedVerses.length == 1
        ? sortedVerses.first
        : '${sortedVerses.first}-${sortedVerses.last}';

    return '$_selectedBook $_selectedChapter:$verseRange';
  }

  Future<File> _getLocalFile(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$filename');
  }

  /// Load a specific translation by ID
  Future<void> loadTranslation(String id, {bool isParallel = false}) async {
    try {
      if (!isParallel) {
        _isLoading = true;
      }
      _error = null;
      notifyListeners();

      final version = _availableTranslations.firstWhere((v) => v.id == id);

      // If already in memory
      if (version.data != null) {
        if (isParallel) {
          _parallelBible = version.data!;
        } else {
          // Change book appropriately using the index paradigm if book names differ
          _handleTranslationSwitch(id);
          _selectedVersionId = id;
        }

        _isLoading = false;
        notifyListeners();
        return;
      }

      String jsonBody = '';
      if (version.isBundled) {
        jsonBody = await rootBundle.loadString(version.assetPath);
      } else {
        // Check local cache, then fall back to the network
        final file = await _getLocalFile(version.filename);
        if (await file.exists()) {
          debugPrint("Loading ${version.name} from local cache...");
          jsonBody = await file.readAsString();
        } else {
          debugPrint("Downloading ${version.name}...");
          final response = await http.get(Uri.parse(version.downloadUrl));
          if (response.statusCode == 200) {
            jsonBody = response.body;
            await file.writeAsString(jsonBody);
          } else {
            throw Exception("Failed to download ${version.name}");
          }
        }
      }

      final rawData = json.decode(jsonBody);
      version.data = _transformBibleData(rawData);

      if (isParallel) {
        _parallelBible = version.data!;
      } else {
        _handleTranslationSwitch(id);
        _selectedVersionId = id;

        // Force auto-load if a valid book is not selected
        if (_selectedBook.isEmpty ||
            !version.data!.containsKey(_selectedBook)) {
          if (version.data!.isNotEmpty) {
            _selectedBook = version.data!.keys.first;
            _selectedChapter = 1;
          }
        }
      }

      _isLoading = false;

      // Ensure the first chapter renders correctly instead of blank screen
      if (verses.isEmpty && currentBible.isNotEmpty) {
        selectBook(currentBible.keys.first);
        selectChapter(1);
      } else {
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading Bible data: $e");
      _error = "Check your connection and restart.";
      _isLoading = false;
      notifyListeners();
    }
  }

  /// The current translation's key for a canonical book ID, or null when
  /// that book isn't in the loaded translation.
  String? bookKeyForId(String bookId) {
    for (final key in currentBible.keys) {
      if (resolveBookId(key) == bookId) return key;
    }
    return null;
  }

  /// Localized display name for a canonical book ID: the current
  /// translation's book name when available, English otherwise.
  String bookNameForId(String bookId) =>
      bookKeyForId(bookId) ?? bookDisplayNames[bookId] ?? bookId;

  /// Opens a plan reading in the reader. Returns false when the book is
  /// missing from the current translation.
  bool openReading(String bookId, int chapter) {
    final key = bookKeyForId(bookId);
    if (key == null) return false;
    selectBook(key);
    selectChapter(chapter);
    return true;
  }

  /// Opens a saved reference (bookmark, note) whose book name may come from
  /// a different translation than the one currently loaded. Falls back to
  /// canonical-ID resolution when the raw key doesn't match.
  bool openSavedReference(String book, int chapter) {
    if (currentBible.containsKey(book)) {
      selectBook(book);
      selectChapter(chapter);
      return true;
    }
    final bookId = resolveBookId(book);
    if (bookId != null) return openReading(bookId, chapter);
    return false;
  }

  // --- Recent searches ---
  static const int _maxRecentSearches = 8;
  List<String> _recentSearches = [];
  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  Future<void> loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading recent searches: $e');
    }
  }

  /// Records a committed search (submit / theme tap), most recent first.
  Future<void> addRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _recentSearches.remove(trimmed);
    _recentSearches.insert(0, trimmed);
    if (_recentSearches.length > _maxRecentSearches) {
      _recentSearches = _recentSearches.sublist(0, _maxRecentSearches);
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('recent_searches', _recentSearches);
    } catch (e) {
      debugPrint('Error saving recent searches: $e');
    }
  }

  /// True when the loaded translation's text is written in Ge'ez script —
  /// used to pick search suggestions the text can actually match.
  bool get currentTranslationIsEthiopic {
    for (final book in currentBible.values) {
      if (book is Map) {
        for (final chapter in book.values) {
          final sample = chapter is Map
              ? chapter.values.whereType<String>().firstOrNull
              : (chapter is List
                    ? chapter.whereType<String>().firstOrNull
                    : null);
          if (sample != null && sample.isNotEmpty) {
            return sample.runes.any((r) => r >= 0x1200 && r <= 0x137F);
          }
        }
      }
    }
    return false;
  }

  void _handleTranslationSwitch(String newId) {
    if (_selectedBook.isEmpty) return;

    final version = _availableTranslations.firstWhere((v) => v.id == newId);
    if (version.data == null || version.data!.isEmpty) return;

    final newBibleData = version.data!;
    final oldBibleData = currentBible;

    // 1. Maintain the current book across the switch. Prefer canonical book
    // IDs so translations with different canons (NT-only, Apocrypha) still
    // land on the same book; fall back to positional index when the name
    // can't be resolved (e.g. untranslated alias languages).
    final newBookKeys = newBibleData.keys.toList();
    final currentBookId = resolveBookId(_selectedBook);
    String? matchedKey;

    if (currentBookId != null) {
      for (final key in newBookKeys) {
        if (resolveBookId(key) == currentBookId) {
          matchedKey = key;
          break;
        }
      }
    }

    if (matchedKey != null) {
      _selectedBook = matchedKey;
    } else {
      final currentBookKeys = oldBibleData.keys.toList();
      final bookIndex = currentBookKeys.indexOf(_selectedBook);
      if (bookIndex != -1) {
        _selectedBook = bookIndex < newBookKeys.length
            ? newBookKeys[bookIndex]
            : newBookKeys.first;
      } else {
        _selectedBook = newBookKeys.first;
      }
    }

    // 2. Cap Chapter to ensure we don't exceed available chapters in the new translation
    final newBookContent = newBibleData[_selectedBook];
    int maxChapters = 0;

    if (newBookContent is Map) {
      maxChapters = newBookContent.length;
    } else if (newBookContent is List) {
      maxChapters = newBookContent.length;
      // Handle potential null/empty first elements if array starts at index 1
      if (newBookContent.isNotEmpty && newBookContent[0] == null) {
        maxChapters -= 1;
      }
    }

    if (_selectedChapter > maxChapters && maxChapters > 0) {
      _selectedChapter = maxChapters;
    } else if (_selectedChapter < 1) {
      _selectedChapter = 1;
    }
  }

  // Helper function to translate your specific JSON structure
  Map<String, dynamic> _transformBibleData(Map<String, dynamic> rawData) {
    final Map<String, dynamic> formattedBible = {};

    // Check if the JSON is wrapped in a "books" array
    if (rawData.containsKey('books') && rawData['books'] is List) {
      final List<dynamic> booksList = rawData['books'];

      for (var book in booksList) {
        // Flexible book name detection
        final String bookTitle = (book['title'] ?? book['name'] ?? 'Unknown')
            .toString()
            .trim();
        final Map<String, dynamic> formattedChapters = {};

        if (book['chapters'] is List) {
          final List<dynamic> chaptersList = book['chapters'];
          for (var c = 0; c < chaptersList.length; c++) {
            final chapter = chaptersList[c];
            // Some source files carry corrupted chapter labels (stray words
            // instead of numbers). Chapters are positional, so fall back to
            // the index when the label isn't a number.
            final rawNum = chapter['chapter']?.toString();
            final String chapterNum =
                (rawNum != null && int.tryParse(rawNum) != null)
                ? rawNum
                : (c + 1).toString();
            final Map<String, String> formattedVerses = {};

            if (chapter['verses'] is List) {
              final List<dynamic> versesList = chapter['verses'];
              for (int i = 0; i < versesList.length; i++) {
                final verseData = versesList[i];
                if (verseData is Map) {
                  // Handle Object format (e.g., BBE)
                  final vNum = (verseData['verse'] ?? (i + 1)).toString();
                  final vText = (verseData['text'] ?? '').toString();
                  formattedVerses[vNum] = vText;
                } else {
                  // Handle String array format
                  formattedVerses[(i + 1).toString()] = verseData.toString();
                }
              }
            }
            formattedChapters[chapterNum] = formattedVerses;
          }
        }
        formattedBible[bookTitle] = formattedChapters;
      }
      return formattedBible;
    }

    // If it's already in the correct format (fallback for English if it differs)
    return rawData;
  }

  /// Select a book and reset chapter to 1
  void selectBook(String book) {
    clearActiveSearchQuery();
    if (_selectedBook != book) {
      _selectedBook = book;
      _selectedChapter = 1;
      updateLastRead();
      notifyListeners();
    }
  }

  // Changes the chapter and tells the screen to update
  void selectChapter(int chapter) {
    clearActiveSearchQuery();
    _selectedChapter = chapter;
    updateLastRead();
    notifyListeners();
  }

  bool get hasPreviousChapter {
    if (books.isEmpty || chapters.isEmpty) return false;
    return books.indexOf(_selectedBook) > 0 ||
        chapters.indexOf(_selectedChapter) > 0;
  }

  bool get hasNextChapter {
    if (books.isEmpty || chapters.isEmpty) return false;
    return books.indexOf(_selectedBook) < books.length - 1 ||
        chapters.indexOf(_selectedChapter) < chapters.length - 1;
  }

  void previousChapter() {
    if (!hasPreviousChapter) return;

    final currentChapters = chapters;
    final currentIndex = currentChapters.indexOf(_selectedChapter);

    if (currentIndex > 0) {
      _selectedChapter = currentChapters[currentIndex - 1];
      updateLastRead();
      notifyListeners();
    } else {
      final currentBooks = books;
      final bookIndex = currentBooks.indexOf(_selectedBook);
      if (bookIndex > 0) {
        _selectedBook = currentBooks[bookIndex - 1];
        final newChapters = chapters;
        _selectedChapter = newChapters.isNotEmpty ? newChapters.last : 1;
        updateLastRead();
        notifyListeners();
      }
    }
  }

  void nextChapter() {
    if (!hasNextChapter) return;

    final currentChapters = chapters;
    final currentIndex = currentChapters.indexOf(_selectedChapter);

    if (currentIndex < currentChapters.length - 1) {
      _selectedChapter = currentChapters[currentIndex + 1];
      updateLastRead();
      notifyListeners();
    } else {
      final currentBooks = books;
      final bookIndex = currentBooks.indexOf(_selectedBook);
      if (bookIndex < currentBooks.length - 1) {
        _selectedBook = currentBooks[bookIndex + 1];
        final newChapters = chapters;
        _selectedChapter = newChapters.isNotEmpty ? newChapters.first : 1;
        updateLastRead();
        notifyListeners();
      }
    }
  }

  /// Get the currently selected Bible based on language
  Map<String, dynamic> get currentBible {
    return currentTranslation.data ?? {};
  }

  /// Get chapters for the selected book
  List<int> get chapters {
    if (_selectedBook.isEmpty) return <int>[];
    final book = currentBible[_selectedBook];
    if (book == null || book is! Map) return <int>[];

    // Force Dart to build a strict integer list
    final List<int> chapterList = <int>[];
    for (var key in book.keys) {
      final int? num = int.tryParse(key.toString());
      if (num != null) {
        chapterList.add(num);
      }
    }
    chapterList.sort();
    return chapterList;
  }

  /// Get verses for the selected chapter
  Map<String, String> get verses {
    if (_selectedBook.isEmpty) return {};
    final book = currentBible[_selectedBook];
    if (book == null) return {};

    // 1. Find the Chapter (Safely handles if JSON used a List or Map)
    dynamic chapter;
    if (book is List) {
      int chapterNum = int.tryParse(_selectedChapter.toString()) ?? 1;
      // Intelligently grab the chapter depending on if the array starts at index 0 or 1
      if (chapterNum < book.length && book[0] == null) {
        chapter = book[chapterNum];
      } else if (chapterNum - 1 >= 0 && chapterNum - 1 < book.length) {
        chapter = book[chapterNum - 1];
      }
    } else if (book is Map) {
      chapter =
          book[_selectedChapter.toString()] ??
          book[int.tryParse(_selectedChapter.toString())];
    }

    if (chapter == null) return {};

    final Map<String, String> result = {};

    // 2. Parse the Verses (Safely handles if JSON used a List or Map)
    if (chapter is List) {
      for (int i = 0; i < chapter.length; i++) {
        if (chapter[i] != null && chapter[i].toString().trim().isNotEmpty) {
          // If index 0 is null, it means Verse 1 is at index 1
          int verseNum = chapter[0] == null ? i : (i + 1);
          result[verseNum.toString()] = chapter[i].toString();
        }
      }
    } else if (chapter is Map) {
      chapter.forEach((key, value) {
        if (value != null && value.toString().trim().isNotEmpty) {
          result[key.toString()] = value.toString();
        }
      });
    }

    // 3. Sort by verse number so they appear in correct order
    final sortedKeys =
        result.keys.where((k) => int.tryParse(k) != null).toList()
          ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    return Map.fromEntries(sortedKeys.map((k) => MapEntry(k, result[k]!)));
  }

  /// Get verses for the selected chapter in the secondary translation
  Map<String, String> get parallelVerses {
    if (_selectedBook.isEmpty || _parallelBible.isEmpty) return {};

    // Find the equivalent book in the secondary translation: match by
    // canonical book ID first, fall back to position for unresolved names.
    final parallelBooks = _parallelBible.keys.toList();
    String? parallelBookName;
    final bookId = resolveBookId(_selectedBook);
    if (bookId != null) {
      for (final key in parallelBooks) {
        if (resolveBookId(key) == bookId) {
          parallelBookName = key;
          break;
        }
      }
    }
    if (parallelBookName == null) {
      final primaryIndex = currentBible.keys.toList().indexOf(_selectedBook);
      if (primaryIndex == -1 || primaryIndex >= parallelBooks.length) {
        return {};
      }
      parallelBookName = parallelBooks[primaryIndex];
    }
    final book = _parallelBible[parallelBookName];
    if (book == null) return {};

    // Using exact same fetching logic as primary verses
    dynamic chapter;
    if (book is List) {
      int chapterNum = int.tryParse(_selectedChapter.toString()) ?? 1;
      if (chapterNum < book.length && book[0] == null) {
        chapter = book[chapterNum];
      } else if (chapterNum - 1 >= 0 && chapterNum - 1 < book.length) {
        chapter = book[chapterNum - 1];
      }
    } else if (book is Map) {
      chapter =
          book[_selectedChapter.toString()] ??
          book[int.tryParse(_selectedChapter.toString())];
    }

    if (chapter == null) return {};

    final Map<String, String> result = {};
    if (chapter is List) {
      for (int i = 0; i < chapter.length; i++) {
        if (chapter[i] != null && chapter[i].toString().trim().isNotEmpty) {
          int verseNum = chapter[0] == null ? i : (i + 1);
          result[verseNum.toString()] = chapter[i].toString();
        }
      }
    } else if (chapter is Map) {
      chapter.forEach((key, value) {
        if (value != null && value.toString().trim().isNotEmpty) {
          result[key.toString()] = value.toString();
        }
      });
    }

    final sortedKeys =
        result.keys.where((k) => int.tryParse(k) != null).toList()
          ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    return Map.fromEntries(sortedKeys.map((k) => MapEntry(k, result[k]!)));
  }

  /// Get total verse count for selected chapter
  int get verseCount => verses.length;

  Map<String, String> get verseOfTheDay => verseOfTheDayFor(DateTime.now());

  /// The curated verse for any given date — deterministic, so the schedule
  /// of upcoming daily-verse notifications matches what the app shows.
  Map<String, String> verseOfTheDayFor(DateTime date) {
    if (currentBible.isEmpty) {
      return {
        'reference': '...',
        'text': 'Loading...',
        'book': '',
        'chapter': '',
        'verse': '',
      };
    }

    final seed = date.year * 10000 + date.month * 100 + date.day;
    final random = Random(seed);
    return dailyVerseFor(_dailyVerses[random.nextInt(_dailyVerses.length)]);
  }

  /// The curated daily-verse references, in English book names. Also the
  /// question pool for the Bible games.
  List<Map<String, String>> get dailyVerseRefs =>
      List.unmodifiable(_dailyVerses);

  /// Resolves one curated reference against the current translation.
  Map<String, String> dailyVerseFor(Map<String, String> verseRef) {
    final String engBook = verseRef['book']!;
    final String chapter = verseRef['chapter']!;
    final String verse = verseRef['verse']!;

    // Resolve the curated English name to the current translation's own key
    // through the canonical catalog, so the daily verse works in every
    // translation rather than only the two bundled defaults.
    final bookId = resolveBookId(engBook);
    final String actualJsonKey =
        (bookId == null ? null : bookKeyForId(bookId)) ?? engBook;

    final String text =
        currentBible[actualJsonKey]?[chapter]?[verse] ?? 'Verse not found';

    return {
      'reference': '$actualJsonKey $chapter:$verse',
      'text': text,
      // The exact JSON key, so onTap navigation lands on the right book.
      'book': actualJsonKey,
      'chapter': chapter,
      'verse': verse,
    };
  }

  /// Search across all books, chapters, and verses.
  List<Map<String, dynamic>> searchBible(String query) {
    if (query.trim().isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    final Map<String, dynamic> bible = currentBible;
    final List<Map<String, dynamic>> results = [];

    // Loop through books
    for (String bookName in bible.keys) {
      final bookData = bible[bookName];

      // Get chapters
      List<int> chaptersList = [];
      if (bookData is Map) {
        chaptersList =
            bookData.keys.map((k) => int.tryParse(k.toString()) ?? 1).toList()
              ..sort();
      } else if (bookData is List) {
        chaptersList = List.generate(bookData.length, (i) => i + 1);
      }

      for (int chapterNum in chaptersList) {
        dynamic chapter;
        if (bookData is Map) {
          chapter = bookData[chapterNum.toString()] ?? bookData[chapterNum];
        } else if (bookData is List) {
          if (chapterNum < bookData.length && bookData[0] == null) {
            chapter = bookData[chapterNum];
          } else if (chapterNum - 1 >= 0 && chapterNum - 1 < bookData.length) {
            chapter = bookData[chapterNum - 1];
          }
        }

        if (chapter == null) continue;

        // Parse verses
        if (chapter is Map) {
          chapter.forEach((verseKey, verseValue) {
            if (verseValue != null && verseValue.toString().trim().isNotEmpty) {
              final text = verseValue.toString();
              if (text.toLowerCase().contains(lowerQuery)) {
                results.add({
                  'book': bookName,
                  'chapter': chapterNum.toString(),
                  'verse': verseKey.toString(),
                  'text': text,
                });
              }
            }
          });
        } else if (chapter is List) {
          for (int i = 0; i < chapter.length; i++) {
            if (chapter[i] != null && chapter[i].toString().trim().isNotEmpty) {
              int verseNum = chapter[0] == null ? i : (i + 1);
              final text = chapter[i].toString();
              if (text.toLowerCase().contains(lowerQuery)) {
                results.add({
                  'book': bookName,
                  'chapter': chapterNum.toString(),
                  'verse': verseNum.toString(),
                  'text': text,
                });
              }
            }
          }
        }
      }
    }
    return results;
  }
}

// ─────────────────────────────────────────────────────
// APP SHELL – Bottom Navigation Host
