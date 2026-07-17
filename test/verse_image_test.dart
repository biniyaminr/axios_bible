import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_bible/verse_image.dart';

void main() {
  testWidgets('VerseCard renders the verse text and reference', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VerseCard(
            text: 'እግዚአብሔር እረኛዬ ነው፤ የሚያሳጣኝ የለም።',
            reference: 'መዝሙረ ዳዊት 23:1',
          ),
        ),
      ),
    );

    expect(find.text('እግዚአብሔር እረኛዬ ነው፤ የሚያሳጣኝ የለም።'), findsOneWidget);
    expect(find.text('መዝሙረ ዳዊት 23:1'), findsOneWidget);
    expect(find.text('AXIOS BIBLE'), findsOneWidget);
  });

  testWidgets('VerseCard stays square regardless of verse length', (
    tester,
  ) async {
    final long = 'And God said, ' * 60;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: VerseCard(text: long, reference: 'Genesis 1:3'),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(VerseCard));
    expect(size.width, 360);
    expect(size.height, 360);
    expect(tester.takeException(), isNull); // no overflow from a long passage
  });

  // The whole point of the feature is the exported PNG, so rasterize for
  // real: 360pt at pixelRatio 3 must give the 1080x1080 Telegram expects.
  testWidgets('card rasterizes to a 1080x1080 image', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: key,
              child: const VerseCard(
                text: 'For God so loved the world.',
                reference: 'John 3:16',
              ),
            ),
          ),
        ),
      ),
    );

    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      expect(image.width, 1080);
      expect(image.height, 1080);
      image.dispose();
    });
  });
}
