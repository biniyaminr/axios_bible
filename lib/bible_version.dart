/// A single Bible translation registered in the catalog.
class BibleVersion {
  final String id;
  final String name;
  final String shortName;
  final String downloadUrl;
  final String filename;

  /// True when the translation JSON ships inside the app bundle
  /// (assets/bible_data/) instead of being fetched over the network.
  final bool isBundled;
  Map<String, dynamic>? data;

  BibleVersion({
    required this.id,
    required this.name,
    required this.shortName,
    this.downloadUrl = '',
    required this.filename,
    this.isBundled = false,
    this.data,
  });

  String get assetPath => 'assets/bible_data/$filename';
}
