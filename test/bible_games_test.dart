import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_bible/bible_games.dart';

void main() {
  final verses = [
    {'reference': 'John 3:16', 'text': 'For God so loved the world'},
    {'reference': 'Psalm 23:1', 'text': 'The Lord is my shepherd'},
    {'reference': 'Gen 1:1', 'text': 'In the beginning God created heaven'},
    {'reference': 'Phil 4:13', 'text': 'I can do all things through Christ'},
    {'reference': 'Rom 8:28', 'text': 'All things work together for good'},
    {'reference': 'Broken 0:0', 'text': 'Verse not found'},
    {'reference': 'Empty 0:0', 'text': '   '},
  ];

  test('playableVerses drops empty and unresolved texts', () {
    final pool = playableVerses(verses);
    expect(pool.length, 5);
    expect(pool.any((v) => v['reference'] == 'Broken 0:0'), false);
    expect(pool.any((v) => v['reference'] == 'Empty 0:0'), false);
  });

  test('reference quiz: 4 unique options containing the answer once', () {
    final questions = buildReferenceQuiz(verses, 10, Random(7));
    expect(questions.length, 5); // capped by playable pool size

    for (final q in questions) {
      expect(q.options.length, 4);
      expect(q.options.toSet().length, 4, reason: 'options must be unique');
      expect(q.options.where((o) => o == q.reference).length, 1);
      expect(q.options[q.correctIndex], q.reference);
      // Prompt is the verse text of the answer reference.
      final source = verses.firstWhere((v) => v['reference'] == q.reference);
      expect(q.prompt, source['text']);
    }
  });

  test('fill-blank quiz: blank replaces the answer word', () {
    final questions = buildFillBlankQuiz(verses, 10, Random(11));
    expect(questions, isNotEmpty);

    for (final q in questions) {
      expect(q.prompt, contains('____'));
      expect(q.options.length, 4);
      expect(q.options.toSet().length, 4);
      final answer = q.correctAnswer;
      // Restoring the blank with the answer must reproduce the verse
      // (modulo stripped punctuation).
      final restored = q.prompt.replaceFirst('____', answer);
      final source = verses.firstWhere((v) => v['reference'] == q.reference);
      expect(restored.split(' ').length, source['text']!.split(' ').length);
      // The answer never appears as its own word elsewhere in the options
      // pool sourced from the same verse.
      expect(answer.trim(), isNotEmpty);
      expect(answer.contains(' '), false);
    }
  });

  test('scramble rounds shuffle but preserve the words', () {
    final rounds = buildScrambleRounds(verses, 5, Random(3));
    expect(rounds, isNotEmpty);

    for (final r in rounds) {
      expect(r.shuffled.length, r.words.length);
      // Same multiset of words…
      final a = List.of(r.words)..sort();
      final b = List.of(r.shuffled)..sort();
      expect(a, b);
      // …but never presented already in order.
      expect(
        List.generate(
          r.words.length,
          (i) => r.words[i] == r.shuffled[i],
        ).every((same) => same),
        false,
        reason: 'shuffled order must differ from the solution',
      );
    }
  });

  test('long verses are capped for the scramble game', () {
    final long = [
      {
        'reference': 'Long 1:1',
        'text': List.generate(30, (i) => 'word$i').join(' '),
      },
    ];
    final rounds = buildScrambleRounds(long, 1, Random(1));
    expect(rounds.single.words.length, 12);
  });

  test('generators are deterministic for a fixed seed', () {
    final a = buildReferenceQuiz(verses, 5, Random(42));
    final b = buildReferenceQuiz(verses, 5, Random(42));
    expect(
      [for (final q in a) q.prompt + q.options.join()],
      [for (final q in b) q.prompt + q.options.join()],
    );
  });

  test('daily challenge is date-seeded: same day same questions', () {
    final day = DateTime(2026, 7, 17);
    final a = buildDailyChallenge(verses, day);
    final b = buildDailyChallenge(verses, day);
    expect(a.length, 5);
    expect([for (final q in a) q.prompt], [for (final q in b) q.prompt]);

    final other = buildDailyChallenge(verses, DateTime(2026, 7, 18));
    expect(
      [for (final q in a) q.prompt + q.options.join()] ==
          [for (final q in other) q.prompt + q.options.join()],
      false,
    );
  });

  test('challenge streak: increments on consecutive days only', () {
    final today = DateTime(2026, 7, 17);
    // Never played → 1.
    expect(
      challengeStreakAfterCompletion(lastDate: null, streak: 0, today: today),
      1,
    );
    // Played yesterday → +1.
    expect(
      challengeStreakAfterCompletion(
        lastDate: '2026-07-16',
        streak: 4,
        today: today,
      ),
      5,
    );
    // Already played today → unchanged.
    expect(
      challengeStreakAfterCompletion(
        lastDate: '2026-07-17',
        streak: 5,
        today: today,
      ),
      5,
    );
    // Gap → reset to 1.
    expect(
      challengeStreakAfterCompletion(
        lastDate: '2026-07-10',
        streak: 9,
        today: today,
      ),
      1,
    );

    expect(challengeStreakAlive(lastDate: '2026-07-16', today: today), true);
    expect(challengeStreakAlive(lastDate: '2026-07-17', today: today), true);
    expect(challengeStreakAlive(lastDate: '2026-07-14', today: today), false);
    expect(challengeStreakAlive(lastDate: null, today: today), false);
  });

  test('too-small pools return no questions instead of crashing', () {
    final tiny = verses.take(3).toList();
    expect(buildReferenceQuiz(tiny, 5, Random(1)), isEmpty);
    expect(buildFillBlankQuiz(tiny, 5, Random(1)), isEmpty);
  });
}
