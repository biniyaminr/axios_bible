import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'bible_provider.dart';
import 'l10n/app_localizations.dart';
import 'bible_search_delegate.dart';
import 'bookmarks_screen.dart';
import 'journal_screen.dart';
import 'translation_store_screen.dart';
import 'verse_image.dart';

enum _SelectorStep { book, chapter }

class PremiumBibleScreen extends StatefulWidget {
  const PremiumBibleScreen({super.key});

  @override
  State<PremiumBibleScreen> createState() => _PremiumBibleScreenState();
}

class _PremiumBibleScreenState extends State<PremiumBibleScreen> {
  final ScrollController _primaryScrollController = ScrollController();
  final ScrollController _secondaryScrollController = ScrollController();
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _primaryScrollController.addListener(() {
      if (_isSyncing) return;
      _isSyncing = true;
      if (_secondaryScrollController.hasClients) {
        // Prevent out-of-bounds scrolling on the secondary view
        final maxScrollOffset =
            _secondaryScrollController.position.maxScrollExtent;
        final targetOffset = _primaryScrollController.offset;
        _secondaryScrollController.jumpTo(
          targetOffset > maxScrollOffset ? maxScrollOffset : targetOffset,
        );
      }
      _isSyncing = false;
    });

    _secondaryScrollController.addListener(() {
      if (_isSyncing) return;
      _isSyncing = true;
      if (_primaryScrollController.hasClients) {
        final maxScrollOffset =
            _primaryScrollController.position.maxScrollExtent;
        final targetOffset = _secondaryScrollController.offset;
        _primaryScrollController.jumpTo(
          targetOffset > maxScrollOffset ? maxScrollOffset : targetOffset,
        );
      }
      _isSyncing = false;
    });
  }

  @override
  void dispose() {
    _primaryScrollController.dispose();
    _secondaryScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: _buildPremiumDrawer(context, context.watch<BibleProvider>()),
      body: Consumer<BibleProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFD4AF37),
                strokeWidth: 2.0,
              ),
            );
          }
          if (provider.error != null) {
            return Center(
              child: Text(
                provider.error!,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.54),
                  fontWeight: FontWeight.w300,
                  fontSize: 16,
                ),
              ),
            );
          }

          final verses = provider.verses.entries.toList();
          if (verses.isEmpty) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.noVersesFound,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.24),
                  letterSpacing: 1.5,
                  fontSize: 16,
                ),
              ),
            );
          }

          return GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! > 300) {
                provider.previousChapter();
              } else if (details.primaryVelocity! < -300) {
                provider.nextChapter();
              }
            },
            child: Stack(
              children: [
                // Classic Reading Experience (The List/Split)
                Column(
                  children: [
                    Expanded(
                      flex: 1,
                      child: CustomScrollView(
                        controller: _primaryScrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          // Premium Glassmorphism Header
                          SliverAppBar(
                            pinned: true,
                            expandedHeight: 110.0,
                            backgroundColor: Theme.of(
                              context,
                            ).scaffoldBackgroundColor,
                            elevation: 0,
                            leading: Builder(
                              builder: (context) => IconButton(
                                icon: const Icon(
                                  Icons.menu,
                                  color: Color(0xFFD4AF37),
                                ),
                                onPressed: () {
                                  Scaffold.of(context).openDrawer();
                                },
                              ),
                            ),
                            actions: [
                              IconButton(
                                icon: const Icon(
                                  Icons.settings,
                                  color: Color(0xFFD4AF37),
                                ),
                                onPressed: () {
                                  _showReadingStudio(context, provider);
                                },
                              ),
                            ],
                            flexibleSpace: ClipRect(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 15,
                                  sigmaY: 15,
                                ),
                                child: FlexibleSpaceBar(
                                  titlePadding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  title: Text(
                                    '${provider.selectedBook} ${provider.selectedChapter}',
                                    style: const TextStyle(
                                      color: Color(0xFFD4AF37), // Gold accent
                                      fontWeight: FontWeight.w600,
                                      fontSize: 22,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  background: Container(
                                    color: Theme.of(context)
                                        .scaffoldBackgroundColor
                                        .withValues(alpha: 0.65),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Reading List
                          SliverPadding(
                            padding: EdgeInsets.only(
                              left: 20,
                              right: 20,
                              top: 16,
                              bottom: provider.isSplitScreen
                                  ? 20
                                  : 120, // Extra bottom padding for floating menu only if not split
                            ),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final verse = verses[index];
                                final isSelected = provider.selectedVerses
                                    .contains(verse.key);
                                final highlightColor = provider
                                    .getHighlightColor(verse.key);

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    splashColor: const Color(
                                      0xFFD4AF37,
                                    ).withValues(alpha: 0.3), // Axios Gold
                                    highlightColor: Colors.transparent,
                                    onTap: () {
                                      provider.toggleVerseSelection(verse.key);
                                    },
                                    onLongPress: () {
                                      if (!isSelected) {
                                        provider.toggleVerseSelection(
                                          verse.key,
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                        horizontal: 20.0,
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 2.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? (Theme.of(context).brightness ==
                                                      Brightness.light
                                                  ? Colors.black.withValues(
                                                      alpha: 0.05,
                                                    )
                                                  : Colors.white.withValues(
                                                      alpha: 0.1,
                                                    ))
                                            : (highlightColor != null
                                                  ? highlightColor.withValues(
                                                      alpha: 0.2,
                                                    )
                                                  : Colors.transparent),
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Redesigned Verse Number
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 2.0,
                                              right: 14.0,
                                            ),
                                            child: Column(
                                              children: [
                                                Container(
                                                  width: 30,
                                                  height: 30,
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color:
                                                        Theme.of(
                                                              context,
                                                            ).brightness ==
                                                            Brightness.light
                                                        ? const Color(
                                                            0xFFFDF8ED,
                                                          )
                                                        : Colors.transparent,
                                                    border: Border.all(
                                                      color:
                                                          Theme.of(
                                                                context,
                                                              ).brightness ==
                                                              Brightness.light
                                                          ? const Color(
                                                              0xFFE5D5A4,
                                                            )
                                                          : Colors.white24,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    verse.key,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color:
                                                          Theme.of(
                                                                context,
                                                              ).brightness ==
                                                              Brightness.light
                                                          ? const Color(
                                                              0xFFC8A951,
                                                            )
                                                          : Theme.of(context)
                                                                .colorScheme
                                                                .onSurface
                                                                .withValues(
                                                                  alpha: 0.4,
                                                                ),
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                if (provider.hasNote(
                                                  '${provider.selectedBook} ${provider.selectedChapter}:${verse.key}',
                                                ))
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 4.0,
                                                        ),
                                                    child: Icon(
                                                      Icons.bookmark,
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                      size: 12,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          // Verse Text
                                          Expanded(
                                            child: Text(
                                              verse.value,
                                              style: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                                fontSize: provider
                                                    .fontSize, // Synced with Settings slider
                                                height: provider.lineSpacing,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }, childCount: verses.length),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // The Glowing Divider for Split Screen
                    if (provider.isSplitScreen)
                      Container(
                        height: 2,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFD4AF37,
                              ).withValues(alpha: 0.6),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                          color: const Color(0xFFD4AF37),
                        ),
                      ),

                    // Language Selector Button
                    if (provider.isSplitScreen)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            right: 16.0,
                            top: 8.0,
                            bottom: 4.0,
                          ),
                          child: TextButton.icon(
                            onPressed: () =>
                                _showParallelVersionSelector(context, provider),
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Color(0xFFD4AF37),
                              size: 18,
                            ),
                            label: Text(
                              provider.parallelTranslation?.name ??
                                  AppLocalizations.of(context)!.selectVersion,
                              style: const TextStyle(
                                color: Color(0xFFD4AF37),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: const Color(
                                0xFFD4AF37,
                              ).withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // The Secondary Translation
                    if (provider.isSplitScreen)
                      Expanded(
                        flex: 1,
                        child: CustomScrollView(
                          controller: _secondaryScrollController,
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.only(
                                left: 20,
                                right: 20,
                                top: 16,
                                bottom:
                                    120, // Menu space goes to bottom element
                              ),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final parallelVerses = provider
                                      .parallelVerses
                                      .entries
                                      .toList();
                                  if (index >= parallelVerses.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final verse = parallelVerses[index];

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10.0,
                                      horizontal: 20.0,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 5.0,
                                            right: 14.0,
                                          ),
                                          child: SizedBox(
                                            width: 24,
                                            child: Text(
                                              verse.key,
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.2),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            verse.value,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(
                                                    alpha: 0.8,
                                                  ), // Slightly dimmed for secondary
                                              fontSize: provider.fontSize,
                                              height: 1.65,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }, childCount: provider.parallelVerses.length),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // The Floating Action Menu
                Positioned(
                  bottom: 35,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                ? Colors.white
                                : Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.25),
                              width: 1,
                            ),
                            boxShadow: [
                              if (Theme.of(context).brightness ==
                                  Brightness.light)
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, -5),
                                )
                              else
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).shadowColor.withValues(alpha: 0.6),
                                  blurRadius: 25,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 10),
                                ),
                            ],
                          ),
                          // Five 48pt buttons plus the gaps need 336pt and
                          // the pill offers 332, so scale down rather than
                          // overflow — narrower phones need it more.
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildMenuButton(
                                  icon: Icons.menu_book_rounded,
                                  onPressed: () {
                                    _showBookSelectorInfo(context, provider);
                                  },
                                ),
                                const SizedBox(width: 16),
                                _buildMenuButton(
                                  icon: Icons.search_rounded,
                                  onPressed: () {
                                    showSearch(
                                      context: context,
                                      delegate: BibleSearchDelegate(provider),
                                    );
                                  },
                                ),
                                const SizedBox(width: 16),
                                _buildMenuButton(
                                  icon: Icons.call_split_rounded,
                                  onPressed: () {
                                    provider.toggleSplitScreen();
                                  },
                                  isActive: provider.isSplitScreen,
                                ),
                                const SizedBox(width: 16),
                                _buildMenuButton(
                                  icon: Icons.language,
                                  onPressed: () {
                                    provider.toggleTranslation();
                                  },
                                ),
                                const SizedBox(width: 16),
                                _buildMenuButton(
                                  icon: Icons.play_circle_outline_rounded,
                                  onPressed: () {
                                    // Future Audio Player Hook
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.audioComingSoon,
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                        ),
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.surface,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Selection Action Bar (Floating)
                if (provider.selectedVerses.isNotEmpty)
                  Positioned(
                    bottom: 110, // Sits above the main floating menu
                    left: 0,
                    right: 0,
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.surface
                                        .withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                if (Theme.of(context).brightness ==
                                    Brightness.light)
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, -5),
                                  )
                                else
                                  BoxShadow(
                                    color: Theme.of(
                                      context,
                                    ).shadowColor.withValues(alpha: 0.15),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 5),
                                  ),
                              ],
                            ),
                            // Scale down slightly on narrow screens instead
                            // of overflowing the pill.
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildHighlightDot(
                                    context,
                                    provider,
                                    const Color(0xFFD4AF37),
                                  ), // Gold
                                  const SizedBox(width: 16),
                                  _buildHighlightDot(
                                    context,
                                    provider,
                                    const Color(0xFF4CA1AF),
                                  ), // Blue
                                  const SizedBox(width: 16),
                                  _buildHighlightDot(
                                    context,
                                    provider,
                                    const Color(0xFF8A9A5B),
                                  ), // Green
                                  const SizedBox(width: 16),
                                  _buildHighlightDot(
                                    context,
                                    provider,
                                    const Color(0xFFE57373),
                                  ), // Red
                                  const SizedBox(width: 16),
                                  Container(
                                    width: 1,
                                    height: 24,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.24),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.history_edu,
                                      color: Color(0xFFD4AF37),
                                      size: 22,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      _showJournalNoteSheet(context, provider);
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.image_outlined,
                                      color: Color(0xFFD4AF37),
                                      size: 21,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      final text = provider.getSelectedText();
                                      final reference = provider
                                          .getSelectedReference();
                                      provider.clearSelection();
                                      showVerseImageSheet(
                                        context,
                                        text: text,
                                        reference: reference,
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(
                                      Icons.copy,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      size: 20,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(
                                          text:
                                              '${provider.getSelectedText()}\n— ${provider.getSelectedReference()}',
                                        ),
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.copiedToClipboard,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          backgroundColor: const Color(
                                            0xFF1E1E1E,
                                          ),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      provider.clearSelection();
                                    },
                                  ),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    icon: Icon(
                                      Icons.close,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.54),
                                      size: 20,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      provider.clearSelection();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPremiumDrawer(BuildContext context, BibleProvider provider) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                AppLocalizations.of(context)!.drawerHeader,
                style: const TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Divider(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.1),
            ),
            Expanded(
              child: ListView(
                children: [
                  ...provider.availableTranslations
                      .where(provider.isInstalled)
                      .map((version) {
                        final isSelected =
                            provider.currentTranslation.id == version.id;
                        return ListTile(
                          leading: Icon(
                            Icons.library_books_rounded,
                            color: isSelected
                                ? const Color(0xFFD4AF37)
                                : Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                            size: 22,
                          ),
                          title: Text(
                            version.name,
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFFD4AF37)
                                  : Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.8),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w400,
                              fontSize: 15,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFFD4AF37),
                                  size: 20,
                                )
                              : null,
                          onTap: () async {
                            await provider.changeTranslation(version.id);
                            if (context.mounted) {
                              Navigator.pop(context); // Close drawer
                            }
                          },
                        );
                      }),
                  Divider(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFFFFD700),
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.getMoreTranslations,
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close the drawer first
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TranslationStoreScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Divider(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.1),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.edit_note_rounded,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              title: Text(
                AppLocalizations.of(context)!.myJournal,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              onTap: () {
                Navigator.pop(context); // Close Drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const JournalScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.bookmark_border_rounded,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.54),
              ),
              title: Text(
                AppLocalizations.of(context)!.bookmarksTitle,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BookmarksScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Builder(
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.05),
          ),
          child: IconButton(
            icon: Icon(
              icon,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : (Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFFA0AEC0)
                        : const Color(0xFFD4AF37)),
              size: 26,
            ),
            splashColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.2),
            highlightColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.1),
            onPressed: onPressed,
          ),
        );
      },
    );
  }

  void _showParallelVersionSelector(
    BuildContext context,
    BibleProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.85),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.parallelTranslation,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: Builder(
                      builder: (context) {
                        final installed = provider.availableTranslations
                            .where(provider.isInstalled)
                            .toList();
                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: installed.length,
                          itemBuilder: (context, index) {
                            final version = installed[index];
                            final isSelected =
                                version.id == provider.parallelTranslation?.id;

                            return ListTile(
                              title: Text(
                                version.name,
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFFD4AF37)
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Color(0xFFD4AF37),
                                    )
                                  : null,
                              onTap: () {
                                provider.setParallelVersion(version.id);
                                Navigator.pop(context);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showBookSelectorInfo(BuildContext context, BibleProvider provider) {
    String selectedBookTemp = provider.selectedBook;
    _SelectorStep currentStep = _SelectorStep.book;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.8),
                  height: MediaQuery.of(context).size.height * 0.75,
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        height: 5,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.24),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          children: [
                            if (currentStep == _SelectorStep.chapter)
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Color(0xFFD4AF37),
                                ),
                                onPressed: () {
                                  setState(() {
                                    currentStep = _SelectorStep.book;
                                  });
                                },
                              ),
                            Expanded(
                              child: Text(
                                currentStep == _SelectorStep.book
                                    ? AppLocalizations.of(context)!.selectBook
                                    : selectedBookTemp,
                                textAlign: currentStep == _SelectorStep.book
                                    ? TextAlign.center
                                    : TextAlign.left,
                                style: const TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (currentStep == _SelectorStep.chapter)
                              Text(
                                AppLocalizations.of(context)!.selectChapter,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.54),
                                  fontSize: 16,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Content
                      Expanded(
                        child: currentStep == _SelectorStep.book
                            ? _buildBookGrid(provider, (book) {
                                setState(() {
                                  selectedBookTemp = book;
                                  currentStep = _SelectorStep.chapter;
                                });
                              })
                            : _buildChapterGrid(provider, selectedBookTemp, (
                                chapter,
                              ) {
                                provider.selectBook(selectedBookTemp);
                                provider.selectChapter(chapter);
                                Navigator.pop(context);
                              }),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBookGrid(
    BibleProvider provider,
    Function(String) onBookSelected,
  ) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: provider.books.length,
      itemBuilder: (context, index) {
        final book = provider.books[index];
        final isSelected = book == provider.selectedBook;
        return Builder(
          builder: (context) {
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 4,
              ),
              title: Text(
                book,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFFD4AF37)
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 18,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Color(0xFFD4AF37))
                  : null,
              onTap: () => onBookSelected(book),
            );
          },
        );
      },
    );
  }

  Widget _buildChapterGrid(
    BibleProvider provider,
    String bookName,
    Function(int) onChapterSelected,
  ) {
    final bookData = provider.currentBible[bookName];
    final int chapterCount = (bookData is Map)
        ? bookData.length
        : (bookData is List ? bookData.length : 1);
    final List<int> chaptersList = List.generate(
      chapterCount,
      (index) => index + 1,
    );

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: chaptersList.length,
      itemBuilder: (context, index) {
        final chapter = chaptersList[index];
        final isSelected =
            (bookName == provider.selectedBook &&
            chapter == provider.selectedChapter);

        return Builder(
          builder: (context) {
            return InkWell(
              onTap: () => onChapterSelected(chapter),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFD4AF37).withValues(alpha: 0.2)
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: const Color(0xFFD4AF37))
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  chapter.toString(),
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFFD4AF37)
                        : Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHighlightDot(
    BuildContext context,
    BibleProvider provider,
    Color color,
  ) {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () {
            provider.applyHighlight(color.toARGB32());
          },
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showJournalNoteSheet(BuildContext context, BibleProvider provider) {
    String category = "Personal";
    final TextEditingController noteController = TextEditingController();
    final String verseRef = provider.getSelectedReference();
    final String verseText = provider.getSelectedText();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    color: Theme.of(context).colorScheme.surface,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFD4AF37,
                              ).withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Header
                        Text(
                          verseRef,
                          style: const TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          verseText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                            fontStyle: FontStyle.italic,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Body
                        TextField(
                          controller: noteController,
                          maxLines: 4,
                          cursorColor: const Color(0xFFD4AF37),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(
                              context,
                            )!.writeRevelation,
                            hintStyle: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.3),
                            ),
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Footer Categories
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: ["Personal", "Sermon", "Prayer"].map((cat) {
                            final isSelected = category == cat;
                            return GestureDetector(
                              onTap: () => setState(() => category = cat),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(
                                          0xFFD4AF37,
                                        ).withValues(alpha: 0.2)
                                      : Theme.of(context).colorScheme.onSurface
                                            .withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFD4AF37)
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                    color: isSelected
                                        ? const Color(0xFFD4AF37)
                                        : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.5),
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 28),
                        // Action
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFD4AF37,
                                ).withValues(alpha: 0.3),
                                blurRadius: 15,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4AF37),
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.surface,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              provider.saveNote(
                                verseId: verseRef,
                                text: verseText,
                                content: noteController.text,
                                category: category,
                              );
                              provider.clearSelection();
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.revelationSealed,
                                    style: const TextStyle(
                                      color: Color(0xFFD4AF37),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.inverseSurface,
                                ),
                              );
                            },
                            child: Text(
                              AppLocalizations.of(context)!.sealRevelation,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showReadingStudio(BuildContext context, BibleProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withValues(alpha: 0.7)
                    : const Color(0xFFFDF5E6).withValues(alpha: 0.8),
                border: const Border(
                  top: BorderSide(color: Color(0xFFFFD700), width: 1.5),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Theme Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.theme,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.wb_sunny_rounded,
                                color: provider.themeMode == ThemeMode.light
                                    ? const Color(0xFFFFD700)
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () =>
                                  provider.setThemeMode(ThemeMode.light),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.nightlight_round,
                                color: provider.themeMode == ThemeMode.dark
                                    ? const Color(0xFFFFD700)
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () =>
                                  provider.setThemeMode(ThemeMode.dark),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Font Size
                  Text(
                    AppLocalizations.of(context)!.fontSize,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.format_size,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      Expanded(
                        child: Slider(
                          value: provider.fontSize,
                          activeColor: const Color(0xFFFFD700),
                          thumbColor: const Color(0xFFFFD700),
                          inactiveColor: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.2),
                          min: 12.0,
                          max: 32.0,
                          divisions: 10,
                          onChanged: (value) => provider.setFontSize(value),
                        ),
                      ),
                      Icon(
                        Icons.format_size,
                        size: 24,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Line Spacing
                  Text(
                    AppLocalizations.of(context)!.lineSpacing,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.format_line_spacing,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      Expanded(
                        child: Slider(
                          value: provider.lineSpacing,
                          activeColor: const Color(0xFFFFD700),
                          thumbColor: const Color(0xFFFFD700),
                          inactiveColor: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.2),
                          min: 1.0,
                          max: 2.5,
                          divisions: 15,
                          onChanged: (value) => provider.setLineSpacing(value),
                        ),
                      ),
                      Icon(
                        Icons.format_line_spacing,
                        size: 24,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
