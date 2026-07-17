import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'bookmarks_screen.dart';
import 'plans_screen.dart';
import 'premium_bible_screen.dart';
import 'search_screen.dart';
import 'study_hub_screen.dart';

// ─────────────────────────────────────────────────────
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 1; // Default to reading tab

  /// Tab to return to when a screen offers a back affordance. Tabs live in an
  /// IndexedStack, so there is no route to pop — back has to be tracked here.
  int _previousIndex = 1;

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      StudyHubScreen(onGoToReading: _goToReading), // 0
      const PremiumBibleScreen(), // 1
      PlansScreen(onGoToReading: _goToReading), // 2
      SearchScreen(onGoToReading: _goToReading, onBack: _goBack), // 3
      BookmarksScreen(onGoToReading: _goToReading), // 4
    ]);
  }

  void _selectTab(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });
  }

  void _goToReading() => _selectTab(1);

  /// Returns to the tab the user came from.
  void _goBack() => _selectTab(_previousIndex);

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFFFD700);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: gold.withValues(alpha: 0.12), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: gold.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  0,
                  Icons.home_rounded,
                  AppLocalizations.of(context)!.navHome,
                ), // 0: Home dashboard (Study Hub)
                _buildNavItem(
                  1,
                  Icons.menu_book_rounded,
                  AppLocalizations.of(context)!.navBible,
                ), // 1: Bible
                _buildNavItem(
                  2,
                  Icons.event_note_rounded,
                  AppLocalizations.of(context)!.navPlans,
                ), // 2: Reading plans
                _buildNavItem(
                  3,
                  Icons.search_rounded,
                  AppLocalizations.of(context)!.navSearch,
                ), // 3: Search
                _buildNavItem(
                  4,
                  Icons.bookmark_rounded,
                  AppLocalizations.of(context)!.navBookmarks,
                ), // 4: Bookmarks
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = index == _currentIndex;
    const gold = Color(0xFFFFD700);
    return GestureDetector(
      onTap: () => _selectTab(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            width: 48,
            height: 40,
            decoration: BoxDecoration(
              color: isActive
                  ? gold.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: gold.withValues(alpha: 0.1),
                        blurRadius: 10,
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              icon,
              color: isActive
                  ? gold
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive
                  ? gold
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
