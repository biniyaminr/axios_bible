import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'bible_provider.dart';
import 'l10n/app_localizations.dart';
import 'reading_plans.dart';

const _gold = Color(0xFFD4AF37);

/// Reading-plans tab: streak header + plan cards.
class PlansScreen extends StatelessWidget {
  final VoidCallback onGoToReading;
  const PlansScreen({super.key, required this.onGoToReading});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<ReadingPlanProvider>(
      builder: (context, plans, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              l10n.readingPlans,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (plans.streak > 0) _StreakBanner(days: plans.streak),
              for (final plan in plans.plans)
                _PlanCard(plan: plan, onGoToReading: onGoToReading),
            ],
          ),
        );
      },
    );
  }
}

class _StreakBanner extends StatelessWidget {
  final int days;
  const _StreakBanner({required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            _gold.withValues(alpha: 0.25),
            _gold.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: _gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: _gold,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context)!.readingStreak(days),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _gold,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final ReadingPlan plan;
  final VoidCallback onGoToReading;
  const _PlanCard({required this.plan, required this.onGoToReading});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final plans = context.watch<ReadingPlanProvider>();
    final started = plans.isStarted(plan.id);
    final done = plans.completedDays(plan.id).length;
    final progress = plans.progress(plan);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _gold.withValues(alpha: started ? 0.6 : 0.25),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          if (!started) await plans.startPlan(plan.id);
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PlanDetailScreen(plan: plan, onGoToReading: onGoToReading),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plan.title(l10n),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                plan.description(l10n),
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 14),
              if (started) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    color: _gold,
                    backgroundColor: _gold.withValues(alpha: 0.15),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.daysCompleted(done, plan.totalDays),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      l10n.continuePlan,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _gold,
                      ),
                    ),
                  ],
                ),
              ] else
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    l10n.startPlan,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _gold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Day-by-day view of a plan. Tapping a reading opens it in the reader;
/// the checkbox marks the day complete. Opens scrolled to the current day
/// so long plans don't require hunting for today.
class PlanDetailScreen extends StatefulWidget {
  final ReadingPlan plan;
  final VoidCallback onGoToReading;
  const PlanDetailScreen({
    super.key,
    required this.plan,
    required this.onGoToReading,
  });

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  // Rows are ~86px (padding + label + one chip row); close enough to land
  // the current day on screen even when some rows wrap taller.
  static const double _estimatedRowHeight = 86;

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    final currentDay = context.read<ReadingPlanProvider>().currentDay(
      widget.plan,
    );
    _scrollController = ScrollController(
      initialScrollOffset: currentDay <= 2
          ? 0
          : (currentDay - 2) * _estimatedRowHeight,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final plan = widget.plan;
    final onGoToReading = widget.onGoToReading;
    return Consumer2<ReadingPlanProvider, BibleProvider>(
      builder: (context, plans, bible, _) {
        final currentDay = plans.currentDay(plan);
        return Scaffold(
          appBar: AppBar(
            title: Text(
              plan.title(l10n),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
          body: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: plan.totalDays,
            itemBuilder: (context, day) {
              final readings = plan.schedule[day];
              final completed = plans.isDayCompleted(plan.id, day);
              final isCurrent = day == currentDay && !completed;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCurrent
                        ? _gold
                        : _gold.withValues(alpha: completed ? 0.4 : 0.15),
                    width: isCurrent ? 1.5 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.dayLabel(day + 1),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: completed
                                    ? _gold
                                    : Theme.of(context).colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final r in readings)
                                  ActionChip(
                                    label: Text(
                                      '${bible.bookNameForId(r.bookId)} '
                                      '${r.chapter}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    side: BorderSide(
                                      color: _gold.withValues(alpha: 0.35),
                                    ),
                                    onPressed: () {
                                      if (bible.openReading(
                                        r.bookId,
                                        r.chapter,
                                      )) {
                                        Navigator.pop(context);
                                        onGoToReading();
                                      }
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Checkbox(
                        value: completed,
                        activeColor: _gold,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (_) => plans.toggleDay(plan.id, day),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
