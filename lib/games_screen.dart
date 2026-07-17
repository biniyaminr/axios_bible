import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bible_games.dart';
import 'bible_provider.dart';
import 'l10n/app_localizations.dart';

const _gold = Color(0xFFD4AF37);

/// Best scores per game, stored in SharedPreferences. Quiz scores are
/// "higher is better"; the verse builder stores fewest wrong taps.
class _BestScores {
  static Future<int?> get(String game) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('game_best_$game');
  }

  static Future<void> putIfBetter(
    String game,
    int score, {
    bool lowerIsBetter = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'game_best_$game';
    final current = prefs.getInt(key);
    final better =
        current == null || (lowerIsBetter ? score < current : score > current);
    if (better) await prefs.setInt(key, score);
  }
}

/// The games hub: one card per mini-game, with the best score so far.
class GamesHubScreen extends StatefulWidget {
  const GamesHubScreen({super.key});

  @override
  State<GamesHubScreen> createState() => _GamesHubScreenState();
}

class _GamesHubScreenState extends State<GamesHubScreen> {
  final Map<String, int?> _best = {};

  @override
  void initState() {
    super.initState();
    _loadBest();
  }

  Future<void> _loadBest() async {
    for (final game in ['reference', 'blank', 'scramble']) {
      final score = await _BestScores.get(game);
      if (mounted) setState(() => _best[game] = score);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.bibleGames,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _GameCard(
            icon: Icons.menu_book_rounded,
            title: l10n.gameGuessReference,
            description: l10n.gameGuessReferenceDesc,
            best: _best['reference'],
            onTap: () => _open(
              context,
              QuizScreen(
                title: l10n.gameGuessReference,
                gameKey: 'reference',
                buildQuestions: (verses, rng) =>
                    buildReferenceQuiz(verses, 10, rng),
              ),
            ),
          ),
          _GameCard(
            icon: Icons.edit_note_rounded,
            title: l10n.gameFillBlank,
            description: l10n.gameFillBlankDesc,
            best: _best['blank'],
            onTap: () => _open(
              context,
              QuizScreen(
                title: l10n.gameFillBlank,
                gameKey: 'blank',
                buildQuestions: (verses, rng) =>
                    buildFillBlankQuiz(verses, 10, rng),
              ),
            ),
          ),
          _GameCard(
            icon: Icons.extension_rounded,
            title: l10n.gameVerseBuilder,
            description: l10n.gameVerseBuilderDesc,
            best: _best['scramble'],
            onTap: () => _open(context, const VerseBuilderScreen()),
          ),
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context, Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => screen),
    );
    _loadBest(); // Refresh best scores after a game.
  }
}

class _GameCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final int? best;
  final VoidCallback onTap;

  const _GameCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.best,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _gold, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: onSurface.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                    if (best != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        l10n.bestScoreLabel(best!),
                        style: const TextStyle(
                          color: _gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: onSurface.withValues(alpha: 0.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Multiple-choice quiz flow shared by "Guess the Reference" and
/// "Fill in the Blank".
class QuizScreen extends StatefulWidget {
  final String title;
  final String gameKey;
  final List<QuizQuestion> Function(
    List<Map<String, String>> verses,
    Random rng,
  )
  buildQuestions;

  const QuizScreen({
    super.key,
    required this.title,
    required this.gameKey,
    required this.buildQuestions,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<QuizQuestion> _questions = [];
  int _index = 0;
  int _score = 0;
  int? _picked;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    final bible = context.read<BibleProvider>();
    final verses = [
      for (final ref in bible.dailyVerseRefs) bible.dailyVerseFor(ref),
    ];
    setState(() {
      _questions = widget.buildQuestions(verses, Random());
      _index = 0;
      _score = 0;
      _picked = null;
      _finished = false;
    });
  }

  void _pick(int option) {
    if (_picked != null) return;
    setState(() {
      _picked = option;
      if (option == _questions[_index].correctIndex) _score++;
    });
  }

  Future<void> _next() async {
    if (_index + 1 < _questions.length) {
      setState(() {
        _index++;
        _picked = null;
      });
    } else {
      await _BestScores.putIfBetter(widget.gameKey, _score);
      if (mounted) setState(() => _finished = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.title,
          style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _questions.isEmpty
          ? const Center(child: CircularProgressIndicator(color: _gold))
          : _finished
          ? _ResultView(
              score: _score,
              total: _questions.length,
              onPlayAgain: _start,
            )
          : _buildQuestion(context, l10n),
    );
  }

  Widget _buildQuestion(BuildContext context, AppLocalizations l10n) {
    final question = _questions[_index];
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final answered = _picked != null;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.questionOf(_index + 1, _questions.length),
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$_score',
              style: const TextStyle(
                color: _gold,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: (_index + (answered ? 1 : 0)) / _questions.length,
            minHeight: 5,
            color: _gold,
            backgroundColor: _gold.withValues(alpha: 0.15),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _gold.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text(
                '“${question.prompt}”',
                textAlign: TextAlign.center,
                style: TextStyle(color: onSurface, fontSize: 17, height: 1.6),
              ),
              if (answered) ...[
                const SizedBox(height: 12),
                Text(
                  question.reference,
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < question.options.length; i++)
          _OptionTile(
            label: question.options[i],
            state: !answered
                ? _OptionState.idle
                : i == question.correctIndex
                ? _OptionState.correct
                : i == _picked
                ? _OptionState.wrong
                : _OptionState.disabled,
            onTap: () => _pick(i),
          ),
        if (answered) ...[
          const SizedBox(height: 8),
          Text(
            _picked == question.correctIndex
                ? l10n.correctAnswer
                : l10n.wrongAnswer,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _picked == question.correctIndex
                  ? const Color(0xFF7CB342)
                  : onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _next,
            child: Text(
              _index + 1 < _questions.length
                  ? l10n.nextQuestion
                  : l10n.finishGame,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ],
    );
  }
}

enum _OptionState { idle, correct, wrong, disabled }

class _OptionTile extends StatelessWidget {
  final String label;
  final _OptionState state;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    const green = Color(0xFF7CB342);
    const red = Color(0xFFE57373);

    final Color border;
    final Color? fill;
    final Color text;
    switch (state) {
      case _OptionState.correct:
        border = green;
        fill = green.withValues(alpha: 0.15);
        text = onSurface;
      case _OptionState.wrong:
        border = red;
        fill = red.withValues(alpha: 0.12);
        text = onSurface;
      case _OptionState.disabled:
        border = onSurface.withValues(alpha: 0.08);
        fill = null;
        text = onSurface.withValues(alpha: 0.45);
      case _OptionState.idle:
        border = _gold.withValues(alpha: 0.35);
        fill = null;
        text = onSurface;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: fill ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1.2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: state == _OptionState.idle ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: text,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (state == _OptionState.correct)
                const Icon(Icons.check_circle, color: green, size: 20),
              if (state == _OptionState.wrong)
                const Icon(Icons.cancel, color: red, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final int score;
  final int total;
  final VoidCallback onPlayAgain;

  const _ResultView({
    required this.score,
    required this.total,
    required this.onPlayAgain,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final ratio = total == 0 ? 0.0 : score / total;
    final headline = ratio == 1.0
        ? l10n.gamePerfect
        : ratio >= 0.6
        ? l10n.gameWellDone
        : l10n.gameKeepPracticing;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              ratio >= 0.6 ? Icons.emoji_events_rounded : Icons.menu_book,
              color: _gold,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              headline,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.yourScore,
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$score / $total',
              style: const TextStyle(
                color: _gold,
                fontSize: 40,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
              ),
              onPressed: onPlayAgain,
              icon: const Icon(Icons.replay_rounded),
              label: Text(
                l10n.playAgain,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Verse Builder: tap the shuffled words in order to rebuild the verse.
/// A wrong word flashes and counts a mistake; fewest mistakes is the best
/// score.
class VerseBuilderScreen extends StatefulWidget {
  const VerseBuilderScreen({super.key});

  @override
  State<VerseBuilderScreen> createState() => _VerseBuilderScreenState();
}

class _VerseBuilderScreenState extends State<VerseBuilderScreen> {
  List<ScrambleRound> _rounds = [];
  int _round = 0;
  int _placed = 0; // how many words of the current round are placed
  int _mistakes = 0;
  int? _flashingIndex; // chip that flashed red
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    final bible = context.read<BibleProvider>();
    final verses = [
      for (final ref in bible.dailyVerseRefs) bible.dailyVerseFor(ref),
    ];
    setState(() {
      _rounds = buildScrambleRounds(verses, 5, Random());
      _round = 0;
      _placed = 0;
      _mistakes = 0;
      _finished = false;
    });
  }

  /// Indices of shuffled chips still unplaced, given how many words are
  /// placed: each chip is used exactly once.
  List<int> _remainingChipIndices(ScrambleRound round) {
    final used = List<bool>.filled(round.shuffled.length, false);
    for (var p = 0; p < _placed; p++) {
      final word = round.words[p];
      for (var i = 0; i < round.shuffled.length; i++) {
        if (!used[i] && round.shuffled[i] == word) {
          used[i] = true;
          break;
        }
      }
    }
    return [
      for (var i = 0; i < round.shuffled.length; i++)
        if (!used[i]) i,
    ];
  }

  Future<void> _tapChip(ScrambleRound round, int chipIndex) async {
    final expected = round.words[_placed];
    if (round.shuffled[chipIndex] == expected) {
      setState(() {
        _placed++;
        _flashingIndex = null;
      });
      if (_placed == round.words.length) {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        if (_round + 1 < _rounds.length) {
          setState(() {
            _round++;
            _placed = 0;
          });
        } else {
          await _BestScores.putIfBetter(
            'scramble',
            _mistakes,
            lowerIsBetter: true,
          );
          if (mounted) setState(() => _finished = true);
        }
      }
    } else {
      setState(() {
        _mistakes++;
        _flashingIndex = chipIndex;
      });
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (mounted) setState(() => _flashingIndex = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.gameVerseBuilder,
          style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _rounds.isEmpty
          ? const Center(child: CircularProgressIndicator(color: _gold))
          : _finished
          ? _buildResult(l10n, onSurface)
          : _buildRound(l10n, onSurface),
    );
  }

  Widget _buildRound(AppLocalizations l10n, Color onSurface) {
    final round = _rounds[_round];
    final remaining = _remainingChipIndices(round);
    final complete = _placed == round.words.length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.verseOf(_round + 1, _rounds.length),
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              l10n.scrambleMistakes(_mistakes),
              style: TextStyle(
                color: _mistakes == 0
                    ? const Color(0xFF7CB342)
                    : onSurface.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // The verse under construction.
        Container(
          constraints: const BoxConstraints(minHeight: 120),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: complete
                  ? const Color(0xFF7CB342)
                  : _gold.withValues(alpha: 0.35),
              width: complete ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                round.words.take(_placed).join(' '),
                style: TextStyle(color: onSurface, fontSize: 17, height: 1.6),
              ),
              if (complete) ...[
                const SizedBox(height: 10),
                Text(
                  round.reference,
                  style: const TextStyle(
                    color: _gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        // The shuffled word chips.
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final i in remaining)
              ActionChip(
                label: Text(round.shuffled[i]),
                labelStyle: TextStyle(
                  color: _flashingIndex == i ? Colors.white : onSurface,
                  fontSize: 15,
                ),
                backgroundColor: _flashingIndex == i
                    ? const Color(0xFFE57373)
                    : Theme.of(context).colorScheme.surface,
                side: BorderSide(color: _gold.withValues(alpha: 0.4)),
                onPressed: () => _tapChip(round, i),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildResult(AppLocalizations l10n, Color onSurface) {
    final headline = _mistakes == 0
        ? l10n.gamePerfect
        : _mistakes <= 4
        ? l10n.gameWellDone
        : l10n.gameKeepPracticing;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _mistakes <= 4 ? Icons.emoji_events_rounded : Icons.menu_book,
              color: _gold,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              headline,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.scrambleMistakes(_mistakes),
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.6),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
              ),
              onPressed: _start,
              icon: const Icon(Icons.replay_rounded),
              label: Text(
                l10n.playAgain,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
