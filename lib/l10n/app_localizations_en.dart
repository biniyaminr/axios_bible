// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Axios Bible';

  @override
  String get navHome => 'Home';

  @override
  String get navBible => 'Bible';

  @override
  String get navSearch => 'Search';

  @override
  String get navBookmarks => 'Bookmarks';

  @override
  String get settings => 'Settings';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get fontSize => 'Font Size';

  @override
  String get audioSpeed => 'Audio Speed';

  @override
  String get lineSpacing => 'Line Spacing';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get bookmarksTitle => 'Bookmarks';

  @override
  String get noBookmarks => 'No bookmarks yet.';

  @override
  String get noBookmarksHint =>
      'No bookmarks yet. Save meaningful verses to find them quickly.';

  @override
  String get searchBibleTitle => 'Search the Bible';

  @override
  String get searchHint => 'Search words or verses…';

  @override
  String get searchTranslationsHint => 'Search translations…';

  @override
  String get filterVerses => 'Verses';

  @override
  String get filterChapters => 'Chapters';

  @override
  String get filterTexts => 'Texts';

  @override
  String get noResults => 'No results found…';

  @override
  String get clear => 'Clear';

  @override
  String get studyHub => 'Study Hub';

  @override
  String get currentJourney => 'Current Journey';

  @override
  String get recentRevelations => 'Recent Revelations';

  @override
  String get savedBookmarks => 'Saved Bookmarks';

  @override
  String get continueReading => 'CONTINUE READING';

  @override
  String get startJourney => 'Start your journey today.';

  @override
  String get tapToResume => 'Tap to resume reading';

  @override
  String get tapToOpen => 'Tap to open the Bible';

  @override
  String get noRevelations => 'No revelations yet.';

  @override
  String get noJournalEntries =>
      'No journal entries yet. Add your reflections while reading.';

  @override
  String get myJournal => 'My Journal';

  @override
  String get oldTestament => 'Old Testament';

  @override
  String get newTestament => 'New Testament';

  @override
  String get translationStore => 'Translation Store';

  @override
  String translationsSummary(int total, int bundled) {
    return '$total translations — $bundled built-in, the rest download on demand';
  }

  @override
  String currentlyReading(String name) {
    return 'Currently reading ($name)';
  }

  @override
  String installedTranslation(String name) {
    return 'Installed ($name)';
  }

  @override
  String readyToInstall(String name) {
    return 'Ready to install ($name)';
  }

  @override
  String readyToDownload(String name) {
    return 'Ready to download — needs internet ($name)';
  }

  @override
  String get downloadFailed => 'Download failed — check your connection';

  @override
  String get remove => 'Remove';

  @override
  String chapterLabel(int number) {
    return 'Chapter $number';
  }

  @override
  String get selectBook => 'Select Book';

  @override
  String get selectChapter => 'Select Chapter';

  @override
  String get selectTranslation => 'Select Translation';

  @override
  String get selectVersion => 'Select Version';

  @override
  String get parallelTranslation => 'Parallel Translation';

  @override
  String get writeRevelation => 'Write your revelation…';

  @override
  String get sealRevelation => 'Seal Revelation';

  @override
  String get revelationSealed => 'Revelation Sealed';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get audioComingSoon => 'Audio Player coming soon!';

  @override
  String get pleaseSelectBook => 'Please select a book';

  @override
  String get noVersesFound => 'No verses found';

  @override
  String get navPlans => 'Plans';

  @override
  String get readingPlans => 'Reading Plans';

  @override
  String readingStreak(int days) {
    return '$days-day streak';
  }

  @override
  String get startPlan => 'Start Plan';

  @override
  String get continuePlan => 'Continue';

  @override
  String dayLabel(int number) {
    return 'Day $number';
  }

  @override
  String daysCompleted(int done, int total) {
    return '$done of $total days completed';
  }

  @override
  String get planBibleYearTitle => 'Bible in a Year';

  @override
  String get planBibleYearDesc =>
      'Read the whole Bible in 365 days, a few chapters at a time.';

  @override
  String get planNt90Title => 'New Testament in 90 Days';

  @override
  String get planNt90Desc => 'From Matthew to Revelation in three months.';

  @override
  String get planGospels30Title => 'The Gospels in 30 Days';

  @override
  String get planGospels30Desc =>
      'Walk with Jesus through Matthew, Mark, Luke, and John.';

  @override
  String get planPsalms30Title => 'Psalms in 30 Days';

  @override
  String get planPsalms30Desc =>
      'Five psalms a day for a month of prayer and praise.';

  @override
  String get planProverbs31Title => 'Proverbs in a Month';

  @override
  String get planProverbs31Desc =>
      'One chapter of wisdom for every day of the month.';

  @override
  String get shareAsImage => 'Share as Image';

  @override
  String get shareImageFailed =>
      'Couldn\'t create the image — please try again.';

  @override
  String get dailyReminder => 'Daily reading reminder';

  @override
  String get dailyReminderHint => 'A gentle nudge to keep your streak alive.';

  @override
  String get reminderTime => 'Reminder time';

  @override
  String get reminderNotificationTitle => 'Time for today\'s reading 📖';

  @override
  String get reminderNotificationBody =>
      'A few minutes in the Word keeps your streak going.';

  @override
  String get notificationsDenied =>
      'Notifications are turned off. Allow them in your phone\'s Settings to get reminders.';

  @override
  String get prayerList => 'Prayer List';

  @override
  String get addPrayer => 'Add Prayer';

  @override
  String get prayerHint => 'What\'s on your heart to pray for?';

  @override
  String get noPrayersHint =>
      'Your prayer list is empty.\nAdd what\'s on your heart.';

  @override
  String get activePrayers => 'Active';

  @override
  String get answeredPrayers => 'Answered';

  @override
  String get markAnswered => 'Mark as answered';

  @override
  String answeredOn(String date) {
    return 'Answered $date';
  }

  @override
  String prayersActive(int count) {
    return '$count active prayers';
  }

  @override
  String get prayerDeleted => 'Prayer removed';

  @override
  String get undo => 'Undo';

  @override
  String get cancel => 'Cancel';

  @override
  String get verseOfTheDay => 'Verse of the Day';

  @override
  String get verseOfDayHint =>
      'A verse each morning to start your day in the Word.';

  @override
  String get drawerHeader => 'Menu & Translations';

  @override
  String get getMoreTranslations => 'Get More Translations';

  @override
  String get removeTranslation => 'Remove';

  @override
  String get popularThemes => 'Popular Themes';

  @override
  String get recentSearches => 'Recent Searches';

  @override
  String get themeLove => 'Love';

  @override
  String get themeFaith => 'Faith';

  @override
  String get themeHope => 'Hope';

  @override
  String get bibleGames => 'Bible Games';

  @override
  String get bibleGamesHint => 'Test your Bible knowledge';

  @override
  String get gameGuessReference => 'Guess the Reference';

  @override
  String get gameGuessReferenceDesc => 'Which passage is this verse from?';

  @override
  String get gameFillBlank => 'Fill in the Blank';

  @override
  String get gameFillBlankDesc => 'Choose the missing word.';

  @override
  String get gameVerseBuilder => 'Verse Builder';

  @override
  String get gameVerseBuilderDesc => 'Rebuild the verse word by word.';

  @override
  String questionOf(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String verseOf(int current, int total) {
    return 'Verse $current of $total';
  }

  @override
  String get correctAnswer => 'Correct!';

  @override
  String get wrongAnswer => 'Not quite — the answer is highlighted.';

  @override
  String get nextQuestion => 'Next';

  @override
  String get finishGame => 'Finish';

  @override
  String get playAgain => 'Play Again';

  @override
  String get yourScore => 'Your score';

  @override
  String bestScoreLabel(int score) {
    return 'Best: $score';
  }

  @override
  String scrambleMistakes(int count) {
    return '$count wrong taps';
  }

  @override
  String get gamePerfect => 'Perfect!';

  @override
  String get gameWellDone => 'Well done!';

  @override
  String get gameKeepPracticing => 'Keep practicing — the Word is worth it.';
}
