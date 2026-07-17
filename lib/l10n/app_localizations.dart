import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('am'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Axios Bible'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navBible.
  ///
  /// In en, this message translates to:
  /// **'Bible'**
  String get navBible;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get navBookmarks;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSize;

  /// No description provided for @audioSpeed.
  ///
  /// In en, this message translates to:
  /// **'Audio Speed'**
  String get audioSpeed;

  /// No description provided for @lineSpacing.
  ///
  /// In en, this message translates to:
  /// **'Line Spacing'**
  String get lineSpacing;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @bookmarksTitle.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarksTitle;

  /// No description provided for @noBookmarks.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet.'**
  String get noBookmarks;

  /// No description provided for @noBookmarksHint.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet. Save meaningful verses to find them quickly.'**
  String get noBookmarksHint;

  /// No description provided for @searchBibleTitle.
  ///
  /// In en, this message translates to:
  /// **'Search the Bible'**
  String get searchBibleTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search words or verses…'**
  String get searchHint;

  /// No description provided for @searchTranslationsHint.
  ///
  /// In en, this message translates to:
  /// **'Search translations…'**
  String get searchTranslationsHint;

  /// No description provided for @filterVerses.
  ///
  /// In en, this message translates to:
  /// **'Verses'**
  String get filterVerses;

  /// No description provided for @filterChapters.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get filterChapters;

  /// No description provided for @filterTexts.
  ///
  /// In en, this message translates to:
  /// **'Texts'**
  String get filterTexts;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found…'**
  String get noResults;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @studyHub.
  ///
  /// In en, this message translates to:
  /// **'Study Hub'**
  String get studyHub;

  /// No description provided for @currentJourney.
  ///
  /// In en, this message translates to:
  /// **'Current Journey'**
  String get currentJourney;

  /// No description provided for @recentRevelations.
  ///
  /// In en, this message translates to:
  /// **'Recent Revelations'**
  String get recentRevelations;

  /// No description provided for @savedBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Saved Bookmarks'**
  String get savedBookmarks;

  /// No description provided for @continueReading.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE READING'**
  String get continueReading;

  /// No description provided for @startJourney.
  ///
  /// In en, this message translates to:
  /// **'Start your journey today.'**
  String get startJourney;

  /// No description provided for @tapToResume.
  ///
  /// In en, this message translates to:
  /// **'Tap to resume reading'**
  String get tapToResume;

  /// No description provided for @tapToOpen.
  ///
  /// In en, this message translates to:
  /// **'Tap to open the Bible'**
  String get tapToOpen;

  /// No description provided for @noRevelations.
  ///
  /// In en, this message translates to:
  /// **'No revelations yet.'**
  String get noRevelations;

  /// No description provided for @noJournalEntries.
  ///
  /// In en, this message translates to:
  /// **'No journal entries yet. Add your reflections while reading.'**
  String get noJournalEntries;

  /// No description provided for @myJournal.
  ///
  /// In en, this message translates to:
  /// **'My Journal'**
  String get myJournal;

  /// No description provided for @oldTestament.
  ///
  /// In en, this message translates to:
  /// **'Old Testament'**
  String get oldTestament;

  /// No description provided for @newTestament.
  ///
  /// In en, this message translates to:
  /// **'New Testament'**
  String get newTestament;

  /// No description provided for @translationStore.
  ///
  /// In en, this message translates to:
  /// **'Translation Store'**
  String get translationStore;

  /// No description provided for @translationsSummary.
  ///
  /// In en, this message translates to:
  /// **'{total} translations — {bundled} built-in, the rest download on demand'**
  String translationsSummary(int total, int bundled);

  /// No description provided for @currentlyReading.
  ///
  /// In en, this message translates to:
  /// **'Currently reading ({name})'**
  String currentlyReading(String name);

  /// No description provided for @installedTranslation.
  ///
  /// In en, this message translates to:
  /// **'Installed ({name})'**
  String installedTranslation(String name);

  /// No description provided for @readyToInstall.
  ///
  /// In en, this message translates to:
  /// **'Ready to install ({name})'**
  String readyToInstall(String name);

  /// No description provided for @readyToDownload.
  ///
  /// In en, this message translates to:
  /// **'Ready to download — needs internet ({name})'**
  String readyToDownload(String name);

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed — check your connection'**
  String get downloadFailed;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @chapterLabel.
  ///
  /// In en, this message translates to:
  /// **'Chapter {number}'**
  String chapterLabel(int number);

  /// No description provided for @selectBook.
  ///
  /// In en, this message translates to:
  /// **'Select Book'**
  String get selectBook;

  /// No description provided for @selectChapter.
  ///
  /// In en, this message translates to:
  /// **'Select Chapter'**
  String get selectChapter;

  /// No description provided for @selectTranslation.
  ///
  /// In en, this message translates to:
  /// **'Select Translation'**
  String get selectTranslation;

  /// No description provided for @selectVersion.
  ///
  /// In en, this message translates to:
  /// **'Select Version'**
  String get selectVersion;

  /// No description provided for @parallelTranslation.
  ///
  /// In en, this message translates to:
  /// **'Parallel Translation'**
  String get parallelTranslation;

  /// No description provided for @writeRevelation.
  ///
  /// In en, this message translates to:
  /// **'Write your revelation…'**
  String get writeRevelation;

  /// No description provided for @sealRevelation.
  ///
  /// In en, this message translates to:
  /// **'Seal Revelation'**
  String get sealRevelation;

  /// No description provided for @revelationSealed.
  ///
  /// In en, this message translates to:
  /// **'Revelation Sealed'**
  String get revelationSealed;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @audioComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Audio Player coming soon!'**
  String get audioComingSoon;

  /// No description provided for @pleaseSelectBook.
  ///
  /// In en, this message translates to:
  /// **'Please select a book'**
  String get pleaseSelectBook;

  /// No description provided for @noVersesFound.
  ///
  /// In en, this message translates to:
  /// **'No verses found'**
  String get noVersesFound;

  /// No description provided for @navPlans.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get navPlans;

  /// No description provided for @readingPlans.
  ///
  /// In en, this message translates to:
  /// **'Reading Plans'**
  String get readingPlans;

  /// No description provided for @readingStreak.
  ///
  /// In en, this message translates to:
  /// **'{days}-day streak'**
  String readingStreak(int days);

  /// No description provided for @startPlan.
  ///
  /// In en, this message translates to:
  /// **'Start Plan'**
  String get startPlan;

  /// No description provided for @continuePlan.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continuePlan;

  /// No description provided for @dayLabel.
  ///
  /// In en, this message translates to:
  /// **'Day {number}'**
  String dayLabel(int number);

  /// No description provided for @daysCompleted.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} days completed'**
  String daysCompleted(int done, int total);

  /// No description provided for @planBibleYearTitle.
  ///
  /// In en, this message translates to:
  /// **'Bible in a Year'**
  String get planBibleYearTitle;

  /// No description provided for @planBibleYearDesc.
  ///
  /// In en, this message translates to:
  /// **'Read the whole Bible in 365 days, a few chapters at a time.'**
  String get planBibleYearDesc;

  /// No description provided for @planNt90Title.
  ///
  /// In en, this message translates to:
  /// **'New Testament in 90 Days'**
  String get planNt90Title;

  /// No description provided for @planNt90Desc.
  ///
  /// In en, this message translates to:
  /// **'From Matthew to Revelation in three months.'**
  String get planNt90Desc;

  /// No description provided for @planGospels30Title.
  ///
  /// In en, this message translates to:
  /// **'The Gospels in 30 Days'**
  String get planGospels30Title;

  /// No description provided for @planGospels30Desc.
  ///
  /// In en, this message translates to:
  /// **'Walk with Jesus through Matthew, Mark, Luke, and John.'**
  String get planGospels30Desc;

  /// No description provided for @planPsalms30Title.
  ///
  /// In en, this message translates to:
  /// **'Psalms in 30 Days'**
  String get planPsalms30Title;

  /// No description provided for @planPsalms30Desc.
  ///
  /// In en, this message translates to:
  /// **'Five psalms a day for a month of prayer and praise.'**
  String get planPsalms30Desc;

  /// No description provided for @planProverbs31Title.
  ///
  /// In en, this message translates to:
  /// **'Proverbs in a Month'**
  String get planProverbs31Title;

  /// No description provided for @planProverbs31Desc.
  ///
  /// In en, this message translates to:
  /// **'One chapter of wisdom for every day of the month.'**
  String get planProverbs31Desc;

  /// No description provided for @shareAsImage.
  ///
  /// In en, this message translates to:
  /// **'Share as Image'**
  String get shareAsImage;

  /// No description provided for @shareImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the image — please try again.'**
  String get shareImageFailed;

  /// No description provided for @dailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily reading reminder'**
  String get dailyReminder;

  /// No description provided for @dailyReminderHint.
  ///
  /// In en, this message translates to:
  /// **'A gentle nudge to keep your streak alive.'**
  String get dailyReminderHint;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get reminderTime;

  /// No description provided for @reminderNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Time for today\'s reading 📖'**
  String get reminderNotificationTitle;

  /// No description provided for @reminderNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'A few minutes in the Word keeps your streak going.'**
  String get reminderNotificationBody;

  /// No description provided for @notificationsDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are turned off. Allow them in your phone\'s Settings to get reminders.'**
  String get notificationsDenied;

  /// No description provided for @prayerList.
  ///
  /// In en, this message translates to:
  /// **'Prayer List'**
  String get prayerList;

  /// No description provided for @addPrayer.
  ///
  /// In en, this message translates to:
  /// **'Add Prayer'**
  String get addPrayer;

  /// No description provided for @prayerHint.
  ///
  /// In en, this message translates to:
  /// **'What\'s on your heart to pray for?'**
  String get prayerHint;

  /// No description provided for @noPrayersHint.
  ///
  /// In en, this message translates to:
  /// **'Your prayer list is empty.\nAdd what\'s on your heart.'**
  String get noPrayersHint;

  /// No description provided for @activePrayers.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activePrayers;

  /// No description provided for @answeredPrayers.
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get answeredPrayers;

  /// No description provided for @markAnswered.
  ///
  /// In en, this message translates to:
  /// **'Mark as answered'**
  String get markAnswered;

  /// No description provided for @answeredOn.
  ///
  /// In en, this message translates to:
  /// **'Answered {date}'**
  String answeredOn(String date);

  /// No description provided for @prayersActive.
  ///
  /// In en, this message translates to:
  /// **'{count} active prayers'**
  String prayersActive(int count);

  /// No description provided for @prayerDeleted.
  ///
  /// In en, this message translates to:
  /// **'Prayer removed'**
  String get prayerDeleted;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @verseOfTheDay.
  ///
  /// In en, this message translates to:
  /// **'Verse of the Day'**
  String get verseOfTheDay;

  /// No description provided for @verseOfDayHint.
  ///
  /// In en, this message translates to:
  /// **'A verse each morning to start your day in the Word.'**
  String get verseOfDayHint;

  /// No description provided for @drawerHeader.
  ///
  /// In en, this message translates to:
  /// **'Menu & Translations'**
  String get drawerHeader;

  /// No description provided for @getMoreTranslations.
  ///
  /// In en, this message translates to:
  /// **'Get More Translations'**
  String get getMoreTranslations;

  /// No description provided for @removeTranslation.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeTranslation;

  /// No description provided for @popularThemes.
  ///
  /// In en, this message translates to:
  /// **'Popular Themes'**
  String get popularThemes;

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get recentSearches;

  /// No description provided for @themeLove.
  ///
  /// In en, this message translates to:
  /// **'Love'**
  String get themeLove;

  /// No description provided for @themeFaith.
  ///
  /// In en, this message translates to:
  /// **'Faith'**
  String get themeFaith;

  /// No description provided for @themeHope.
  ///
  /// In en, this message translates to:
  /// **'Hope'**
  String get themeHope;

  /// No description provided for @bibleGames.
  ///
  /// In en, this message translates to:
  /// **'Bible Games'**
  String get bibleGames;

  /// No description provided for @bibleGamesHint.
  ///
  /// In en, this message translates to:
  /// **'Test your Bible knowledge'**
  String get bibleGamesHint;

  /// No description provided for @gameGuessReference.
  ///
  /// In en, this message translates to:
  /// **'Guess the Reference'**
  String get gameGuessReference;

  /// No description provided for @gameGuessReferenceDesc.
  ///
  /// In en, this message translates to:
  /// **'Which passage is this verse from?'**
  String get gameGuessReferenceDesc;

  /// No description provided for @gameFillBlank.
  ///
  /// In en, this message translates to:
  /// **'Fill in the Blank'**
  String get gameFillBlank;

  /// No description provided for @gameFillBlankDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose the missing word.'**
  String get gameFillBlankDesc;

  /// No description provided for @gameVerseBuilder.
  ///
  /// In en, this message translates to:
  /// **'Verse Builder'**
  String get gameVerseBuilder;

  /// No description provided for @gameVerseBuilderDesc.
  ///
  /// In en, this message translates to:
  /// **'Rebuild the verse word by word.'**
  String get gameVerseBuilderDesc;

  /// No description provided for @questionOf.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String questionOf(int current, int total);

  /// No description provided for @verseOf.
  ///
  /// In en, this message translates to:
  /// **'Verse {current} of {total}'**
  String verseOf(int current, int total);

  /// No description provided for @correctAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get correctAnswer;

  /// No description provided for @wrongAnswer.
  ///
  /// In en, this message translates to:
  /// **'Not quite — the answer is highlighted.'**
  String get wrongAnswer;

  /// No description provided for @nextQuestion.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextQuestion;

  /// No description provided for @finishGame.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finishGame;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get playAgain;

  /// No description provided for @yourScore.
  ///
  /// In en, this message translates to:
  /// **'Your score'**
  String get yourScore;

  /// No description provided for @bestScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Best: {score}'**
  String bestScoreLabel(int score);

  /// No description provided for @scrambleMistakes.
  ///
  /// In en, this message translates to:
  /// **'{count} wrong taps'**
  String scrambleMistakes(int count);

  /// No description provided for @gamePerfect.
  ///
  /// In en, this message translates to:
  /// **'Perfect!'**
  String get gamePerfect;

  /// No description provided for @gameWellDone.
  ///
  /// In en, this message translates to:
  /// **'Well done!'**
  String get gameWellDone;

  /// No description provided for @gameKeepPracticing.
  ///
  /// In en, this message translates to:
  /// **'Keep practicing — the Word is worth it.'**
  String get gameKeepPracticing;

  /// No description provided for @newSermonNote.
  ///
  /// In en, this message translates to:
  /// **'Sermon Note'**
  String get newSermonNote;

  /// No description provided for @sermonPassage.
  ///
  /// In en, this message translates to:
  /// **'Passage (e.g. John 3)'**
  String get sermonPassage;

  /// No description provided for @sermonSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Preacher'**
  String get sermonSpeaker;

  /// No description provided for @sermonChurch.
  ///
  /// In en, this message translates to:
  /// **'Church'**
  String get sermonChurch;

  /// No description provided for @sermonNoteHint.
  ///
  /// In en, this message translates to:
  /// **'What was preached? What spoke to you?'**
  String get sermonNoteHint;

  /// No description provided for @saveLabel.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveLabel;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @categoryPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get categoryPersonal;

  /// No description provided for @categorySermon.
  ///
  /// In en, this message translates to:
  /// **'Sermon'**
  String get categorySermon;

  /// No description provided for @categoryPrayer.
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get categoryPrayer;

  /// No description provided for @dailyChallenge.
  ///
  /// In en, this message translates to:
  /// **'Daily Challenge'**
  String get dailyChallenge;

  /// No description provided for @dailyChallengeHint.
  ///
  /// In en, this message translates to:
  /// **'5 questions. Every day. Keep the flame alive.'**
  String get dailyChallengeHint;

  /// No description provided for @challengeDoneToday.
  ///
  /// In en, this message translates to:
  /// **'Completed today — {score}/5'**
  String challengeDoneToday(int score);

  /// No description provided for @challengeStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'{days}-day streak'**
  String challengeStreakLabel(int days);

  /// No description provided for @comeBackTomorrow.
  ///
  /// In en, this message translates to:
  /// **'New questions tomorrow!'**
  String get comeBackTomorrow;

  /// No description provided for @playNow.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playNow;

  /// No description provided for @prayerMoment.
  ///
  /// In en, this message translates to:
  /// **'Prayer Moment'**
  String get prayerMoment;

  /// No description provided for @prayerMomentHint.
  ///
  /// In en, this message translates to:
  /// **'Begin each day with a quiet moment of prayer.'**
  String get prayerMomentHint;

  /// No description provided for @prayerMomentTitle.
  ///
  /// In en, this message translates to:
  /// **'Pause. Breathe. Pray.'**
  String get prayerMomentTitle;

  /// No description provided for @prayerMomentPrayers.
  ///
  /// In en, this message translates to:
  /// **'Pray over what\'s on your heart:'**
  String get prayerMomentPrayers;

  /// No description provided for @amen.
  ///
  /// In en, this message translates to:
  /// **'Amen'**
  String get amen;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['am', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
