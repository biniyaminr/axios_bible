import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'bible_provider.dart';
import 'l10n/app_localizations.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<BibleProvider>(
      builder: (context, provider, _) {
        return Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.settings,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.language,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  style: SegmentedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E1E1E),
                    selectedBackgroundColor: const Color(0xFFD4AF37),
                    selectedForegroundColor: Colors.black,
                  ),
                  segments: [
                    ButtonSegment(
                      value: 'system',
                      label: Text(l10n.languageSystem),
                    ),
                    const ButtonSegment(value: 'am', label: Text('አማርኛ')),
                    const ButtonSegment(value: 'en', label: Text('English')),
                  ],
                  selected: {provider.appLanguage},
                  onSelectionChanged: (Set<String> newSelection) {
                    provider.setAppLanguage(newSelection.first);
                  },
                ),
                const SizedBox(height: 32),
                Text(
                  l10n.theme,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<ThemeMode>(
                  style: SegmentedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E1E1E), // Dark background
                    selectedBackgroundColor: const Color(
                      0xFFD4AF37,
                    ), // Axios Gold
                    selectedForegroundColor:
                        Colors.black, // Dark text on gold for contrast
                  ),
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: const Icon(Icons.brightness_auto),
                      label: Text(l10n.themeSystem),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: const Icon(Icons.light_mode),
                      label: Text(l10n.themeLight),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: const Icon(Icons.dark_mode),
                      label: Text(l10n.themeDark),
                    ),
                  ],
                  selected: {provider.themeMode},
                  onSelectionChanged: (Set<ThemeMode> newSelection) {
                    provider.setThemeMode(newSelection.first);
                  },
                ),
                const SizedBox(height: 32),
                Text(
                  l10n.prayerMoment,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.prayerMomentHint,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    Switch(
                      value: provider.prayerMomentEnabled,
                      activeThumbColor: const Color(0xFFD4AF37),
                      onChanged: provider.setPrayerMomentEnabled,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _NotificationSetting(
                  title: l10n.dailyReminder,
                  hint: l10n.dailyReminderHint,
                  enabled: provider.reminderEnabled,
                  time: provider.reminderTime,
                  onToggle: provider.setReminderEnabled,
                  onTimeChanged: provider.setReminderTime,
                ),
                const SizedBox(height: 32),
                _NotificationSetting(
                  title: l10n.verseOfTheDay,
                  hint: l10n.verseOfDayHint,
                  enabled: provider.votdEnabled,
                  time: provider.votdTime,
                  onToggle: provider.setVotdEnabled,
                  onTimeChanged: provider.setVotdTime,
                ),
                const SizedBox(height: 32),
                Text(
                  l10n.fontSize,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.format_size, size: 16),
                    Expanded(
                      child: Slider(
                        value: provider.fontSize,
                        activeColor: const Color(0xFFD4AF37), // Axios Gold
                        thumbColor: const Color(0xFFD4AF37), // Axios Gold
                        inactiveColor: Colors.white24,
                        min: 12.0,
                        max: 32.0,
                        divisions: 10,
                        label: provider.fontSize.round().toString(),
                        onChanged: (value) {
                          provider.setFontSize(value);
                        },
                      ),
                    ),
                    const Icon(Icons.format_size, size: 24),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  l10n.audioSpeed,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.speed, size: 16),
                    Expanded(
                      child: Slider(
                        value: provider.audioSpeed,
                        activeColor: const Color(0xFFD4AF37), // Axios Gold
                        thumbColor: const Color(0xFFD4AF37), // Axios Gold
                        inactiveColor: Colors.white24,
                        min: 0.5,
                        max: 2.0,
                        divisions: 6,
                        label: '${provider.audioSpeed}x',
                        onChanged: (value) {
                          provider.setAudioSpeed(value);
                        },
                      ),
                    ),
                    const Icon(Icons.speed, size: 24),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A titled toggle with a tappable time row, shared by the daily reading
/// reminder and the verse-of-the-day notification settings.
class _NotificationSetting extends StatelessWidget {
  final String title;
  final String hint;
  final bool enabled;
  final TimeOfDay time;

  /// Returns false when the OS denied notification permission.
  final Future<bool> Function(bool) onToggle;
  final Future<void> Function(TimeOfDay) onTimeChanged;

  const _NotificationSetting({
    required this.title,
    required this.hint,
    required this.enabled,
    required this.time,
    required this.onToggle,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                hint,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
            Switch(
              value: enabled,
              activeThumbColor: const Color(0xFFD4AF37),
              onChanged: (value) async {
                final messenger = ScaffoldMessenger.of(context);
                final deniedText = l10n.notificationsDenied;
                final ok = await onToggle(value);
                if (value && !ok) {
                  messenger.showSnackBar(SnackBar(content: Text(deniedText)));
                }
              },
            ),
          ],
        ),
        if (enabled)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: time,
                );
                if (picked != null) {
                  await onTimeChanged(picked);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.alarm, size: 18, color: Color(0xFFD4AF37)),
                    const SizedBox(width: 8),
                    Text(l10n.reminderTime),
                    const Spacer(),
                    Text(
                      time.format(context),
                      style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
