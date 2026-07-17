import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'bible_provider.dart';
import 'l10n/app_localizations.dart';

const _gold = Color(0xFFD4AF37);

/// Journal: all notes with category filters, plus a dedicated sermon-note
/// editor for taking notes during a service (passage, preacher, church).
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  /// null = all; otherwise the stored category key.
  String? _filter;

  /// Stored category keys are English; display names are localized.
  String _categoryLabel(AppLocalizations l10n, String category) {
    switch (category) {
      case 'Personal':
        return l10n.categoryPersonal;
      case 'Sermon':
        return l10n.categorySermon;
      case 'Prayer':
        return l10n.categoryPrayer;
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _gold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.church_outlined),
        label: Text(l10n.newSermonNote),
        onPressed: () => _showSermonNoteSheet(context),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Theme.of(
              context,
            ).scaffoldBackgroundColor.withValues(alpha: 0.8),
            elevation: 0,
            pinned: true,
            iconTheme: const IconThemeData(color: _gold),
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    l10n.myJournal,
                    style: const TextStyle(
                      color: _gold,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  background: Container(color: Colors.transparent),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Wrap(
                spacing: 8,
                children: [
                  for (final entry in [
                    (null, l10n.categoryAll),
                    ('Personal', l10n.categoryPersonal),
                    ('Sermon', l10n.categorySermon),
                    ('Prayer', l10n.categoryPrayer),
                  ])
                    ChoiceChip(
                      label: Text(entry.$2),
                      selected: _filter == entry.$1,
                      selectedColor: _gold.withValues(alpha: 0.25),
                      labelStyle: TextStyle(
                        color: _filter == entry.$1
                            ? _gold
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: _filter == entry.$1
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                      side: BorderSide(
                        color: _gold.withValues(
                          alpha: _filter == entry.$1 ? 0.6 : 0.25,
                        ),
                      ),
                      onSelected: (_) => setState(() => _filter = entry.$1),
                    ),
                ],
              ),
            ),
          ),
          Consumer<BibleProvider>(
            builder: (context, provider, child) {
              final notes = _filter == null
                  ? provider.notes
                  : provider.notes
                        .where((n) => n['category'] == _filter)
                        .toList();
              if (notes.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_edu,
                          size: 80,
                          color: _gold.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noRevelations,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.4),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final note = notes[index];
                    final key = ValueKey(
                      note['id'] ?? note['timestamp'] ?? index.toString(),
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Dismissible(
                        key: key,
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24.0),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        onDismissed: (direction) {
                          final id = note['id'];
                          if (id is int) {
                            provider.deleteNoteById(id);
                          }
                        },
                        child: _buildAxiosGlassCard(context, l10n, note),
                      ),
                    );
                  }, childCount: notes.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSermonNoteSheet(BuildContext context) {
    final provider = context.read<BibleProvider>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SermonNoteSheet(provider: provider),
    );
  }

  Widget _buildAxiosGlassCard(
    BuildContext context,
    AppLocalizations l10n,
    Map<String, dynamic> note,
  ) => _JournalCard(note: note, categoryLabel: _categoryLabel);
}

/// Owns its controllers so they are disposed with the sheet's own state,
/// after the close animation — disposing them from `whenComplete` crashes
/// ('_dependents.isEmpty') while the sheet is still animating out.
class _SermonNoteSheet extends StatefulWidget {
  final BibleProvider provider;
  const _SermonNoteSheet({required this.provider});

  @override
  State<_SermonNoteSheet> createState() => _SermonNoteSheetState();
}

class _SermonNoteSheetState extends State<_SermonNoteSheet> {
  final _passage = TextEditingController();
  final _speaker = TextEditingController();
  final _church = TextEditingController();
  final _body = TextEditingController();

  @override
  void dispose() {
    _passage.dispose();
    _speaker.dispose();
    _church.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    InputDecoration deco(String hint, IconData icon) => InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 18, color: _gold),
      filled: true,
      fillColor: Theme.of(
        context,
      ).colorScheme.onSurface.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      isDense: true,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.newSermonNote,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _gold,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passage,
              decoration: deco(l10n.sermonPassage, Icons.menu_book_rounded),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _speaker,
                    decoration: deco(l10n.sermonSpeaker, Icons.person_outline),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _church,
                    decoration: deco(l10n.sermonChurch, Icons.church_outlined),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _body,
              autofocus: true,
              minLines: 4,
              maxLines: 8,
              decoration: deco(l10n.sermonNoteHint, Icons.edit_note),
            ),
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                if (_body.text.trim().isEmpty) return;
                widget.provider.saveNote(
                  verseId: _passage.text.trim(),
                  text: '',
                  content: _body.text,
                  category: 'Sermon',
                  speaker: _speaker.text,
                  church: _church.text,
                );
                Navigator.pop(context);
              },
              child: Text(
                l10n.saveLabel,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalCard extends StatelessWidget {
  final Map<String, dynamic> note;
  final String Function(AppLocalizations, String) categoryLabel;
  const _JournalCard({required this.note, required this.categoryLabel});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final speaker = (note['speaker'] ?? '').toString();
    final church = (note['church'] ?? '').toString();
    final meta = [
      if (speaker.isNotEmpty) speaker,
      if (church.isNotEmpty) church,
    ].join(' • ');
    final reference = (note['reference'] ?? '').toString();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _gold.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, size: 16, color: _gold),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            reference.isEmpty ? l10n.myJournal : reference,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _gold,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (note['category'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _gold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _gold.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        categoryLabel(l10n, note['category'].toString()),
                        style: const TextStyle(
                          color: _gold,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
              if (meta.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        meta,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if ((note['text'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.only(left: 14),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: _gold.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    note['text'].toString(),
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.5,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Divider(color: _gold.withValues(alpha: 0.15)),
              const SizedBox(height: 12),
              Text(
                note['userNote'] ?? '',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.6,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
