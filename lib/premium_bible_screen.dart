import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'main.dart'; // Import BibleProvider, BibleSearchDelegate, SettingsDialog, BookmarksScreen
import 'journal_screen.dart';

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
        final maxScrollOffset = _secondaryScrollController.position.maxScrollExtent;
        final targetOffset = _primaryScrollController.offset;
        _secondaryScrollController.jumpTo(targetOffset > maxScrollOffset ? maxScrollOffset : targetOffset);
      }
      _isSyncing = false;
    });

    _secondaryScrollController.addListener(() {
      if (_isSyncing) return;
      _isSyncing = true;
      if (_primaryScrollController.hasClients) {
        final maxScrollOffset = _primaryScrollController.position.maxScrollExtent;
        final targetOffset = _secondaryScrollController.offset;
        _primaryScrollController.jumpTo(targetOffset > maxScrollOffset ? maxScrollOffset : targetOffset);
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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
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
                'No verses found yet.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24),
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
                            backgroundColor: Colors.transparent, // Must be transparent for blur
                            elevation: 0,
                            leading: Builder(
                              builder: (context) => IconButton(
                                icon: const Icon(Icons.menu, color: Color(0xFFD4AF37)),
                                onPressed: () {
                                  Scaffold.of(context).openDrawer();
                                },
                              ),
                            ),
                            actions: [
                              IconButton(
                                icon: const Icon(Icons.settings, color: Color(0xFFD4AF37)),
                                onPressed: () {
                                  showDialog(context: context, builder: (context) => const SettingsDialog());
                                },
                              ),
                            ],
                            flexibleSpace: ClipRect(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                child: FlexibleSpaceBar(
                                  titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                                    color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.65),
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
                              bottom: provider.isSplitScreen ? 20 : 120, // Extra bottom padding for floating menu only if not split
                            ),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final verse = verses[index];
                                  final isSelected = provider.selectedVerses.contains(verse.key);
                                  final highlightColor = provider.getHighlightColor(verse.key);

                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      splashColor: const Color(0xFFD4AF37).withValues(alpha: 0.3), // Axios Gold
                                      highlightColor: Colors.transparent,
                                      onTap: () {
                                        provider.toggleVerseSelection(verse.key);
                                      },
                                      onLongPress: () {
                                        if (!isSelected) {
                                          provider.toggleVerseSelection(verse.key);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
                                        margin: const EdgeInsets.symmetric(vertical: 2.0),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFFD4AF37).withValues(alpha: 0.15)
                                              : (highlightColor != null
                                                  ? highlightColor.withValues(alpha: 0.3)
                                                  : Colors.transparent),
                                          borderRadius: BorderRadius.circular(8.0),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Muted Verse Number with Note Indicator
                                            Padding(
                                              padding: const EdgeInsets.only(top: 5.0, right: 14.0),
                                              child: SizedBox(
                                                width: 36,
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    if (provider.hasNote('${provider.selectedBook} ${provider.selectedChapter}:${verse.key}'))
                                                      const Padding(
                                                        padding: EdgeInsets.only(right: 4.0),
                                                        child: Icon(Icons.bookmark, color: Color(0xFFD4AF37), size: 10),
                                                      ),
                                                    Text(
                                                      verse.key,
                                                      textAlign: TextAlign.right,
                                                      style: TextStyle(
                                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            // Verse Text
                                            Expanded(
                                              child: Text(
                                                verse.value,
                                                style: TextStyle(
                                                  color: Theme.of(context).colorScheme.onSurface, 
                                                  fontSize: provider.fontSize, // Synced with Settings slider
                                                  height: 1.65,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                childCount: verses.length,
                              ),
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
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
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
                          padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 4.0),
                          child: TextButton.icon(
                            onPressed: () => _showParallelVersionSelector(context, provider),
                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFD4AF37), size: 18),
                            label: Text(
                              provider.parallelTranslation?.name ?? 'Select Version',
                              style: const TextStyle(
                                color: Color(0xFFD4AF37),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                                bottom: 120, // Menu space goes to bottom element
                              ),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final parallelVerses = provider.parallelVerses.entries.toList();
                                    if (index >= parallelVerses.length) return const SizedBox.shrink();
                                    final verse = parallelVerses[index];

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(top: 5.0, right: 14.0),
                                            child: SizedBox(
                                              width: 24,
                                              child: Text(
                                                verse.key,
                                                textAlign: TextAlign.right,
                                                style: TextStyle(
                                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
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
                                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8), // Slightly dimmed for secondary
                                                fontSize: provider.fontSize,
                                                height: 1.65,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  childCount: provider.parallelVerses.length,
                                ),
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
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 25,
                                spreadRadius: 2,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildMenuButton(
                                icon: Icons.menu_book_rounded,
                                onPressed: () {
                                  _showBookSelectorInfo(context, provider);
                                },
                              ),
                              const SizedBox(width: 24),
                              _buildMenuButton(
                                icon: Icons.search_rounded,
                                onPressed: () {
                                  showSearch(context: context, delegate: BibleSearchDelegate(provider));
                                },
                              ),
                              const SizedBox(width: 24),
                              _buildMenuButton(
                                icon: Icons.call_split_rounded,
                                onPressed: () {
                                  provider.toggleSplitScreen();
                                },
                                isActive: provider.isSplitScreen,
                              ),
                              const SizedBox(width: 24),
                              _buildMenuButton(
                                icon: Icons.play_circle_outline_rounded,
                                onPressed: () {
                                  // Future Audio Player Hook
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Audio Player coming soon!', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                                      backgroundColor: Theme.of(context).colorScheme.surface,
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
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 5),
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildHighlightDot(context, provider, const Color(0xFFD4AF37)), // Gold
                                const SizedBox(width: 16),
                                _buildHighlightDot(context, provider, const Color(0xFF4CA1AF)), // Blue
                                const SizedBox(width: 16),
                                _buildHighlightDot(context, provider, const Color(0xFF8A9A5B)), // Green
                                const SizedBox(width: 16),
                                _buildHighlightDot(context, provider, const Color(0xFFE57373)), // Red
                                const SizedBox(width: 16),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.history_edu, color: Color(0xFFD4AF37), size: 22),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    _showJournalNoteSheet(context, provider);
                                  },
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.copy, color: Colors.white, size: 20),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    // Copy functionality
                                    final text = provider.getSelectedText();
                                    // You can add Clipboard.setData here if needed
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Copied to clipboard', style: TextStyle(color: Colors.white)),
                                        backgroundColor: Color(0xFF1E1E1E),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                    provider.clearSelection();
                                  },
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), size: 20),
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
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'Menu & Translation',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
            Expanded(
              child: ListView.builder(
                itemCount: provider.availableTranslations.length,
                itemBuilder: (context, index) {
                  final version = provider.availableTranslations[index];
                  final isSelected = provider.currentTranslation.id == version.id;
                  return ListTile(
                    leading: Icon(Icons.book, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
                    title: Text(
                      version.name,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFFD4AF37) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    trailing: isSelected ? const Icon(Icons.check, color: Color(0xFFD4AF37)) : null,
                    onTap: () {
                      provider.loadTranslation(version.id);
                      Navigator.pop(context); // Close drawer
                    },
                  );
                },
              ),
            ),
            Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.edit_note_rounded, color: Theme.of(context).colorScheme.onSurface),
              title: Text('Journal', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              onTap: () {
                Navigator.pop(context); // Close Drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const JournalScreen()),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.bookmark_border_rounded, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
              title: Text('Bookmarks', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BookmarksScreen()));
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton({required IconData icon, required VoidCallback onPressed, bool isActive = false}) {
    return Builder(
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive 
              ? const Color(0xFFD4AF37).withValues(alpha: 0.2) // Highlight if split is active
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
          ),
          child: IconButton(
            icon: Icon(icon, color: const Color(0xFFD4AF37), size: 26),
            splashColor: const Color(0xFFD4AF37).withValues(alpha: 0.2),
            highlightColor: const Color(0xFFD4AF37).withValues(alpha: 0.1),
            onPressed: onPressed,
          ),
        );
      }
    );
  }

  void _showParallelVersionSelector(BuildContext context, BibleProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Parallel Translation',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: provider.availableTranslations.length,
                      itemBuilder: (context, index) {
                        final version = provider.availableTranslations[index];
                        final isSelected = version.id == provider.parallelTranslation?.id;
                        
                        return ListTile(
                          title: Text(
                            version.name,
                            style: TextStyle(
                              color: isSelected 
                                ? const Color(0xFFD4AF37) 
                                : Theme.of(context).colorScheme.onSurface,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                          trailing: isSelected 
                            ? const Icon(Icons.check, color: Color(0xFFD4AF37)) 
                            : null,
                          onTap: () {
                            provider.setParallelVersion(version.id);
                            Navigator.pop(context);
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                  height: MediaQuery.of(context).size.height * 0.75,
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        height: 5,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                        child: Row(
                          children: [
                            if (currentStep == _SelectorStep.chapter)
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: Color(0xFFD4AF37)),
                                onPressed: () {
                                  setState(() {
                                    currentStep = _SelectorStep.book;
                                  });
                                },
                              ),
                            Expanded(
                              child: Text(
                                currentStep == _SelectorStep.book ? 'Select Book' : selectedBookTemp,
                                textAlign: currentStep == _SelectorStep.book ? TextAlign.center : TextAlign.left,
                                style: const TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (currentStep == _SelectorStep.chapter)
                              Text(
                                'Select Chapter',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
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
                            : _buildChapterGrid(provider, selectedBookTemp, (chapter) {
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

  Widget _buildBookGrid(BibleProvider provider, Function(String) onBookSelected) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: provider.books.length,
      itemBuilder: (context, index) {
        final book = provider.books[index];
        final isSelected = book == provider.selectedBook;
        return Builder(
          builder: (context) {
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
              title: Text(
                book,
                style: TextStyle(
                  color: isSelected ? const Color(0xFFD4AF37) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 18,
                ),
              ),
              trailing: isSelected ? const Icon(Icons.check, color: Color(0xFFD4AF37)) : null,
              onTap: () => onBookSelected(book),
            );
          }
        );
      },
    );
  }

  Widget _buildChapterGrid(BibleProvider provider, String bookName, Function(int) onChapterSelected) {
    final bookData = provider.currentBible[bookName];
    final int chapterCount = (bookData is Map) ? bookData.length : (bookData is List ? bookData.length : 1);
    final List<int> chaptersList = List.generate(chapterCount, (index) => index + 1);

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
        final isSelected = (bookName == provider.selectedBook && chapter == provider.selectedChapter);
        
        return Builder(
          builder: (context) {
            return InkWell(
              onTap: () => onChapterSelected(chapter),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFD4AF37).withValues(alpha: 0.2) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected ? Border.all(color: const Color(0xFFD4AF37)) : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  chapter.toString(),
                  style: TextStyle(
                    color: isSelected ? const Color(0xFFD4AF37) : Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildHighlightDot(BuildContext context, BibleProvider provider, Color color) {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () {
            provider.applyHighlight(color.value);
          },
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
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
      }
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
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    color: const Color(0xFF1E1E1E).withValues(alpha: 0.85),
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
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
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
                            color: Colors.white.withValues(alpha: 0.7),
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
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'Write your revelation...',
                            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                            filled: true,
                            fillColor: Colors.black.withValues(alpha: 0.3),
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
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                    ? const Color(0xFFD4AF37).withValues(alpha: 0.2) 
                                    : Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent,
                                  ),
                                ),
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                    color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withValues(alpha: 0.5),
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                                color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                                blurRadius: 15,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4AF37),
                              foregroundColor: Colors.black,
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
                                const SnackBar(
                                  content: Text('Revelation Sealed', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                                  backgroundColor: Colors.black,
                                ),
                              );
                            },
                            child: const Text('Seal Revelation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }
}
