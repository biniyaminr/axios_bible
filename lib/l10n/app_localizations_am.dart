// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Amharic (`am`).
class AppLocalizationsAm extends AppLocalizations {
  AppLocalizationsAm([String locale = 'am']) : super(locale);

  @override
  String get appTitle => 'የአማርኛ መጽሐፍ ቅዱስ';

  @override
  String get navHome => 'መነሻ';

  @override
  String get navBible => 'መጽሐፍ ቅዱስ';

  @override
  String get navSearch => 'ፈልግ';

  @override
  String get navBookmarks => 'ዕልባቶች';

  @override
  String get settings => 'ማስተካከያዎች';

  @override
  String get theme => 'ገጽታ';

  @override
  String get themeSystem => 'የስርዓት';

  @override
  String get themeLight => 'ብርሃን';

  @override
  String get themeDark => 'ጨለማ';

  @override
  String get fontSize => 'የፊደል መጠን';

  @override
  String get audioSpeed => 'የድምፅ ፍጥነት';

  @override
  String get lineSpacing => 'የመስመር ክፍተት';

  @override
  String get language => 'ቋንቋ';

  @override
  String get languageSystem => 'የስርዓት';

  @override
  String get bookmarksTitle => 'ዕልባቶች';

  @override
  String get noBookmarks => 'ምንም ዕልባቶች የሉም።';

  @override
  String get noBookmarksHint => 'ምንም ዕልባቶች የሉም። ትርጉም ያላቸውን ጥቅሶች ያስቀምጡ።';

  @override
  String get searchBibleTitle => 'መጽሐፍ ቅዱስ ፈልግ';

  @override
  String get searchHint => 'ቃላትን ወይም ጥቅሶችን ይፈልጉ…';

  @override
  String get searchTranslationsHint => 'ትርጉም ይፈልጉ…';

  @override
  String get filterVerses => 'ጥቅሶች';

  @override
  String get filterChapters => 'ምዕራፎች';

  @override
  String get filterTexts => 'ጽሑፎች';

  @override
  String get noResults => 'ምንም ውጤት አልተገኘም…';

  @override
  String get clear => 'አጽዳ';

  @override
  String get studyHub => 'የጥናት ማዕከል';

  @override
  String get currentJourney => 'የአሁኑ ጉዞ';

  @override
  String get recentRevelations => 'የቅርብ ጊዜ ራእዮች';

  @override
  String get savedBookmarks => 'የተቀመጡ ዕልባቶች';

  @override
  String get continueReading => 'ንባብ ይቀጥሉ';

  @override
  String get startJourney => 'ጉዞዎን ዛሬ ይጀምሩ።';

  @override
  String get tapToResume => 'ንባብ ለመቀጠል ይንኩ';

  @override
  String get tapToOpen => 'መጽሐፍ ቅዱስን ለመክፈት ይንኩ';

  @override
  String get noRevelations => 'እስካሁን ራእይ የለም።';

  @override
  String get noJournalEntries => 'እስካሁን ማስታወሻ የለም። ሲያነቡ ሀሳብዎን ያስፍሩ።';

  @override
  String get myJournal => 'ማስታወሻዬ';

  @override
  String get oldTestament => 'ብሉይ ኪዳን';

  @override
  String get newTestament => 'ሐዲስ ኪዳን';

  @override
  String get translationStore => 'የትርጉም ማዕከል';

  @override
  String translationsSummary(int total, int bundled) {
    return '$total ትርጉሞች — $bundled አብረው የተጫኑ፣ ቀሪዎቹ በፍላጎት ይወርዳሉ';
  }

  @override
  String currentlyReading(String name) {
    return 'በንባብ ላይ ($name)';
  }

  @override
  String installedTranslation(String name) {
    return 'ተጭኗል ($name)';
  }

  @override
  String readyToInstall(String name) {
    return 'ለመጫን ዝግጁ ($name)';
  }

  @override
  String readyToDownload(String name) {
    return 'ለማውረድ ዝግጁ — ኢንተርኔት ያስፈልጋል ($name)';
  }

  @override
  String get downloadFailed => 'ማውረድ አልተሳካም — ኢንተርኔት ግንኙነትዎን ያረጋግጡ';

  @override
  String get remove => 'አስወግድ';

  @override
  String chapterLabel(int number) {
    return 'ምዕራፍ $number';
  }

  @override
  String get selectBook => 'መጽሐፍ ይምረጡ';

  @override
  String get selectChapter => 'ምዕራፍ ይምረጡ';

  @override
  String get selectTranslation => 'ትርጉም ይምረጡ';

  @override
  String get selectVersion => 'ትርጉም ይምረጡ';

  @override
  String get parallelTranslation => 'ትይዩ ትርጉም';

  @override
  String get writeRevelation => 'ራእይዎን ይጻፉ…';

  @override
  String get sealRevelation => 'ራእይ አትም';

  @override
  String get revelationSealed => 'ራእይ ታትሟል';

  @override
  String get copiedToClipboard => 'ተቀድቷል';

  @override
  String get audioComingSoon => 'የድምፅ ማጫወቻ በቅርቡ ይመጣል!';

  @override
  String get pleaseSelectBook => 'እባክዎ መጽሐፍ ይምረጡ';

  @override
  String get noVersesFound => 'ምንም ጥቅስ አልተገኘም';

  @override
  String get navPlans => 'እቅዶች';

  @override
  String get readingPlans => 'የንባብ እቅዶች';

  @override
  String readingStreak(int days) {
    return 'የ$days ቀን ተከታታይ ንባብ';
  }

  @override
  String get startPlan => 'እቅድ ጀምር';

  @override
  String get continuePlan => 'ይቀጥሉ';

  @override
  String dayLabel(int number) {
    return 'ቀን $number';
  }

  @override
  String daysCompleted(int done, int total) {
    return '$done ከ $total ቀናት ተጠናቀዋል';
  }

  @override
  String get planBibleYearTitle => 'መጽሐፍ ቅዱስ በአንድ ዓመት';

  @override
  String get planBibleYearDesc => 'መላውን መጽሐፍ ቅዱስ በ365 ቀናት፣ በቀን ጥቂት ምዕራፎች ያንብቡ።';

  @override
  String get planNt90Title => 'አዲስ ኪዳን በ90 ቀናት';

  @override
  String get planNt90Desc => 'ከማቴዎስ እስከ ራእይ በሦስት ወራት።';

  @override
  String get planGospels30Title => 'ወንጌላት በ30 ቀናት';

  @override
  String get planGospels30Desc => 'በማቴዎስ፣ ማርቆስ፣ ሉቃስ እና ዮሐንስ ከኢየሱስ ጋር ይጓዙ።';

  @override
  String get planPsalms30Title => 'መዝሙረ ዳዊት በ30 ቀናት';

  @override
  String get planPsalms30Desc => 'ለአንድ ወር ጸሎትና ምስጋና በቀን አምስት መዝሙሮች።';

  @override
  String get planProverbs31Title => 'ምሳሌ በአንድ ወር';

  @override
  String get planProverbs31Desc => 'ለእያንዳንዱ የወሩ ቀን አንድ የጥበብ ምዕራፍ።';

  @override
  String get shareAsImage => 'እንደ ምስል አጋራ';

  @override
  String get shareImageFailed => 'ምስሉን መፍጠር አልተቻለም — እባክዎ እንደገና ይሞክሩ።';

  @override
  String get dailyReminder => 'ዕለታዊ የንባብ አስታዋሽ';

  @override
  String get dailyReminderHint => 'ተከታታይ ንባብዎን ለመጠበቅ የሚረዳ ማሳሰቢያ።';

  @override
  String get reminderTime => 'የአስታዋሽ ሰዓት';

  @override
  String get reminderNotificationTitle => 'የዛሬው ንባብ ጊዜ ደርሷል 📖';

  @override
  String get reminderNotificationBody => 'በቃሉ ጥቂት ደቂቃዎች ተከታታይ ንባብዎን ይጠብቃሉ።';

  @override
  String get notificationsDenied =>
      'ማሳወቂያዎች ጠፍተዋል። አስታዋሾችን ለማግኘት በስልክዎ ቅንብሮች ውስጥ ይፍቀዱ።';

  @override
  String get prayerList => 'የጸሎት ዝርዝር';

  @override
  String get addPrayer => 'ጸሎት ጨምር';

  @override
  String get prayerHint => 'ስለ ምን መጸለይ ይፈልጋሉ?';

  @override
  String get noPrayersHint => 'የጸሎት ዝርዝርዎ ባዶ ነው።\nበልብዎ ያለውን ይጨምሩ።';

  @override
  String get activePrayers => 'በጸሎት ላይ';

  @override
  String get answeredPrayers => 'የተመለሱ';

  @override
  String get markAnswered => 'እንደተመለሰ ምልክት ያድርጉ';

  @override
  String answeredOn(String date) {
    return 'የተመለሰው $date';
  }

  @override
  String prayersActive(int count) {
    return '$count ጸሎቶች በሂደት ላይ';
  }

  @override
  String get prayerDeleted => 'ጸሎቱ ተወግዷል';

  @override
  String get undo => 'ቀልብስ';

  @override
  String get cancel => 'ይቅር';

  @override
  String get verseOfTheDay => 'የዕለቱ ጥቅስ';

  @override
  String get verseOfDayHint => 'ቀንዎን በቃሉ ለመጀመር በየጠዋቱ አንድ ጥቅስ።';

  @override
  String get drawerHeader => 'ምናሌ እና ትርጉሞች';

  @override
  String get getMoreTranslations => 'ተጨማሪ ትርጉሞች ያግኙ';

  @override
  String get removeTranslation => 'አስወግድ';

  @override
  String get popularThemes => 'ተወዳጅ ጭብጦች';

  @override
  String get recentSearches => 'የቅርብ ጊዜ ፍለጋዎች';

  @override
  String get themeLove => 'ፍቅር';

  @override
  String get themeFaith => 'እምነት';

  @override
  String get themeHope => 'ተስፋ';

  @override
  String get bibleGames => 'የመጽሐፍ ቅዱስ ጨዋታዎች';

  @override
  String get bibleGamesHint => 'የመጽሐፍ ቅዱስ እውቀትዎን ይፈትኑ';

  @override
  String get gameGuessReference => 'ጥቅሱ ከየት ነው?';

  @override
  String get gameGuessReferenceDesc => 'ይህ ጥቅስ ከየትኛው ክፍል ነው?';

  @override
  String get gameFillBlank => 'ባዶውን ሙላ';

  @override
  String get gameFillBlankDesc => 'የጎደለውን ቃል ይምረጡ።';

  @override
  String get gameVerseBuilder => 'ጥቅስ ገንቢ';

  @override
  String get gameVerseBuilderDesc => 'ጥቅሱን ቃል በቃል መልሰው ይገንቡ።';

  @override
  String questionOf(int current, int total) {
    return 'ጥያቄ $current ከ $total';
  }

  @override
  String verseOf(int current, int total) {
    return 'ጥቅስ $current ከ $total';
  }

  @override
  String get correctAnswer => 'ትክክል!';

  @override
  String get wrongAnswer => 'አልተሳካም — ትክክለኛው መልስ ተመልክቷል።';

  @override
  String get nextQuestion => 'ቀጣይ';

  @override
  String get finishGame => 'ጨርስ';

  @override
  String get playAgain => 'እንደገና ይጫወቱ';

  @override
  String get yourScore => 'የእርስዎ ነጥብ';

  @override
  String bestScoreLabel(int score) {
    return 'ምርጥ ነጥብ፦ $score';
  }

  @override
  String scrambleMistakes(int count) {
    return '$count የተሳሳቱ ንክኪዎች';
  }

  @override
  String get gamePerfect => 'እንከን የለሽ!';

  @override
  String get gameWellDone => 'ጎበዝ!';

  @override
  String get gameKeepPracticing => 'መለማመዱን ይቀጥሉ — ቃሉ ዋጋ አለው።';
}
