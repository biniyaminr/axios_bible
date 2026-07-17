import 'package:flutter_test/flutter_test.dart';
import 'package:amharic_bible/book_catalog.dart';

void main() {
  test('isNewTestamentBook classifies OT, deuterocanon, and NT', () {
    expect(isNewTestamentBook('Malachi'), false);
    expect(isNewTestamentBook('I Esdras'), false); // Apocrypha -> not NT
    expect(isNewTestamentBook('II Maccabees'), false);
    expect(isNewTestamentBook('Matthew'), true);
    expect(isNewTestamentBook('Revelation'), true);
    expect(isNewTestamentBook('የማቴዎስ ወንጌል'), true); // Amharic Matthew
    expect(isNewTestamentBook('መዝሙረ ዳዊት'), false); // Amharic Psalms
    expect(isNewTestamentBook('Kwakwalaka'), isNull); // unknown -> null
  });
}
