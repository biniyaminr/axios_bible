import 'package:flutter/material.dart';

import 'bible_provider.dart';
import 'l10n/app_localizations.dart';

class BibleSearchDelegate extends SearchDelegate<String?> {
  final BibleProvider provider;

  BibleSearchDelegate(this.provider);

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  Widget _buildHighlightedText(
    String text,
    String query,
    BuildContext context,
  ) {
    if (query.isEmpty) {
      return Text(text, style: TextStyle(color: Colors.grey[400]));
    }

    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();

    List<TextSpan> spans = [];
    int start = 0;
    int indexOfMatch = lowerText.indexOf(lowerQuery, start);

    if (indexOfMatch == -1) {
      return Text(text, style: TextStyle(color: Colors.grey[400]));
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
        style: TextStyle(
          color: Colors.grey[400],
          height: 1.5,
        ), // Standard verse styling
        children: spans,
      ),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSuggestionsOrResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSuggestionsOrResults(context);
  }

  Widget _buildSuggestionsOrResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return Container();
    }

    final results = provider.searchBible(query);

    if (results.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.noResults));
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              '${result['book']} ${result['chapter']}:${result['verse']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: _buildHighlightedText(result['text'], query, context),
            ),
            onTap: () {
              provider.performSearch(query);
              provider.selectBook(result['book'].toString());
              provider.selectChapter(int.parse(result['chapter'].toString()));
              close(context, null);
            },
          ),
        );
      },
    );
  }
}
