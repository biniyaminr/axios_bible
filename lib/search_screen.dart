import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bible_provider.dart';
import 'l10n/app_localizations.dart';

class SearchScreen extends StatefulWidget {
  final VoidCallback? onGoToReading;

  /// Returns to the tab the user came from. Search is a tab inside an
  /// IndexedStack, so there is no route for the AppBar to pop to and it
  /// would otherwise render with no way back.
  final VoidCallback? onBack;

  const SearchScreen({super.key, this.onGoToReading, this.onBack});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  int _activeFilterIndex = 0; // Tracks active pill index

  static const Color _gold = Color(0xFFFFD700); // 2. Axios Gold

  // 3. Exact Glow Effect
  BoxDecoration get _axiosGoldGlow => BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: _gold.withValues(alpha: 0.5), width: 1.5),
    boxShadow: [
      BoxShadow(
        color: _gold.withValues(alpha: 0.3),
        blurRadius: 20,
        spreadRadius: 2,
      ),
    ],
  );

  @override
  void initState() {
    super.initState();
    final provider = context.read<BibleProvider>();
    if (provider.currentSearchQuery.isNotEmpty) {
      _controller.text = provider.currentSearchQuery;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerThemeSearch(String themeWord, BibleProvider provider) {
    _controller.text = themeWord;
    provider.performSearch(themeWord, filterIndex: _activeFilterIndex);
    provider.addRecentSearch(themeWord);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BibleProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Theme.of(
            context,
          ).scaffoldBackgroundColor, // Strictly Pure Black
          appBar: _buildAppBar(),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(provider),
                const SizedBox(height: 25),
                _buildFilterPills(),

                if (provider.currentSearchQuery.isEmpty &&
                    provider.searchResults.isEmpty) ...[
                  const SizedBox(height: 35),
                  _buildSectionTitle(
                    AppLocalizations.of(context)!.popularThemes,
                    _gold,
                  ),
                  const SizedBox(height: 15),
                  _buildThemesRow(provider),
                  if (provider.recentSearches.isNotEmpty) ...[
                    const SizedBox(height: 35),
                    _buildSectionTitle(
                      AppLocalizations.of(context)!.recentSearches,
                      Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(height: 15),
                    _buildRecentSearches(provider),
                  ],
                  const SizedBox(height: 50),
                ] else ...[
                  const SizedBox(height: 35),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle(
                        AppLocalizations.of(context)!.navSearch,
                        Theme.of(context).colorScheme.onSurface,
                      ),
                      TextButton(
                        onPressed: () {
                          _controller.clear();
                          provider
                              .clearActiveSearchQuery(); // Required interaction
                        },
                        child: Text(
                          AppLocalizations.of(context)!.clear,
                          style: TextStyle(color: _gold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  if (provider.searchResults.isEmpty &&
                      provider.currentSearchQuery.isNotEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          AppLocalizations.of(context)!.noResults,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.54),
                          ),
                        ),
                      ),
                    )
                  else
                    _buildResultsList(provider),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: widget.onBack == null
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back, color: _gold),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () {
                FocusScope.of(context).unfocus();
                widget.onBack!.call();
              },
            ),
      title: Text(
        AppLocalizations.of(context)!.searchBibleTitle,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSearchBar(BibleProvider provider) {
    return Container(
      decoration: _axiosGoldGlow,
      child: TextField(
        controller: _controller,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 16,
        ),
        cursorColor: _gold,
        onChanged: (val) =>
            provider.performSearch(val, filterIndex: _activeFilterIndex),
        onSubmitted: (val) {
          provider.performSearch(val, filterIndex: _activeFilterIndex);
          provider.addRecentSearch(val);
        },
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.searchHint,
          hintStyle: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.3),
            fontStyle: FontStyle.italic,
          ),
          prefixIcon: const Icon(Icons.search, color: _gold),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildFilterPills() {
    return Row(
      children: [
        Expanded(
          child: _buildPill(0, AppLocalizations.of(context)!.filterVerses),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildPill(1, AppLocalizations.of(context)!.filterChapters),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildPill(2, AppLocalizations.of(context)!.filterTexts),
        ),
      ],
    );
  }

  Widget _buildPill(int index, String title) {
    final isActive = _activeFilterIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilterIndex = index;
        });
        if (_controller.text.isNotEmpty) {
          context.read<BibleProvider>().performSearch(
            _controller.text,
            filterIndex: index,
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        // Switch between solid Gold and dark inactive background
        decoration: BoxDecoration(
          color: isActive
              ? _gold
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.transparent, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            // When active, text is pure Black, otherwise grey
            color: isActive
                ? Colors.black
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color accentColor) {
    return Text(
      title,
      style: TextStyle(
        color: accentColor,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildThemesRow(BibleProvider provider) {
    // Suggested terms must be in the language of the loaded translation,
    // or they can never match its text.
    final ethiopic = provider.currentTranslationIsEthiopic;
    final love = ethiopic ? 'ፍቅር' : 'love';
    final faith = ethiopic ? 'እምነት' : 'faith';
    final hope = ethiopic ? 'ተስፋ' : 'hope';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildThemeCard(
          love,
          Icons.favorite,
          () => _triggerThemeSearch(love, provider),
        ),
        const SizedBox(width: 15),
        _buildThemeCard(
          faith,
          Icons.shield,
          () => _triggerThemeSearch(faith, provider),
        ),
        const SizedBox(width: 15),
        _buildThemeCard(
          hope,
          Icons.wb_sunny,
          () => _triggerThemeSearch(hope, provider),
        ),
      ],
    );
  }

  Widget _buildThemeCard(String title, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            // 4. Glassmorphism strictly applied
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 25),
              decoration: _axiosGoldGlow,
              child: Column(
                children: [
                  Icon(icon, color: _gold, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The user's actual committed searches, as tappable chips.
  Widget _buildRecentSearches(BibleProvider provider) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final query in provider.recentSearches)
          ActionChip(
            avatar: Icon(
              Icons.history,
              size: 16,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            label: Text(query),
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 13,
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            side: BorderSide(color: _gold.withValues(alpha: 0.25)),
            onPressed: () => _triggerThemeSearch(query, provider),
          ),
      ],
    );
  }

  Widget _buildResultsList(BibleProvider provider) {
    return ListView.builder(
      // 3. Requires ListView.builder over searchResults
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.searchResults.length > 50
          ? 50
          : provider.searchResults.length,
      itemBuilder: (context, index) {
        final item = provider.searchResults[index];
        final ref = '${item['book']} ${item['chapter']}:${item['verse']}';
        final text = item['text']!;

        return _buildVerseCard(
          ref,
          text,
          provider,
          book: item['book'] as String?,
          chapter: int.tryParse(item['chapter'].toString()),
        );
      },
    );
  }

  Widget _buildVerseCard(
    String ref,
    String text,
    BibleProvider provider, {
    String? book,
    int? chapter,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          if (book != null && chapter != null && book.isNotEmpty) {
            provider.selectBook(book);
            provider.selectChapter(chapter);
            widget.onGoToReading?.call();
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            // Apply Glassmorphism to Results too
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(
                  alpha: 0.8,
                ), // Dark base to stack under blur
                borderRadius: BorderRadius.circular(16),
                // Slight border
                border: Border.all(color: _gold.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ref,
                        style: TextStyle(
                          color: _gold,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: _gold.withValues(alpha: 0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      // Small grey arrow icon
                      const Icon(Icons.call_made, color: Colors.grey, size: 20),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    '"$text"',
                    style: GoogleFonts.notoSansEthiopic(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                      height: 1.6,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
