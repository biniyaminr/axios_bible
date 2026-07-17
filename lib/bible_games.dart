import 'dart:math';

/// Game content generated from the Bible text itself, so every game works
/// in whatever translation (and language) the user is reading — no authored
/// question bank required.
///
/// All generators take the resolved curated verses
/// (`{'reference': ..., 'text': ...}`, already in the current translation)
/// and an injectable [Random] so tests can be deterministic.

/// One multiple-choice question. [options] always contains the correct
/// answer exactly once, at [correctIndex].
class QuizQuestion {
  final String prompt;
  final List<String> options;
  final int correctIndex;

  /// The verse reference, shown after answering.
  final String reference;

  const QuizQuestion({
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.reference,
  });

  String get correctAnswer => options[correctIndex];
}

/// Verses usable as game material: non-empty text and a real reference.
List<Map<String, String>> playableVerses(List<Map<String, String>> verses) {
  return verses
      .where(
        (v) =>
            (v['text'] ?? '').trim().isNotEmpty &&
            v['text'] != 'Verse not found' &&
            (v['reference'] ?? '').trim().isNotEmpty,
      )
      .toList();
}

/// "Which reference does this verse belong to?" — the prompt is the verse
/// text, the options are four references.
List<QuizQuestion> buildReferenceQuiz(
  List<Map<String, String>> verses,
  int count,
  Random rng,
) {
  final pool = playableVerses(verses);
  if (pool.length < 4) return [];

  final picks = List.of(pool)..shuffle(rng);
  final questions = <QuizQuestion>[];
  for (final verse in picks.take(count)) {
    final distractors =
        pool
            .where((v) => v['reference'] != verse['reference'])
            .map((v) => v['reference']!)
            .toSet()
            .toList()
          ..shuffle(rng);
    final options = [verse['reference']!, ...distractors.take(3)]..shuffle(rng);
    questions.add(
      QuizQuestion(
        prompt: verse['text']!,
        options: options,
        correctIndex: options.indexOf(verse['reference']!),
        reference: verse['reference']!,
      ),
    );
  }
  return questions;
}

/// "Choose the missing word." — one word of the verse is replaced with a
/// blank; distractor words come from the other verses, so they are always
/// in the same language as the text.
List<QuizQuestion> buildFillBlankQuiz(
  List<Map<String, String>> verses,
  int count,
  Random rng,
) {
  final pool = playableVerses(verses);
  if (pool.length < 4) return [];

  // Candidate words per verse: not the first word, reasonably long, and
  // stripped of trailing punctuation so options look clean.
  String clean(String word) =>
      word.replaceAll(RegExp(r'[፡።፣፤፥፦,;:.!?"“”‘’()\[\]]'), '');

  List<String> words(String text) =>
      text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

  final picks = List.of(pool)..shuffle(rng);
  final questions = <QuizQuestion>[];

  for (final verse in picks) {
    if (questions.length >= count) break;
    final verseWords = words(verse['text']!);
    if (verseWords.length < 4) continue;

    final candidates = <int>[
      for (var i = 1; i < verseWords.length; i++)
        if (clean(verseWords[i]).length >= 3) i,
    ];
    if (candidates.isEmpty) continue;

    final blankIndex = candidates[rng.nextInt(candidates.length)];
    final answer = clean(verseWords[blankIndex]);

    // Distractors: words of similar length from other verses.
    final distractorPool = <String>{};
    for (final other in pool) {
      if (other['reference'] == verse['reference']) continue;
      for (final w in words(other['text']!)) {
        final c = clean(w);
        if (c.length >= 3 && c != answer) distractorPool.add(c);
      }
    }
    if (distractorPool.length < 3) continue;

    final distractors = distractorPool.toList()
      ..sort(
        (a, b) =>
            (a.length - answer.length).abs() - (b.length - answer.length).abs(),
      );
    final near = distractors.take(12).toList()..shuffle(rng);

    final prompt = [
      for (var i = 0; i < verseWords.length; i++)
        i == blankIndex ? '____' : verseWords[i],
    ].join(' ');

    final options = [answer, ...near.take(3)]..shuffle(rng);
    questions.add(
      QuizQuestion(
        prompt: prompt,
        options: options,
        correctIndex: options.indexOf(answer),
        reference: verse['reference']!,
      ),
    );
  }
  return questions;
}

/// One verse-builder round: tap the [shuffled] words in the order of
/// [words] to rebuild the verse.
class ScrambleRound {
  final List<String> words;
  final List<String> shuffled;
  final String reference;

  const ScrambleRound({
    required this.words,
    required this.shuffled,
    required this.reference,
  });
}

/// Prefers short verses that fit whole; long verses are cut to their first
/// [maxWords] words so the tap targets stay manageable.
List<ScrambleRound> buildScrambleRounds(
  List<Map<String, String>> verses,
  int count,
  Random rng, {
  int maxWords = 12,
}) {
  final pool = playableVerses(verses);
  if (pool.isEmpty) return [];

  final picks = List.of(pool)
    ..shuffle(rng)
    ..sort(
      (a, b) =>
          a['text']!.split(' ').length.compareTo(b['text']!.split(' ').length),
    );

  final rounds = <ScrambleRound>[];
  for (final verse in picks.take(count)) {
    var words = verse['text']!
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.length < 3) continue;
    if (words.length > maxWords) words = words.sublist(0, maxWords);

    var shuffled = List.of(words)..shuffle(rng);
    // A shuffle can come back in reading order; rotate to guarantee work.
    if (_sameOrder(words, shuffled) && words.length > 1) {
      shuffled = [...shuffled.sublist(1), shuffled.first];
    }
    rounds.add(
      ScrambleRound(
        words: words,
        shuffled: shuffled,
        reference: verse['reference']!,
      ),
    );
  }
  rounds.shuffle(rng);
  return rounds;
}

bool _sameOrder(List<String> a, List<String> b) {
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// The daily challenge: five questions seeded by the calendar date, so the
/// whole church gets the same challenge on the same day.
List<QuizQuestion> buildDailyChallenge(
  List<Map<String, String>> verses,
  DateTime date,
) {
  final rng = Random(date.year * 10000 + date.month * 100 + date.day);
  final questions = [
    ...buildReferenceQuiz(verses, 3, rng),
    ...buildFillBlankQuiz(verses, 2, rng),
  ]..shuffle(rng);
  return questions.take(5).toList();
}

/// Streak after completing today's challenge. [lastDate] is the previous
/// completion day as 'yyyy-mm-dd' (null when never played).
int challengeStreakAfterCompletion({
  required String? lastDate,
  required int streak,
  required DateTime today,
}) {
  final todayKey = dateKey(today);
  if (lastDate == todayKey) return streak; // already completed today
  final yesterday = dateKey(today.subtract(const Duration(days: 1)));
  return lastDate == yesterday ? streak + 1 : 1;
}

/// Whether a stored streak is still alive on [today] (completed today or
/// yesterday); otherwise it should display as zero.
bool challengeStreakAlive({
  required String? lastDate,
  required DateTime today,
}) {
  if (lastDate == null) return false;
  return lastDate == dateKey(today) ||
      lastDate == dateKey(today.subtract(const Duration(days: 1)));
}

String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
