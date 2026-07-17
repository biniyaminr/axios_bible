import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'bible_provider.dart';
import 'l10n/app_localizations.dart';

class BookmarksScreen extends StatelessWidget {
  /// Switches the shell to the reading tab. Needed when this screen lives
  /// as a tab in the IndexedStack, where there is no route to pop.
  final VoidCallback? onGoToReading;

  const BookmarksScreen({super.key, this.onGoToReading});

  @override
  Widget build(BuildContext context) {
    return Consumer<BibleProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              AppLocalizations.of(context)!.bookmarksTitle,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
          body: provider.bookmarks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmark_border_rounded,
                        size: 64,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.noBookmarks,
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.bookmarks.length,
                  itemBuilder: (context, index) {
                    final bookmark = provider.bookmarks[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          '${bookmark['book']} ${bookmark['chapter']}:${bookmark['verseNum']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            bookmark['text'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(height: 1.5),
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          onPressed: () => provider.removeBookmark(bookmark),
                        ),
                        onTap: () {
                          final opened = provider.openSavedReference(
                            bookmark['book'] as String,
                            bookmark['chapter'] as int,
                          );
                          if (!opened) return;
                          // Pushed from the drawer: pop back to the reader.
                          // Shown as a tab: switch tabs instead.
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            onGoToReading?.call();
                          }
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
