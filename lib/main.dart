import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BibleVersion {
  final String id;
  final String name;
  final String shortName;
  final String ipfsUrl;
  final String filename;
  Map<String, dynamic>? data;

  BibleVersion({
    required this.id,
    required this.name,
    required this.shortName,
    required this.ipfsUrl,
    required this.filename,
    this.data,
  });
}

void main() {
  runApp(const BibleApp());
}

class BibleApp extends StatelessWidget {
  const BibleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BibleProvider()..init(),
      child: Consumer<BibleProvider>(
        builder: (context, provider, child) {
          return MaterialApp(
            title: 'የአማርኛ መጽሐፍ ቅዱስ',
            debugShowCheckedModeBanner: false,
            themeMode: provider.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.light,
              ),
              fontFamily: GoogleFonts.notoSansEthiopic().fontFamily,
              scaffoldBackgroundColor: const Color(0xFFFAFAFA),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
              ),
              fontFamily: GoogleFonts.notoSansEthiopic().fontFamily,
            ),
            home: const DashboardScreen(),
          );
        },
      ),
    );
  }
}

/// State management for Bible data and user selections
class BibleProvider extends ChangeNotifier {
  final List<BibleVersion> _availableTranslations = [
    BibleVersion(
      id: 'am_1954',
      name: 'Amharic 1954',
      shortName: 'AM',
      filename: 'amharic_cache.json',
      ipfsUrl: 'https://gateway.pinata.cloud/ipfs/bafybeiba33qfhteq2yhiqpdt3zo7wyjbvfnh4u7mdnfkhkfjsixjajkioq',
    ),
    BibleVersion(
      id: 'en_kjv',
      name: 'English KJV',
      shortName: 'KJV',
      filename: 'english_kjv_cache.json',
      ipfsUrl: 'https://gateway.pinata.cloud/ipfs/bafybeifxugyq4urrxo72nnh3oax5ydt4h63fhmcplw5h6ssu4dff5oigim',
    ),
  ];
  String _selectedVersionId = 'am_1954';

  String _selectedBook = '';
  int _selectedChapter = 1;
  bool _isLoading = true;
  String? _error;

  // Selection State
  final Set<String> _selectedVerses = {};

  // Highlights State
  Map<String, int> _highlights = {};

  // Bookmarks State
  List<Map<String, dynamic>> _bookmarks = [];

  // Settings State
  ThemeMode _themeMode = ThemeMode.system;
  double _fontSize = 18.0;

  BibleProvider() {
    loadSettings();
    loadHighlights();
    loadBookmarks();
  }

  Future<void> init() async {
    await loadTranslation(_selectedVersionId);
  }

  // Getters
  List<BibleVersion> get availableTranslations => _availableTranslations;
  BibleVersion get currentTranslation => _availableTranslations.firstWhere((v) => v.id == _selectedVersionId);
  bool get isAmharic => _selectedVersionId == 'am_1954';
  bool get isEnglish => _selectedVersionId != 'am_1954';
  String get currentLanguage => currentTranslation.name;
  String get selectedBook => _selectedBook;
  int get selectedChapter => _selectedChapter;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get books => currentBible.keys.toList();
  
  List<String> get oldTestamentBooks {
    return books.take(39).toList();
  }

  List<String> get newTestamentBooks {
    return books.skip(39).toList();
  }

  Set<String> get selectedVerses => _selectedVerses;
  List<Map<String, dynamic>> get bookmarks => _bookmarks;
  ThemeMode get themeMode => _themeMode;
  double get fontSize => _fontSize;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      saveSettings();
      notifyListeners();
    }
  }

  void setFontSize(double size) {
    if (_fontSize != size) {
      _fontSize = size;
      saveSettings();
      notifyListeners();
    }
  }

  Future<void> loadSettings() async {
    try {
      final file = await _getLocalFile('settings.json');
      if (await file.exists()) {
        final String contents = await file.readAsString();
        final Map<String, dynamic> decoded = json.decode(contents);
        
        if (decoded.containsKey('themeMode')) {
          final themeIndex = decoded['themeMode'] as int;
          _themeMode = ThemeMode.values[themeIndex];
        }
        if (decoded.containsKey('fontSize')) {
          _fontSize = (decoded['fontSize'] as num).toDouble();
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading settings: $e");
    }
  }

  Future<void> saveSettings() async {
    try {
      final file = await _getLocalFile('settings.json');
      final settings = {
        'themeMode': _themeMode.index,
        'fontSize': _fontSize,
      };
      await file.writeAsString(json.encode(settings));
    } catch (e) {
      debugPrint("Error saving settings: $e");
    }
  }

  void toggleVerseSelection(String verseNum) {
    if (_selectedVerses.contains(verseNum)) {
      _selectedVerses.remove(verseNum);
    } else {
      _selectedVerses.add(verseNum);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedVerses.clear();
    notifyListeners();
  }

  String _getVerseKey(String verse) => "${_selectedBook}_${_selectedChapter}_$verse";

  Color? getHighlightColor(String verse) {
    final colorValue = _highlights[_getVerseKey(verse)];
    if (colorValue != null) {
      return Color(colorValue);
    }
    return null;
  }

  Future<void> loadHighlights() async {
    try {
      final file = await _getLocalFile('highlights.json');
      if (await file.exists()) {
        final String contents = await file.readAsString();
        final Map<String, dynamic> decoded = json.decode(contents);
        _highlights = decoded.map((key, value) => MapEntry(key, value as int));
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading highlights: $e");
    }
  }

  Future<void> saveHighlights() async {
    try {
      final file = await _getLocalFile('highlights.json');
      await file.writeAsString(json.encode(_highlights));
    } catch (e) {
      debugPrint("Error saving highlights: $e");
    }
  }

  void applyHighlight(int colorValue) {
    for (String verse in _selectedVerses) {
      _highlights[_getVerseKey(verse)] = colorValue;
    }
    saveHighlights();
    clearSelection();
  }

  void removeHighlight() {
    for (String verse in _selectedVerses) {
      _highlights.remove(_getVerseKey(verse));
    }
    saveHighlights();
    clearSelection();
  }

  Future<void> loadBookmarks() async {
    try {
      final file = await _getLocalFile('bookmarks.json');
      if (await file.exists()) {
        final String contents = await file.readAsString();
        final List<dynamic> decoded = json.decode(contents);
        _bookmarks = List<Map<String, dynamic>>.from(decoded);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading bookmarks: $e");
    }
  }

  Future<void> saveBookmarks() async {
    try {
      final file = await _getLocalFile('bookmarks.json');
      await file.writeAsString(json.encode(_bookmarks));
    } catch (e) {
      debugPrint("Error saving bookmarks: $e");
    }
  }

  void toggleBookmarks() {
    for (String verse in _selectedVerses) {
      final existsIndex = _bookmarks.indexWhere((b) => 
        b['book'] == _selectedBook && 
        b['chapter'] == _selectedChapter && 
        b['verseNum'] == verse
      );
      
      if (existsIndex != -1) {
        _bookmarks.removeAt(existsIndex);
      } else {
        _bookmarks.add({
          'book': _selectedBook,
          'chapter': _selectedChapter,
          'verseNum': verse,
          'text': verses[verse].toString(),
        });
      }
    }
    saveBookmarks();
    clearSelection();
  }

  void removeBookmark(Map<String, dynamic> bookmark) {
    _bookmarks.remove(bookmark);
    saveBookmarks();
    notifyListeners();
  }

  bool isBookmarked(String verseNum) {
    return _bookmarks.any((b) => 
      b['book'] == _selectedBook && 
      b['chapter'] == _selectedChapter && 
      b['verseNum'] == verseNum
    );
  }

  String getSelectedText() {
    if (_selectedVerses.isEmpty) return '';

    final sortedVerses = _selectedVerses.toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    final currentVersesMap = verses;
    final StringBuffer textBuffer = StringBuffer();
    
    for (var vNum in sortedVerses) {
      if (currentVersesMap.containsKey(vNum)) {
        textBuffer.write('${currentVersesMap[vNum]} ');
      }
    }

    final String combinedText = textBuffer.toString().trim();
    final verseRange = sortedVerses.join(',');
    return '"$combinedText" — $_selectedBook $_selectedChapter:$verseRange (Bible)';
  }

  Future<File> _getLocalFile(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$filename');
  }

  /// Load a specific translation by ID
  Future<void> loadTranslation(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final version = _availableTranslations.firstWhere((v) => v.id == id);

      // If already in memory
      if (version.data != null) {
        // Change book appropriately using the index paradigm if book names differ
        _handleTranslationSwitch(id);
        
        _selectedVersionId = id;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Check local cache
      final file = await _getLocalFile(version.filename);
      String jsonBody = '';

      if (await file.exists()) {
        debugPrint("Loading ${version.name} from local cache...");
        jsonBody = await file.readAsString();
      } else {
        debugPrint("Fetching ${version.name} from IPFS...");
        final response = await http.get(Uri.parse(version.ipfsUrl));
        if (response.statusCode == 200) {
          jsonBody = response.body;
          await file.writeAsString(jsonBody);
        } else {
          // Fallback logic for English if IPFS fails
          if (id == 'en_kjv') {
             jsonBody = await rootBundle.loadString('assets/bible_data/english_kjv_bible.json');
          } else {
             throw Exception("Failed to load ${version.name} from IPFS");
          }
        }
      }

      final rawData = json.decode(jsonBody);
      version.data = _transformBibleData(rawData);
      
      _handleTranslationSwitch(id);
      _selectedVersionId = id;

      if (_selectedBook.isEmpty && version.data!.isNotEmpty) {
        _selectedBook = version.data!.keys.first;
        _selectedChapter = 1;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading Bible data: $e");
      _error = "Check your connection and restart.";
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleTranslationSwitch(String newId) {
    if (_selectedBook.isEmpty) return;

    final version = _availableTranslations.firstWhere((v) => v.id == newId);
    if (version.data == null || version.data!.isEmpty) return;

    // Grab current index and switch book name based on that index in the new translation map
    final currentBookKeys = currentBible.keys.toList();
    final bookIndex = currentBookKeys.indexOf(_selectedBook);

    if (bookIndex != -1) {
      final newBookKeys = version.data!.keys.toList();
      if (bookIndex < newBookKeys.length) {
        _selectedBook = newBookKeys[bookIndex];
      } else {
        _selectedBook = newBookKeys.first;
      }
    }
  }

  // Helper function to translate your specific JSON structure
  Map<String, dynamic> _transformBibleData(Map<String, dynamic> rawData) {
    final Map<String, dynamic> formattedBible = {};

    // Check if the JSON is wrapped in a "books" array
    if (rawData.containsKey('books') && rawData['books'] is List) {
      final List<dynamic> booksList = rawData['books'];
      
      for (var book in booksList) {
        final String bookTitle = book['title']?.toString().trim() ?? 'Unknown';
        final Map<String, dynamic> formattedChapters = {};

        if (book['chapters'] is List) {
          for (var chapter in book['chapters']) {
            final String chapterNum = chapter['chapter']?.toString() ?? '1';
            final Map<String, String> formattedVerses = {};

            if (chapter['verses'] is List) {
              final List<dynamic> versesList = chapter['verses'];
              // Map the array of verses into a numbered dictionary starting at "1"
              for (int i = 0; i < versesList.length; i++) {
                formattedVerses[(i + 1).toString()] = versesList[i].toString();
              }
            }
            formattedChapters[chapterNum] = formattedVerses;
          }
        }
        formattedBible[bookTitle] = formattedChapters;
      }
      return formattedBible;
    } 
    
    // If it's already in the correct format (fallback for English if it differs)
    return rawData;
  }

  /// Select a book and reset chapter to 1
  void selectBook(String book) {
    if (_selectedBook != book) {
      _selectedBook = book;
      _selectedChapter = 1; 
      notifyListeners();
    }
  }

  // Changes the chapter and tells the screen to update
  void selectChapter(int chapter) {
    _selectedChapter = chapter;
    notifyListeners(); 
  }

  bool get hasPreviousChapter {
    if (books.isEmpty || chapters.isEmpty) return false;
    return books.indexOf(_selectedBook) > 0 || chapters.indexOf(_selectedChapter) > 0;
  }

  bool get hasNextChapter {
    if (books.isEmpty || chapters.isEmpty) return false;
    return books.indexOf(_selectedBook) < books.length - 1 || chapters.indexOf(_selectedChapter) < chapters.length - 1;
  }

  void previousChapter() {
    if (!hasPreviousChapter) return;
    
    final currentChapters = chapters;
    final currentIndex = currentChapters.indexOf(_selectedChapter);
    
    if (currentIndex > 0) {
      _selectedChapter = currentChapters[currentIndex - 1];
      notifyListeners();
    } else {
      final currentBooks = books;
      final bookIndex = currentBooks.indexOf(_selectedBook);
      if (bookIndex > 0) {
        _selectedBook = currentBooks[bookIndex - 1];
        final newChapters = chapters;
        _selectedChapter = newChapters.isNotEmpty ? newChapters.last : 1;
        notifyListeners();
      }
    }
  }

  void nextChapter() {
    if (!hasNextChapter) return;
    
    final currentChapters = chapters;
    final currentIndex = currentChapters.indexOf(_selectedChapter);
    
    if (currentIndex < currentChapters.length - 1) {
      _selectedChapter = currentChapters[currentIndex + 1];
      notifyListeners();
    } else {
      final currentBooks = books;
      final bookIndex = currentBooks.indexOf(_selectedBook);
      if (bookIndex < currentBooks.length - 1) {
        _selectedBook = currentBooks[bookIndex + 1];
        final newChapters = chapters;
        _selectedChapter = newChapters.isNotEmpty ? newChapters.first : 1;
        notifyListeners();
      }
    }
  }

  /// Get the currently selected Bible based on language
  Map<String, dynamic> get currentBible => currentTranslation.data ?? {};

  /// Get chapters for the selected book
  List<int> get chapters {
    if (_selectedBook.isEmpty) return <int>[];
    final book = currentBible[_selectedBook];
    if (book == null || book is! Map) return <int>[];

    // Force Dart to build a strict integer list
    final List<int> chapterList = <int>[];
    for (var key in book.keys) {
      final int? num = int.tryParse(key.toString());
      if (num != null) {
        chapterList.add(num);
      }
    }
    chapterList.sort();
    return chapterList;
  }
  /// Get verses for the selected chapter
 Map<String, String> get verses {
    if (_selectedBook.isEmpty) return {};
    final book = currentBible[_selectedBook];
    if (book == null) return {};
    
    // 1. Find the Chapter (Safely handles if JSON used a List or Map)
    dynamic chapter;
    if (book is List) {
      int chapterNum = int.tryParse(_selectedChapter.toString()) ?? 1;
      // Intelligently grab the chapter depending on if the array starts at index 0 or 1
      if (chapterNum < book.length && book[0] == null) {
        chapter = book[chapterNum]; 
      } else if (chapterNum - 1 >= 0 && chapterNum - 1 < book.length) {
        chapter = book[chapterNum - 1];
      }
    } else if (book is Map) {
      chapter = book[_selectedChapter.toString()] ?? book[int.tryParse(_selectedChapter.toString())];
    }

    if (chapter == null) return {};
    
    final Map<String, String> result = {};
    
    // 2. Parse the Verses (Safely handles if JSON used a List or Map)
    if (chapter is List) {
      for (int i = 0; i < chapter.length; i++) {
        if (chapter[i] != null && chapter[i].toString().trim().isNotEmpty) {
           // If index 0 is null, it means Verse 1 is at index 1
           int verseNum = chapter[0] == null ? i : (i + 1);
           result[verseNum.toString()] = chapter[i].toString();
        }
      }
    } else if (chapter is Map) {
      chapter.forEach((key, value) {
        if (value != null && value.toString().trim().isNotEmpty) {
          result[key.toString()] = value.toString();
        }
      });
    }
    
    // 3. Sort by verse number so they appear in correct order
    final sortedKeys = result.keys.where((k) => int.tryParse(k) != null).toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    
    return Map.fromEntries(
      sortedKeys.map((k) => MapEntry(k, result[k]!)),
    );
  }

  /// Get total verse count for selected chapter
  int get verseCount => verses.length;
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BibleProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            actions: [
              IconButton(
                icon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurface),
                onPressed: () {
                  showSearch(context: context, delegate: BibleSearchDelegate(provider));
                },
              ),
              IconButton(
                icon: Icon(Icons.bookmarks_rounded, color: Theme.of(context).colorScheme.onSurface),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const BookmarksScreen()));
                },
              ),
              IconButton(
                icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onSurface),
                onPressed: () {
                  showDialog(context: context, builder: (context) => const SettingsDialog());
                },
              ),
              _buildLanguageToggle(context, provider),
              const SizedBox(width: 16),
            ],
          ),
          drawer: _buildDrawer(context, provider),
          body: Stack(
            children: [
              _buildBody(context, provider),
              _buildSelectionToolbar(context, provider),
              if (!provider.isLoading && provider.selectedBook.isNotEmpty && provider.selectedVerses.isEmpty)
                Positioned(
                  bottom: 120,
                  right: 16,
                  child: _buildFloatingChapterNav(context, provider),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageToggle(BuildContext context, BibleProvider provider) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (BuildContext bottomSheetContext) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Select Translation',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.availableTranslations.length,
                      itemBuilder: (context, index) {
                        final version = provider.availableTranslations[index];
                        final isSelected = version.id == provider.currentTranslation.id;
                        return ListTile(
                          title: Text(
                            version.name,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Theme.of(context).colorScheme.primary : null,
                            ),
                          ),
                          trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
                          onTap: () {
                            provider.loadTranslation(version.id);
                            Navigator.pop(bottomSheetContext);
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.language, size: 18, color: Theme.of(context).colorScheme.onPrimaryContainer),
              const SizedBox(width: 6),
              Text(
                provider.currentTranslation.shortName,
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, BibleProvider provider) {
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              _buildDrawerHeader(context, provider),
              TabBar(
                indicatorColor: const Color(0xFFD4AF37),
                labelColor: const Color(0xFFD4AF37),
                unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                tabs: [
                  Tab(text: provider.isAmharic ? 'ብሉይ ኪዳን' : 'Old Testament'),
                  Tab(text: provider.isAmharic ? 'ሐዲስ ኪዳን' : 'New Testament'),
                ],
              ),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        children: [
                          _buildBooksList(context, provider, provider.oldTestamentBooks),
                          _buildBooksList(context, provider, provider.newTestamentBooks),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context, BibleProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, size: 28, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'Bible',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 20, color: Theme.of(context).hintColor),
                const SizedBox(width: 12),
                Text(
                  'Search book...',
                  style: TextStyle(color: Theme.of(context).hintColor, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBooksList(BuildContext context, BibleProvider provider, List<String> books) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        final isSelected = provider.selectedBook == book;
        final bookData = provider.currentBible[book];
        List<int> chapters = [];
        if (bookData is Map) {
          chapters = bookData.keys.map((k) => int.tryParse(k.toString()) ?? 1).toList()..sort();
        } else if (bookData is List) {
          chapters = List.generate(bookData.length, (i) => i + 1);
        }

        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: PageStorageKey(book),
            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            title: Text(
              book,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            initiallyExpanded: isSelected,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: chapters.map((chapter) {
                    final isCurrentChapter = isSelected && provider.selectedChapter == chapter;
                    return InkWell(
                      onTap: () {
                        provider.selectBook(book);
                        provider.selectChapter(chapter);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isCurrentChapter
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          chapter.toString(),
                          style: TextStyle(
                            color: isCurrentChapter
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, BibleProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.selectedBook.isEmpty) {
      return const Center(child: Text('Please select a book'));
    }
    final verses = provider.verses;
    if (verses.isEmpty) {
      return const Center(child: Text('No verses found'));
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        
        final velocity = details.primaryVelocity!;
        
        // Quick flick to the left -> Next Chapter
        if (velocity < -300) {
          provider.nextChapter();
        }
        // Quick flick to the right -> Previous Chapter
        else if (velocity > 300) {
          provider.previousChapter();
        }
      },
      child: Container(
        color: Colors.transparent, // Ensures taps/swipes across the whole screen are captured
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 24, bottom: 180), // Extra padding for the pill
          itemCount: verses.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 32, top: 16),
                  child: Text(
                    '${provider.selectedBook} ${provider.selectedChapter}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            }
            final verseNum = verses.keys.elementAt(index - 1);
            final verseText = verses[verseNum]!;
            return _buildVerseCard(context, verseNum, verseText, provider);
          },
        ),
      ),
    );
  }

  Widget _buildVerseCard(BuildContext context, String verseNum, String verseText, BibleProvider provider) {
    final isSelected = provider.selectedVerses.contains(verseNum);
    final highlightColor = provider.getHighlightColor(verseNum);

    return InkWell(
      onTap: () => provider.toggleVerseSelection(verseNum),
      child: Container(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
            : (highlightColor != null ? highlightColor.withOpacity(0.3) : Colors.transparent),
        padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16, top: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6, top: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              verseNum,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            if (provider.isBookmarked(verseNum)) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.bookmark_rounded, size: 12, color: Theme.of(context).colorScheme.primary),
                            ],
                          ],
                        ),
                      ),
                    ),
                    TextSpan(
                      text: verseText,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontFamily: GoogleFonts.notoSansEthiopic().fontFamily,
                            fontSize: provider.fontSize,
                            height: 1.6,
                            letterSpacing: 0.2,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingChapterNav(BuildContext context, BibleProvider provider) {
    final currentChapter = provider.selectedChapter;
    final hasPrev = provider.hasPreviousChapter;
    final hasNext = provider.hasNextChapter;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.95),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: hasPrev ? () => provider.previousChapter() : null,
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
              color: hasPrev ? Theme.of(context).colorScheme.onSurface : Colors.grey.withOpacity(0.5),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 16),
            Text(
              provider.isAmharic ? 'ምዕራፍ $currentChapter' : 'Chapter $currentChapter',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: hasNext ? () => provider.nextChapter() : null,
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
              color: hasNext ? Theme.of(context).colorScheme.onSurface : Colors.grey.withOpacity(0.5),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionToolbar(BuildContext context, BibleProvider provider) {
    if (provider.selectedVerses.isEmpty) return const SizedBox.shrink();

    return Positioned(
      bottom: 30, // Replaces floating point
      left: 16,
      right: 16,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
            ],
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => provider.clearSelection(),
              ),
              Container(width: 1, height: 24, color: Colors.grey.withOpacity(0.3), margin: const EdgeInsets.symmetric(horizontal: 8)),
              IconButton(
                icon: const Icon(Icons.content_copy_rounded),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: provider.getSelectedText()));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 2)));
                  provider.clearSelection();
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _showColorPicker(context, provider),
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_border_rounded),
                onPressed: () => provider.toggleBookmarks(),
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded),
                onPressed: () {
                  Share.share(provider.getSelectedText());
                  provider.clearSelection();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context, BibleProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Highlight', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildColorCircle(context, provider, Colors.yellow.value),
                  _buildColorCircle(context, provider, Colors.green.value),
                  _buildColorCircle(context, provider, Colors.blue.value),
                  _buildColorCircle(context, provider, Colors.purple.value),
                  _buildColorCircle(context, provider, Colors.pink.value),
                  InkWell(
                    onTap: () {
                      provider.removeHighlight();
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade400)),
                      child: const Icon(Icons.format_color_reset_rounded, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColorCircle(BuildContext context, BibleProvider provider, int colorValue) {
    return InkWell(
      onTap: () {
        provider.applyHighlight(colorValue);
        Navigator.pop(context);
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Color(colorValue),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Color(colorValue).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
      ),
    );
  }
}

class BibleSearchDelegate extends SearchDelegate<String?> {
  final BibleProvider provider;

  BibleSearchDelegate(this.provider);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
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

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.trim().isEmpty) {
      return const Center(child: Text('Search the Bible...'));
    }

    final lowerQuery = query.toLowerCase();
    final Map<String, dynamic> bible = provider.currentBible;
    final List<Map<String, dynamic>> results = [];

    // Loop through books
    for (String bookName in bible.keys) {
      final bookData = bible[bookName];

      // Get chapters
      List<int> chaptersList = [];
      if (bookData is Map) {
        chaptersList = bookData.keys.map((k) => int.tryParse(k.toString()) ?? 1).toList()..sort();
      } else if (bookData is List) {
        chaptersList = List.generate(bookData.length, (i) => i + 1);
      }

      for (int chapterNum in chaptersList) {
        dynamic chapter;
        if (bookData is Map) {
          chapter = bookData[chapterNum.toString()] ?? bookData[chapterNum];
        } else if (bookData is List) {
          if (chapterNum < bookData.length && bookData[0] == null) {
            chapter = bookData[chapterNum];
          } else if (chapterNum - 1 >= 0 && chapterNum - 1 < bookData.length) {
            chapter = bookData[chapterNum - 1];
          }
        }

        if (chapter == null) continue;

        // Parse verses
        if (chapter is Map) {
          chapter.forEach((verseKey, verseValue) {
            if (verseValue != null && verseValue.toString().trim().isNotEmpty) {
              final text = verseValue.toString();
              if (text.toLowerCase().contains(lowerQuery) || bookName.toLowerCase().contains(lowerQuery)) {
                results.add({
                  'book': bookName,
                  'chapter': chapterNum,
                  'verse': verseKey.toString(),
                  'text': text,
                });
              }
            }
          });
        } else if (chapter is List) {
          for (int i = 0; i < chapter.length; i++) {
            if (chapter[i] != null && chapter[i].toString().trim().isNotEmpty) {
              int verseNum = chapter[0] == null ? i : (i + 1);
              final text = chapter[i].toString();
              if (text.toLowerCase().contains(lowerQuery) || bookName.toLowerCase().contains(lowerQuery)) {
                results.add({
                  'book': bookName,
                  'chapter': chapterNum,
                  'verse': verseNum.toString(),
                  'text': text,
                });
              }
            }
          }
        }
      }
    }

    if (results.isEmpty) {
      return const Center(child: Text('No matches found.'));
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return ListTile(
          title: Text('${item['book']} ${item['chapter']}:${item['verse']}'),
          subtitle: Text(
            item['text'],
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            provider.selectBook(item['book']);
            provider.selectChapter(item['chapter']);
            close(context, null);
          },
        );
      },
    );
  }
}

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BibleProvider>(
      builder: (context, provider, _) {
        return Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Settings', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Theme', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                SegmentedButton<ThemeMode>(
                  style: SegmentedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    selectedBackgroundColor: Theme.of(context).colorScheme.primary,
                    selectedForegroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto), label: Text('System')),
                    ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode), label: Text('Light')),
                    ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode), label: Text('Dark')),
                  ],
                  selected: {provider.themeMode},
                  onSelectionChanged: (Set<ThemeMode> newSelection) {
                    provider.setThemeMode(newSelection.first);
                  },
                ),
                const SizedBox(height: 32),
                Text('Font Size', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.format_size, size: 16),
                    Expanded(
                      child: Slider(
                        value: provider.fontSize,
                        min: 12.0,
                        max: 32.0,
                        divisions: 10,
                        label: provider.fontSize.round().toString(),
                        onChanged: (value) {
                          provider.setFontSize(value);
                        },
                      ),
                    ),
                    const Icon(Icons.format_size, size: 24),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BibleProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              provider.isAmharic ? 'ዕልባቶች' : 'Bookmarks',
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        provider.isAmharic ? 'ምንም ዕልባቶች የሉም' : 'No bookmarks yet.',
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
                            color: Colors.black.withOpacity(0.05),
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
                          icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                          onPressed: () => provider.removeBookmark(bookmark),
                        ),
                        onTap: () {
                          provider.selectBook(bookmark['book']);
                          provider.selectChapter(bookmark['chapter']);
                          Navigator.pop(context);
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

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _getGreeting(bool isAmharic) {
    final hour = DateTime.now().hour;
    if (isAmharic) {
      if (hour < 12) return 'እንደምን አደሩ,';
      if (hour < 18) return 'እንደምን ዋሉ,';
      return 'እንደምን አመሹ,';
    } else {
      if (hour < 12) return 'Good Morning,';
      if (hour < 18) return 'Good Afternoon,';
      return 'Good Evening,';
    }
  }

  String _getFormattedDate(bool isAmharic) {
    final now = DateTime.now();
    if (isAmharic) {
      final months = ['ጥር', 'የካቲት', 'መጋቢት', 'ሚያዝያ', 'ግንቦት', 'ሰኔ', 'ሐምሌ', 'ነሐሴ', 'መስከረም', 'ጥቅምት', 'ኅዳር', 'ታኅሣሥ'];
      final weekdays = ['ሰኞ', 'ማክሰኞ', 'ረቡዕ', 'ሐሙስ', 'አርብ', 'ቅዳሜ', 'እሑድ'];
      return '${weekdays[now.weekday - 1]}፣ ${months[now.month - 1]} ${now.day}፣ ${now.year}';
    } else {
      final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Consumer<BibleProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    _getFormattedDate(provider.isAmharic).toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getGreeting(provider.isAmharic),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: const Color(0xFFD4AF37),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Verse of the Day Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2A2A2A), Color(0xFF1E1E1E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.isAmharic ? 'የዕለቱ ጥቅስ' : 'VERSE OF THE DAY',
                          style: TextStyle(
                            color: const Color(0xFFD4AF37).withOpacity(0.8),
                            fontSize: 11,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          provider.isAmharic 
                              ? 'እግዚአብሔር እረኛዬ ነው፥ የሚያሳጣኝም የለም። በለመለመ መስክ ያሳድረኛል፤ በዕረፍት ውኃ ዘንድ ይመራኛል።' 
                              : 'The Lord is my shepherd; I shall not want. He maketh me to lie down in green pastures: he leadeth me beside the still waters.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            height: 1.6,
                            fontFamily: GoogleFonts.notoSansEthiopic().fontFamily,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          provider.isAmharic ? 'መዝሙር 23:1-2' : 'Psalm 23:1-2',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Continue Reading Button
                  InkWell(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.isAmharic ? 'ወደ ንባብዎ ይመለሱ' : 'Continue Reading',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                provider.selectedBook.isNotEmpty 
                                    ? '${provider.selectedBook} ${provider.selectedChapter}'
                                    : (provider.isAmharic ? 'መጽሐፍ ይምረጡ' : 'Select a book'),
                                style: TextStyle(
                                  color: const Color(0xFFD4AF37),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFFD4AF37),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
