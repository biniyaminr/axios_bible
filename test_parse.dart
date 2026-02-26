import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  print("Fetching from IPFS...");
  final englishResponse = await http.get(Uri.parse('https://gateway.pinata.cloud/ipfs/bafybeiba33qfhteq2yhiqpdt3zo7wyjbvfnh4u7mdnfkhkfjsixjajkioq'));
  
  if (englishResponse.statusCode != 200) {
    print("Fetch failed");
    return;
  }
  print("Fetched! Decoding...");
  Map<String, dynamic> rawData = json.decode(englishResponse.body);
  
  print("Transforming...");
  final Map<String, dynamic> formattedBible = {};

  for (var entry in rawData.entries) {
    final String key = entry.key; // e.g. "Genesis 1"
    final dynamic verses = entry.value;

    final int lastSpaceIndex = key.lastIndexOf(' ');
    if (lastSpaceIndex == -1) continue; 

    final String bookName = key.substring(0, lastSpaceIndex).trim();
    final String chapterNum = key.substring(lastSpaceIndex + 1).trim();

    if (!formattedBible.containsKey(bookName)) {
      formattedBible[bookName] = <String, dynamic>{};
    }

    final Map<String, String> mappedVerses = {};
    if (verses is Map) {
      verses.forEach((verseNum, verseText) {
        mappedVerses[verseNum.toString()] = verseText.toString();
      });
    }

    formattedBible[bookName][chapterNum] = mappedVerses;
  }
  
  print("Transformation complete.");
  final genesis = formattedBible["Genesis"];
  print("Genesis is practically: ${genesis != null}");
  if (genesis != null) {
      print("Genesis chapters: ${genesis.keys.toList()}");
      final chapter1 = genesis["1"];
      if (chapter1 != null) {
          print("Genesis 1 has ${chapter1.length} verses.");
          print("First verse: ${chapter1["1"]}");
      } else {
          print("Genesis 1 not found!");
      }
  }
}
