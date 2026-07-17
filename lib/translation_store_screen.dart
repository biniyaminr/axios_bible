import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'bible_provider.dart';
import 'l10n/app_localizations.dart';

class TranslationStoreScreen extends StatefulWidget {
  const TranslationStoreScreen({super.key});

  @override
  State<TranslationStoreScreen> createState() => _TranslationStoreScreenState();
}

class _TranslationStoreScreenState extends State<TranslationStoreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  static const Color _gold = Color(0xFFFFD700);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.translationStore,
          style: const TextStyle(color: _gold, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: _gold),
        centerTitle: true,
      ),
      body: Consumer<BibleProvider>(
        builder: (context, provider, child) {
          final lowerQuery = _query.toLowerCase().trim();
          final translations =
              provider.availableTranslations.where((t) {
                if (lowerQuery.isEmpty) return true;
                return t.name.toLowerCase().contains(lowerQuery) ||
                    t.shortName.toLowerCase().contains(lowerQuery) ||
                    t.id.toLowerCase().contains(lowerQuery);
              }).toList()..sort((a, b) {
                // Installed translations first, then alphabetical
                final ai = provider.isInstalled(a) ? 0 : 1;
                final bi = provider.isInstalled(b) ? 0 : 1;
                if (ai != bi) return ai - bi;
                return a.name.toLowerCase().compareTo(b.name.toLowerCase());
              });

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  cursorColor: _gold,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(
                      context,
                    )!.searchTranslationsHint,
                    hintStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    prefixIcon: const Icon(Icons.search, color: _gold),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: _gold),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
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
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppLocalizations.of(context)!.translationsSummary(
                      translations.length,
                      translations.where((t) => t.isBundled).length,
                    ),
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: translations.length,
                  itemBuilder: (context, index) {
                    final translation = translations[index];
                    final isInstalled = provider.isInstalled(translation);
                    final isActive =
                        provider.currentTranslation.id == translation.id;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? _gold
                              : _gold.withValues(alpha: 0.3),
                          width: isActive ? 1.5 : 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        onTap: isInstalled
                            ? () => _readTranslation(provider, translation)
                            : null,
                        title: Text(
                          translation.name,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          isActive
                              ? AppLocalizations.of(
                                  context,
                                )!.currentlyReading(translation.shortName)
                              : isInstalled
                              ? AppLocalizations.of(
                                  context,
                                )!.installedTranslation(translation.shortName)
                              : translation.isBundled
                              ? AppLocalizations.of(
                                  context,
                                )!.readyToInstall(translation.shortName)
                              : AppLocalizations.of(
                                  context,
                                )!.readyToDownload(translation.shortName),
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                        trailing: _buildTrailing(
                          provider,
                          translation,
                          isInstalled,
                          isActive,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _readTranslation(
    BibleProvider provider,
    BibleVersion translation,
  ) async {
    await provider.changeTranslation(translation.id);
    if (mounted) Navigator.pop(context);
  }

  Widget _buildTrailing(
    BibleProvider provider,
    BibleVersion translation,
    bool isInstalled,
    bool isActive,
  ) {
    if (provider.downloadingVersions.contains(translation.id)) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(color: _gold, strokeWidth: 2),
      );
    }

    if (isInstalled) {
      final isDefault =
          translation.id == 'am_1954' || translation.id == 'en_kjv';
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: _gold, size: 28),
          if (!isDefault && !isActive)
            IconButton(
              tooltip: AppLocalizations.of(context)!.removeTranslation,
              icon: Icon(
                Icons.delete_outline,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.4),
                size: 24,
              ),
              onPressed: () => provider.removeTranslation(translation),
            ),
        ],
      );
    }

    return IconButton(
      icon: const Icon(
        Icons.download_for_offline_outlined,
        color: _gold,
        size: 30,
      ),
      onPressed: () async {
        final ok = await provider.downloadTranslation(translation);
        if (!ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.downloadFailed),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }
}
