import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'l10n/app_localizations.dart';

const _gold = Color(0xFFD4AF37);

/// The bundled Ethiopic family. Only Regular ships in assets and GoogleFonts
/// runtime fetching is off, so requesting a heavier weight from google_fonts
/// throws at runtime — reference the family directly instead.
const String _ethiopicFont = 'NotoSansEthiopic';

/// Square shareable card for a verse, sized for Telegram/social feeds.
/// Rendered on screen inside a [RepaintBoundary], then rasterized to PNG.
class VerseCard extends StatelessWidget {
  final String text;
  final String reference;
  final bool dark;

  const VerseCard({
    super.key,
    required this.text,
    required this.reference,
    this.dark = true,
  });

  /// Long passages step down through these sizes; [FittedBox] handles the
  /// rest, so even a whole-chapter selection still fits the square.
  double get _fontSize {
    final len = text.length;
    if (len < 90) return 26;
    if (len < 180) return 22;
    if (len < 300) return 18;
    if (len < 520) return 15;
    return 12;
  }

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : const Color(0xFF2C1E16);
    return SizedBox(
      width: 360,
      height: 360,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [Color(0xFF111111), Color(0xFF000000)]
                : const [Color(0xFFFFFDF7), Color(0xFFF7EFDD)],
          ),
          border: Border.all(color: _gold, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 20),
          child: Column(
            children: [
              Icon(Icons.format_quote_rounded, color: _gold, size: 26),
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Text(
                        text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: _ethiopicFont,
                          color: fg,
                          fontSize: _fontSize,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                reference,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: _ethiopicFont,
                  color: _gold,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 1,
                color: _gold.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'AXIOS BIBLE',
                style: TextStyle(
                  fontFamily: _ethiopicFont,
                  color: fg.withValues(alpha: 0.45),
                  fontSize: 9,
                  letterSpacing: 2.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rasterizes the boundary behind [key] to a PNG in the temp directory.
/// pixelRatio 3 turns the 360pt card into a 1080x1080 image.
Future<File> renderVerseCardToPng(GlobalKey key) async {
  final boundary =
      key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 3.0);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/axios_verse.png');
  await file.writeAsBytes(byteData!.buffer.asUint8List());
  return file;
}

/// Shows a preview of the verse card with a share action.
Future<void> showVerseImageSheet(
  BuildContext context, {
  required String text,
  required String reference,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) =>
        _VerseImageSheet(text: text, reference: reference),
  );
}

class _VerseImageSheet extends StatefulWidget {
  final String text;
  final String reference;

  const _VerseImageSheet({required this.text, required this.reference});

  @override
  State<_VerseImageSheet> createState() => _VerseImageSheetState();
}

class _VerseImageSheetState extends State<_VerseImageSheet> {
  final GlobalKey _cardKey = GlobalKey();
  bool _dark = true;
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final file = await renderVerseCardToPng(_cardKey);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: widget.reference),
      );
      if (mounted) navigator.pop();
    } catch (e) {
      debugPrint('Error sharing verse image: $e');
      messenger.showSnackBar(SnackBar(content: Text(l10n.shareImageFailed)));
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Only the boundary's subtree lands in the PNG.
            RepaintBoundary(
              key: _cardKey,
              child: VerseCard(
                text: widget.text,
                reference: widget.reference,
                dark: _dark,
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: true, label: Text(l10n.themeDark)),
                ButtonSegment(value: false, label: Text(l10n.themeLight)),
              ],
              selected: {_dark},
              onSelectionChanged: (s) => setState(() => _dark = s.first),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: _sharing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.share_rounded, size: 18),
                label: Text(l10n.shareAsImage),
                onPressed: _sharing ? null : _share,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
