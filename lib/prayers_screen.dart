import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'prayer_provider.dart';

const _gold = Color(0xFFD4AF37);

/// Full-screen prayer list: active requests on top, answered ones below,
/// add via FAB, swipe to delete, tap the circle to mark answered.
class PrayersScreen extends StatelessWidget {
  const PrayersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<PrayerProvider>(
      builder: (context, prayers, _) {
        final active = prayers.active;
        final answered = prayers.answered;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              l10n.prayerList,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: _gold,
            foregroundColor: Colors.black,
            icon: const Icon(Icons.add),
            label: Text(l10n.addPrayer),
            onPressed: () => _showAddPrayerSheet(context),
          ),
          body: active.isEmpty && answered.isEmpty
              ? _buildEmptyState(context, l10n)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                  children: [
                    if (active.isNotEmpty) ...[
                      _sectionTitle(context, l10n.activePrayers),
                      const SizedBox(height: 12),
                      for (final p in active) _PrayerCard(prayer: p),
                    ],
                    if (answered.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _sectionTitle(context, l10n.answeredPrayers),
                      const SizedBox(height: 12),
                      for (final p in answered) _PrayerCard(prayer: p),
                    ],
                  ],
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.volunteer_activism_outlined,
            size: 56,
            color: _gold.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noPrayersHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
        letterSpacing: 0.5,
      ),
    );
  }

  void _showAddPrayerSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<PrayerProvider>();
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.addPrayer,
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: l10n.prayerHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _gold, width: 2),
                  ),
                ),
                onSubmitted: (text) {
                  provider.addPrayer(text);
                  Navigator.pop(sheetContext);
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () {
                      provider.addPrayer(controller.text);
                      Navigator.pop(sheetContext);
                    },
                    child: Text(l10n.addPrayer),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ).whenComplete(controller.dispose);
  }
}

class _PrayerCard extends StatelessWidget {
  final Prayer prayer;

  const _PrayerCard({required this.prayer});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<PrayerProvider>();
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final answered = prayer.isAnswered;

    return Dismissible(
      key: ValueKey('prayer_${prayer.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        provider.deletePrayer(prayer.id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.prayerDeleted)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: answered
                ? _gold.withValues(alpha: 0.35)
                : onSurface.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              tooltip: l10n.markAnswered,
              onPressed: () => provider.setAnswered(prayer.id, !answered),
              icon: Icon(
                answered ? Icons.check_circle : Icons.radio_button_unchecked,
                color: answered ? _gold : onSurface.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    prayer.text,
                    style: TextStyle(
                      color: answered
                          ? onSurface.withValues(alpha: 0.55)
                          : onSurface,
                      fontSize: 15,
                      height: 1.4,
                      decoration: answered ? TextDecoration.lineThrough : null,
                      decorationColor: onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    answered
                        ? l10n.answeredOn(_formatDate(prayer.answeredAt!))
                        : _formatDate(prayer.createdAt),
                    style: TextStyle(
                      color: answered
                          ? _gold.withValues(alpha: 0.9)
                          : onSurface.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';
}
