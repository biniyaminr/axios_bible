import 'package:flutter/foundation.dart';

import 'book_catalog.dart';
import 'l10n/app_localizations.dart';
import 'user_data_store.dart';

/// One chapter to read: canonical book ID + chapter number.
@immutable
class PlanReading {
  final String bookId;
  final int chapter;
  const PlanReading(this.bookId, this.chapter);
}

/// A reading plan: a fixed schedule of days, each with a few chapters.
/// Titles/descriptions are localized through AppLocalizations by plan id.
class ReadingPlan {
  final String id;
  final List<List<PlanReading>> schedule;

  const ReadingPlan({required this.id, required this.schedule});

  int get totalDays => schedule.length;

  String title(AppLocalizations l10n) => switch (id) {
    'bible_in_a_year' => l10n.planBibleYearTitle,
    'nt_90' => l10n.planNt90Title,
    'gospels_30' => l10n.planGospels30Title,
    'psalms_30' => l10n.planPsalms30Title,
    'proverbs_31' => l10n.planProverbs31Title,
    _ => id,
  };

  String description(AppLocalizations l10n) => switch (id) {
    'bible_in_a_year' => l10n.planBibleYearDesc,
    'nt_90' => l10n.planNt90Desc,
    'gospels_30' => l10n.planGospels30Desc,
    'psalms_30' => l10n.planPsalms30Desc,
    'proverbs_31' => l10n.planProverbs31Desc,
    _ => '',
  };
}

/// Spreads every chapter of [books] evenly across [days] days, in order.
List<List<PlanReading>> _spread(List<(String, int)> books, int days) {
  final chapters = <PlanReading>[
    for (final (id, count) in books)
      for (var c = 1; c <= count; c++) PlanReading(id, c),
  ];
  final schedule = <List<PlanReading>>[];
  var start = 0;
  for (var day = 0; day < days; day++) {
    // Distribute remainders evenly so day sizes differ by at most one.
    final end = start + ((chapters.length - start) / (days - day)).ceil();
    schedule.add(chapters.sublist(start, end));
    start = end;
  }
  return schedule;
}

List<(String, int)> _booksFrom(String firstId, String lastId) {
  final first = canonicalBooks.indexWhere((b) => b.$1 == firstId);
  final last = canonicalBooks.indexWhere((b) => b.$1 == lastId);
  return canonicalBooks.sublist(first, last + 1);
}

/// The built-in plans. Generated once, lazily.
final List<ReadingPlan> builtInPlans = [
  ReadingPlan(id: 'bible_in_a_year', schedule: _spread(canonicalBooks, 365)),
  ReadingPlan(id: 'nt_90', schedule: _spread(_booksFrom('MAT', 'REV'), 90)),
  ReadingPlan(
    id: 'gospels_30',
    schedule: _spread(_booksFrom('MAT', 'JHN'), 30),
  ),
  ReadingPlan(id: 'psalms_30', schedule: _spread(_booksFrom('PSA', 'PSA'), 30)),
  ReadingPlan(
    id: 'proverbs_31',
    schedule: _spread(_booksFrom('PRO', 'PRO'), 31),
  ),
];

/// Tracks which plans are started and which days are completed.
class ReadingPlanProvider extends ChangeNotifier {
  final Map<String, DateTime> _started = {};
  final Map<String, Set<int>> _completedDays = {};
  List<DateTime> _completionDates = [];
  bool _loaded = false;

  ReadingPlanProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      _started
        ..clear()
        ..addAll(await UserDataStore.instance.loadStartedPlans());
      _completedDays
        ..clear()
        ..addAll(await UserDataStore.instance.loadPlanProgress());
      _completionDates = await UserDataStore.instance.loadPlanCompletionDates();
      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading reading plans: $e');
    }
  }

  bool get isLoaded => _loaded;

  List<ReadingPlan> get plans => builtInPlans;

  bool isStarted(String planId) => _started.containsKey(planId);

  Set<int> completedDays(String planId) => _completedDays[planId] ?? const {};

  bool isDayCompleted(String planId, int day) =>
      completedDays(planId).contains(day);

  double progress(ReadingPlan plan) =>
      plan.totalDays == 0 ? 0 : completedDays(plan.id).length / plan.totalDays;

  /// First not-yet-completed day (0-based), for "continue" affordances.
  int currentDay(ReadingPlan plan) {
    final done = completedDays(plan.id);
    for (var d = 0; d < plan.totalDays; d++) {
      if (!done.contains(d)) return d;
    }
    return plan.totalDays - 1;
  }

  Future<void> startPlan(String planId) async {
    if (_started.containsKey(planId)) return;
    final now = DateTime.now();
    _started[planId] = now;
    notifyListeners();
    try {
      await UserDataStore.instance.startPlan(planId, now);
    } catch (e) {
      debugPrint('Error starting plan: $e');
    }
  }

  Future<void> toggleDay(String planId, int day) async {
    final days = _completedDays.putIfAbsent(planId, () => <int>{});
    final completed = !days.contains(day);
    if (completed) {
      days.add(day);
    } else {
      days.remove(day);
    }
    notifyListeners();
    try {
      await UserDataStore.instance.setPlanDay(planId, day, completed);
      _completionDates = await UserDataStore.instance.loadPlanCompletionDates();
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving plan progress: $e');
    }
  }

  /// Days in a row ending today (or yesterday) with at least one completed
  /// plan day — the reading streak shown on the plans screen.
  int get streak {
    final dates = <DateTime>{};
    // Streak is derived from completion timestamps stored per plan day.
    for (final entry in _completionDates) {
      dates.add(DateTime(entry.year, entry.month, entry.day));
    }
    if (dates.isEmpty) return 0;
    var day = DateTime.now();
    day = DateTime(day.year, day.month, day.day);
    if (!dates.contains(day)) {
      // Allow the streak to survive until the end of today.
      day = day.subtract(const Duration(days: 1));
      if (!dates.contains(day)) return 0;
    }
    var count = 0;
    while (dates.contains(day)) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }

  @visibleForTesting
  set completionDatesForTest(List<DateTime> dates) {
    _completionDates = dates;
  }
}
