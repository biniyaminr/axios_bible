import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bible_games.dart' show dateKey;
import 'bible_provider.dart';
import 'l10n/app_localizations.dart';
import 'prayer_provider.dart';

const _gold = Color(0xFFD4AF37);

/// Marks today's Prayer Moment as seen so it shows once per day.
Future<void> markPrayerMomentSeen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('prayer_moment_last_date', dateKey(DateTime.now()));
}

/// Whether the Prayer Moment should show now (enabled and not yet seen
/// today).
Future<bool> shouldShowPrayerMoment(bool enabled) async {
  if (!enabled) return false;
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('prayer_moment_last_date') != dateKey(DateTime.now());
}

/// A full-screen, once-a-day pause before the app opens: today's verse,
/// the user's active prayers, and a breathing glow to slow down with.
class PrayerMomentScreen extends StatefulWidget {
  const PrayerMomentScreen({super.key});

  @override
  State<PrayerMomentScreen> createState() => _PrayerMomentScreenState();
}

class _PrayerMomentScreenState extends State<PrayerMomentScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await markPrayerMomentSeen();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final verse = context.watch<BibleProvider>().verseOfTheDay;
    final prayers = context.watch<PrayerProvider>().active.take(3).toList();

    return PopScope(
      // Back gesture counts as "skip" — still marks today as seen.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish();
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: dark
                  ? const [Color(0xFF1A1402), Color(0xFF000000)]
                  : const [Color(0xFFFDF3D7), Color(0xFFFAF8F5)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // Breathing glow
                  AnimatedBuilder(
                    animation: _breath,
                    builder: (context, _) {
                      final t = Curves.easeInOut.transform(_breath.value);
                      final scale = 0.92 + t * 0.16;
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _gold.withValues(alpha: 0.10 + t * 0.08),
                            boxShadow: [
                              BoxShadow(
                                color: _gold.withValues(alpha: 0.25 + t * 0.2),
                                blurRadius: 40 + t * 25,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.self_improvement_rounded,
                            color: _gold,
                            size: 54,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  Text(
                    l10n.prayerMomentTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  // Verse of the day
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOut,
                    builder: (context, v, child) => Opacity(
                      opacity: v,
                      child: Transform.translate(
                        offset: Offset(0, (1 - v) * 16),
                        child: child,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withValues(
                          alpha: dark ? 0.55 : 0.8,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _gold.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '“${verse['text']}”',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: onSurface,
                              fontSize: 16,
                              height: 1.7,
                            ),
                            maxLines: 6,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            verse['reference'] ?? '',
                            style: const TextStyle(
                              color: _gold,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (prayers.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.prayerMomentPrayers,
                        style: TextStyle(
                          color: onSurface.withValues(alpha: 0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final p in prayers)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _gold.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _gold.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          p.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: onSurface.withValues(alpha: 0.85),
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                  const Spacer(),
                  // Amen
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: _finish,
                      child: Text(
                        l10n.amen,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _finish,
                    child: Text(
                      l10n.skipForNow,
                      style: TextStyle(
                        color: onSurface.withValues(alpha: 0.45),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
