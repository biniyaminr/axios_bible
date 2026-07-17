import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'bible_provider.dart';
import 'l10n/app_localizations.dart';
import 'bible_search_delegate.dart';
import 'bookmarks_screen.dart';
import 'settings_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BibleProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            actions: [
              IconButton(
                icon: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: BibleSearchDelegate(provider),
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.bookmarks_rounded,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BookmarksScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.more_vert,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const SettingsDialog(),
                  );
                },
              ),
              _buildLanguageToggle(context, provider),
              const SizedBox(width: 16),
            ],
          ),
          drawer: _buildDrawer(context, provider),
          body: Stack(
            children: [
              _buildBody(context, provider),
              _buildSelectionToolbar(context, provider),
              if (!provider.isLoading &&
                  provider.selectedBook.isNotEmpty &&
                  provider.selectedVerses.isEmpty)
                Positioned(
                  bottom: 120,
                  right: 16,
                  child: _buildFloatingChapterNav(context, provider),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageToggle(BuildContext context, BibleProvider provider) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (BuildContext bottomSheetContext) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        AppLocalizations.of(context)!.selectTranslation,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.availableTranslations.length,
                      itemBuilder: (context, index) {
                        final version = provider.availableTranslations[index];
                        final isSelected =
                            version.id == provider.currentTranslation.id;
                        return ListTile(
                          title: Text(
                            version.name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                          onTap: () {
                            provider.loadTranslation(version.id);
                            Navigator.pop(bottomSheetContext);
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.language,
                size: 18,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 6),
              Text(
                provider.currentTranslation.shortName,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, BibleProvider provider) {
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              _buildDrawerHeader(context, provider),
              TabBar(
                indicatorColor: const Color(0xFFD4AF37),
                labelColor: const Color(0xFFD4AF37),
                unselectedLabelColor: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                tabs: [
                  Tab(text: AppLocalizations.of(context)!.oldTestament),
                  Tab(text: AppLocalizations.of(context)!.newTestament),
                ],
              ),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        children: [
                          _buildBooksList(
                            context,
                            provider,
                            provider.oldTestamentBooks,
                          ),
                          _buildBooksList(
                            context,
                            provider,
                            provider.newTestamentBooks,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context, BibleProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.menu_book_rounded,
                size: 28,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Bible',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  size: 20,
                  color: Theme.of(context).hintColor,
                ),
                const SizedBox(width: 12),
                Text(
                  'Search book...',
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBooksList(
    BuildContext context,
    BibleProvider provider,
    List<String> books,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        final isSelected = provider.selectedBook == book;
        final bookData = provider.currentBible[book];
        List<int> chapters = [];
        if (bookData is Map) {
          chapters =
              bookData.keys.map((k) => int.tryParse(k.toString()) ?? 1).toList()
                ..sort();
        } else if (bookData is List) {
          chapters = List.generate(bookData.length, (i) => i + 1);
        }

        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: PageStorageKey(book),
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 0,
            ),
            title: Text(
              book,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            initiallyExpanded: isSelected,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: chapters.map((chapter) {
                    final isCurrentChapter =
                        isSelected && provider.selectedChapter == chapter;
                    return InkWell(
                      onTap: () {
                        provider.selectBook(book);
                        provider.selectChapter(chapter);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isCurrentChapter
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          chapter.toString(),
                          style: TextStyle(
                            color: isCurrentChapter
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, BibleProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.selectedBook.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.pleaseSelectBook),
      );
    }
    final verses = provider.verses;
    if (verses.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.noVersesFound));
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;

        final velocity = details.primaryVelocity!;

        // Quick flick to the left -> Next Chapter
        if (velocity < -300) {
          provider.nextChapter();
        }
        // Quick flick to the right -> Previous Chapter
        else if (velocity > 300) {
          provider.previousChapter();
        }
      },
      child: Container(
        color: Colors
            .transparent, // Ensures taps/swipes across the whole screen are captured
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(
            top: 24,
            bottom: 180,
          ), // Extra padding for the pill
          itemCount: verses.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 32, top: 16),
                  child: Text(
                    '${provider.selectedBook} ${provider.selectedChapter}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            }
            final verseNum = verses.keys.elementAt(index - 1);
            final verseText = verses[verseNum]!;
            return _buildVerseCard(context, verseNum, verseText, provider);
          },
        ),
      ),
    );
  }

  Widget _buildHighlightedText(
    String text,
    String query,
    BuildContext context,
    BibleProvider provider,
  ) {
    if (query.isEmpty) {
      return Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontFamily: GoogleFonts.notoSansEthiopic().fontFamily,
          fontSize: provider.fontSize,
          height: 1.6,
          letterSpacing: 0.2,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      );
    }

    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();

    List<TextSpan> spans = [];
    int start = 0;
    int indexOfMatch = lowerText.indexOf(lowerQuery, start);

    if (indexOfMatch == -1) {
      return Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontFamily: GoogleFonts.notoSansEthiopic().fontFamily,
          fontSize: provider.fontSize,
          height: 1.6,
          letterSpacing: 0.2,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      );
    }

    while (indexOfMatch != -1) {
      // 1. Add normal text BEFORE the match
      if (indexOfMatch > start) {
        spans.add(TextSpan(text: text.substring(start, indexOfMatch)));
      }

      // 2. Add the HIGHLIGHTED text
      spans.add(
        TextSpan(
          text: text.substring(indexOfMatch, indexOfMatch + query.length),
          style: TextStyle(
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(
              alpha: 0.2,
            ), // The marker background
            color: Theme.of(context).colorScheme.primary, // The bold gold text
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      start = indexOfMatch + query.length;
      indexOfMatch = lowerText.indexOf(lowerQuery, start);
    }

    // 3. Add any normal text remaining AFTER the last match
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontFamily: GoogleFonts.notoSansEthiopic().fontFamily,
          fontSize: provider.fontSize,
          height: 1.6,
          letterSpacing: 0.2,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        children: spans,
      ),
    );
  }

  Widget _buildVerseCard(
    BuildContext context,
    String verseNum,
    String verseText,
    BibleProvider provider,
  ) {
    final isSelected = provider.selectedVerses.contains(verseNum);
    final highlightColor = provider.getHighlightColor(verseNum);

    return InkWell(
      onTap: () => provider.toggleVerseSelection(verseNum),
      child: Container(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
            : (highlightColor != null
                  ? highlightColor.withValues(alpha: 0.3)
                  : Colors.transparent),
        padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16, top: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6, top: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              verseNum,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            if (provider.isBookmarked(verseNum)) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.bookmark_rounded,
                                size: 12,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    WidgetSpan(
                      child: provider.currentSearchQuery.isNotEmpty
                          ? _buildHighlightedText(
                              verseText,
                              provider.currentSearchQuery,
                              context,
                              provider,
                            )
                          : Text(
                              verseText,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    fontFamily: GoogleFonts.notoSansEthiopic()
                                        .fontFamily,
                                    fontSize: provider.fontSize,
                                    height: 1.6,
                                    letterSpacing: 0.2,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingChapterNav(
    BuildContext context,
    BibleProvider provider,
  ) {
    final currentChapter = provider.selectedChapter;
    final hasPrev = provider.hasPreviousChapter;
    final hasNext = provider.hasNextChapter;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: hasPrev ? () => provider.previousChapter() : null,
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
              color: hasPrev
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.grey.withValues(alpha: 0.5),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 16),
            Text(
              provider.isAmharic
                  ? 'ምዕራፍ $currentChapter'
                  : 'Chapter $currentChapter',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: hasNext ? () => provider.nextChapter() : null,
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
              color: hasNext
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.grey.withValues(alpha: 0.5),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionToolbar(BuildContext context, BibleProvider provider) {
    if (provider.selectedVerses.isEmpty) return const SizedBox.shrink();

    return Positioned(
      bottom: 30, // Replaces floating point
      left: 16,
      right: 16,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => provider.clearSelection(),
              ),
              Container(
                width: 1,
                height: 24,
                color: Colors.grey.withValues(alpha: 0.3),
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              IconButton(
                icon: const Icon(Icons.content_copy_rounded),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: provider.getSelectedText()),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.copiedToClipboard,
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  provider.clearSelection();
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _showColorPicker(context, provider),
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_border_rounded),
                onPressed: () => provider.toggleBookmarks(),
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded),
                onPressed: () {
                  SharePlus.instance.share(
                    ShareParams(
                      text:
                          '${provider.getSelectedText()}\n— ${provider.getSelectedReference()}',
                    ),
                  );
                  provider.clearSelection();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context, BibleProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Highlight',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildColorCircle(
                    context,
                    provider,
                    Colors.yellow.toARGB32(),
                  ),
                  _buildColorCircle(context, provider, Colors.green.toARGB32()),
                  _buildColorCircle(context, provider, Colors.blue.toARGB32()),
                  _buildColorCircle(
                    context,
                    provider,
                    Colors.purple.toARGB32(),
                  ),
                  _buildColorCircle(context, provider, Colors.pink.toARGB32()),
                  InkWell(
                    onTap: () {
                      provider.removeHighlight();
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: const Icon(
                        Icons.format_color_reset_rounded,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColorCircle(
    BuildContext context,
    BibleProvider provider,
    int colorValue,
  ) {
    return InkWell(
      onTap: () {
        provider.applyHighlight(colorValue);
        Navigator.pop(context);
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Color(colorValue),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(colorValue).withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }
}
