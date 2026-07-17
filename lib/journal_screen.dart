import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'bible_provider.dart';
import 'l10n/app_localizations.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Theme.of(
              context,
            ).scaffoldBackgroundColor.withValues(alpha: 0.8),
            elevation: 0,
            pinned: true,
            iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    AppLocalizations.of(context)!.myJournal,
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  background: Container(color: Colors.transparent),
                ),
              ),
            ),
          ),
          Consumer<BibleProvider>(
            builder: (context, provider, child) {
              if (provider.notes.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_edu,
                          size: 80,
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.noRevelations,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 24.0,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final note = provider.notes[index];
                    // DB id is unique even when two notes share a timestamp.
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
                          child: Icon(
                            Icons.delete_outline,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 28,
                          ),
                        ),
                        onDismissed: (direction) {
                          provider.deleteNote(index);
                        },
                        child: _buildAxiosGlassCard(context, note),
                      ),
                    );
                  }, childCount: provider.notes.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAxiosGlassCard(BuildContext context, Map<String, dynamic> note) {
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
            border: Border.all(
              color: const Color(
                0xFFD4AF37,
              ).withValues(alpha: 0.3), // Gold Border
            ),
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
              // Header: Reference and Category
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: Color(0xFFD4AF37),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        note['reference'] ?? 'Unknown',
                        style: const TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  if (note['category'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        note['category'],
                        style: const TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Scripture Text
              Container(
                padding: const EdgeInsets.only(left: 14),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  note['text'] ?? '...',
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
              const SizedBox(height: 20),
              Divider(color: const Color(0xFFD4AF37).withValues(alpha: 0.15)),
              const SizedBox(height: 16),
              // User Thought
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
