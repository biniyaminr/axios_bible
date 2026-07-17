import 'package:flutter/material.dart';

import 'ethiopian_calendar.dart';

/// The bundled Ethiopic family. Only the Regular weight ships in assets and
/// GoogleFonts runtime fetching is off, so asking google_fonts for a heavier
/// weight throws — reference the family directly and let Flutter synthesize.
const String _ethiopicFont = 'NotoSansEthiopic';

/// Shows today in the Ethiopian calendar, with the Gregorian date beneath.
/// Both lines follow the app's language.
class EthiopianDateBanner extends StatelessWidget {
  /// Overridable so tests and previews are not tied to the real clock.
  final DateTime? date;

  const EthiopianDateBanner({super.key, this.date});

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    final now = date ?? DateTime.now();
    final ethiopian = EthiopianDate.fromGregorian(now);
    final isAmharic = Localizations.localeOf(context).languageCode == 'am';

    // MaterialLocalizations formats the Gregorian line in the active locale
    // without needing intl's date symbols initialized.
    final gregorian = MaterialLocalizations.of(context).formatFullDate(now);
    final weekday = isAmharic
        ? '${ethiopianWeekdaysAm[now.weekday - 1]} • '
        : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: gold.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded, color: gold, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$weekday${ethiopian.format(amharic: isAmharic)}',
                  style: const TextStyle(
                    fontFamily: _ethiopicFont,
                    color: gold,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  gregorian,
                  style: TextStyle(
                    fontFamily: _ethiopicFont,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.55),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
