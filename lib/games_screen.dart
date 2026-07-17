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

/// Today's challenge status, stored in SharedPreferences.
class _ChallengeState {
  final String? lastDate;
  final int streak;
  final int lastScore;

  const _ChallengeState({
    required this.lastDate,
    required this.streak,
    required this.lastScore,
  });

  bool get doneToday => lastDate == dateKey(DateTime.now());
  int get displayStreak =>
      challengeStreakAlive(lastDate: lastDate, today: DateTime.now())
      ? streak
      : 0;

  static Future<_ChallengeState> load() async {
    final prefs = await SharedPreferences.getInstance();
    return _ChallengeState(
      lastDate: prefs.getString('challenge_last_date'),
      streak: prefs.getInt('challenge_streak') ?? 0,
      lastScore: prefs.getInt('challenge_last_score') ?? 0,
    );
  }

  /// Records a completion with [score]; keeps today's best score.
  static Future<void> recordCompletion(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final last = prefs.getString('challenge_last_date');
    final streak = challengeStreakAfterCompletion(
      lastDate: last,
      streak: prefs.getInt('challenge_streak') ?? 0,
      today: now,
    );
    final doneToday = last == dateKey(now);
    final prevScore = prefs.getInt('challenge_last_score') ?? 0;
    await prefs.setString('challenge_last_date', dateKey(now));
    await prefs.setInt('challenge_streak', streak);
    await prefs.setInt(
      'challenge_last_score',
      doneToday ? max(score, prevScore) : score,
    );
  }
}

/// The gradient hero card for the daily challenge, shown on the Home tab
/// and at the top of the games hub.
class DailyChallengeCard extends StatefulWidget {
  const DailyChallengeCard({super.key});

  @override
  State<DailyChallengeCard> createState() => _DailyChallengeCardState();
}

class _DailyChallengeCardState extends State<DailyChallengeCard> {
  _ChallengeState? _state;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _ChallengeState.load();
    if (mounted) setState(() => _state = s);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final state = _state;
    final done = state?.doneToday ?? false;
    final streak = state?.displayStreak ?? 0;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const DailyChallengeScreen()),
        );
        _load();
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _gold.withValues(alpha: 0.30),
              _gold.withValues(alpha: 0.08),
            ],
          ),
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _gold.withValues(alpha: 0.55), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: _gold.withValues(alpha: 0.18),
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Flame + streak badge
            Column(
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  color: streak > 0
                      ? const Color(0xFFFF8F00)
                      : onSurface.withValues(alpha: 0.3),
                  size: 34,
                ),
                if (streak > 0)
                  Text(
                    '$streak',
                    style: const TextStyle(
                      color: Color(0xFFFF8F00),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.dailyChallenge,
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    done
                        ? l10n.challengeDoneToday(state!.lastScore)
                        : l10n.dailyChallengeHint,
                    style: TextStyle(
                      color: done ? _gold : onSurface.withValues(alpha: 0.6),
                      fontSize: 13,
                      fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            done
                ? const Icon(Icons.check_circle_rounded, color: _gold, size: 32)
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: _gold,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: _gold.withValues(alpha: 0.4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Text(
                      l10n.playNow,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

/// The daily challenge run: five date-seeded questions, ending in an
/// animated score ring and the streak flame.
class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  List<QuizQuestion> _questions = [];
  int _index = 0;
  int _score = 0;
  int? _picked;
  bool _finished = false;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    final bible = context.read<BibleProvider>();
    final verses = [
      for (final ref in bible.dailyVerseRefs) bible.dailyVerseFor(ref),
    ];
    _questions = buildDailyChallenge(verses, DateTime.now());
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
      await _ChallengeState.recordCompletion(_score);
      final state = await _ChallengeState.load();
      if (mounted) {
        setState(() {
          _streak = state.displayStreak;
          _finished = true;
        });
      }
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
          l10n.dailyChallenge,
          style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _questions.isEmpty
          ? const Center(child: CircularProgressIndicator(color: _gold))
          : _finished
          ? _ChallengeResultView(
              score: _score,
              total: _questions.length,
              streak: _streak,
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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _gold.withValues(alpha: 0.15),
                _gold.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _gold.withValues(alpha: 0.4)),
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

class _ChallengeResultView extends StatelessWidget {
  final int score;
  final int total;
  final int streak;

  const _ChallengeResultView({
    required this.score,
    required this.total,
    required this.streak,
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
            // Animated score ring
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return SizedBox(
                  width: 150,
                  height: 150,
                  child: CustomPaint(
                    painter: _ScoreRingPainter(
                      progress: value,
                      color: _gold,
                      track: _gold.withValues(alpha: 0.15),
                    ),
                    child: Center(
                      child: Text(
                        '$score/$total',
                        style: TextStyle(
                          color: onSurface,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              headline,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (streak > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8F00).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFFF8F00).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFFFF8F00),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.challengeStreakLabel(streak),
                      style: const TextStyle(
                        color: Color(0xFFFF8F00),
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              l10n.comeBackTomorrow,
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.55),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.finishGame,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;

  _ScoreRingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 12) / 2;
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11;
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      progress * 2 * pi,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) =>
      old.progress != progress || old.color != color;
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
          const DailyChallengeCard(),
          const SizedBox(height: 18),
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
