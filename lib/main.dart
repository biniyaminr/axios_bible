import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const BibleApp());
}

class BibleApp extends StatelessWidget {
  const BibleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BibleProvider()..loadBibles(),
      child: MaterialApp(
        title: 'Bible',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
          // 1. Injecting the Noto Sans Ethiopic font here for Light Mode!
          fontFamily: GoogleFonts.notoSansEthiopic().fontFamily,
          scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          // 2. And injecting it here for Dark Mode!
          fontFamily: GoogleFonts.notoSansEthiopic().fontFamily,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

/// State management for Bible data and user selections
class BibleProvider extends ChangeNotifier {
  Map<String, dynamic> _amharicBible = {};
  Map<String, dynamic> _englishBible = {};
  bool _isAmharic = true;
  String _selectedBook = '';
  int _selectedChapter = 1;
  bool _isLoading = true;
  String? _error;

  // Getters
  bool get isAmharic => _isAmharic;
  bool get isEnglish => !_isAmharic;
  String get currentLanguage => _isAmharic ? 'Amharic' : 'English';
  String get selectedBook => _selectedBook;
  int get selectedChapter => _selectedChapter;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get books => _amharicBible.keys.toList();

  /// Loads both Bible JSON files asynchronously
  Future<void> loadBibles() async {
    try {
      // 1. Load the raw JSON strings
      final amharicString = await rootBundle.loadString('assets/bible_data/amharic_bible.json');
      final englishString = await rootBundle.loadString('assets/bible_data/english_kjv_bible.json');

      // 2. Decode the strings into Maps
      final amharicRaw = json.decode(amharicString);
      final englishRaw = json.decode(englishString);

      // 3. Transform the data to strip wrappers and format it perfectly for the UI
      _amharicBible = _transformBibleData(amharicRaw);
      _englishBible = _transformBibleData(englishRaw);

      // 4. Set default book if available
      if (_amharicBible.isNotEmpty) {
        _selectedBook = _amharicBible.keys.first;
        _selectedChapter = 1;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print("Error loading Bible data: $e");
      _isLoading = false;
      notifyListeners();
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

  /// Toggle between Amharic and English
 void toggleLanguage() {
    if (_amharicBible.isEmpty || _englishBible.isEmpty) return;

    // 1. Figure out which book index we are currently on (e.g., Book #1, Book #2)
    final currentBibleMap = _isAmharic ? _amharicBible : _englishBible;
    final currentBookKeys = currentBibleMap.keys.toList();
    final bookIndex = currentBookKeys.indexOf(_selectedBook);

    // 2. Flip the language switch
    _isAmharic = !_isAmharic;

    // 3. Grab the translated name of the book using that same index
    if (bookIndex != -1) {
      final newBibleMap = _isAmharic ? _amharicBible : _englishBible;
      final newBookKeys = newBibleMap.keys.toList();
      
      if (bookIndex < newBookKeys.length) {
        _selectedBook = newBookKeys[bookIndex];
      } else {
        _selectedBook = newBookKeys.first; // Safety fallback
      }
    }

    // 4. Update the screen!
    notifyListeners();
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

  /// Get the currently selected Bible based on language
  Map<String, dynamic> get currentBible => _isAmharic ? _amharicBible : _englishBible;

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

/// Main home screen with drawer navigation
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BibleProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: _buildTitle(context, provider),
            actions: [
              _buildLanguageToggle(context, provider),
              const SizedBox(width: 8),
            ],
          ),
          drawer: _buildDrawer(context, provider),
          body: _buildBody(context, provider),
        );
      },
    );
  }

  /// Builds the AppBar title showing current book and chapter
  Widget _buildTitle(BuildContext context, BibleProvider provider) {
    // We wrap it in a Builder to get the correct context for the Scaffold!
    return Builder(
      builder: (BuildContext innerContext) {
        return InkWell(
          onTap: () => Scaffold.of(innerContext).openDrawer(),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    '${provider.selectedBook} ${provider.selectedChapter}',
                    style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Language toggle button in AppBar
  Widget _buildLanguageToggle(BuildContext context, BibleProvider provider) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextButton.icon(
        onPressed: provider.toggleLanguage,
        icon: Icon(
          Icons.language,
          size: 18,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        label: Text(
          provider.isAmharic ? 'EN' : 'AM',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Navigation drawer with book and chapter selection
  Widget _buildDrawer(BuildContext context, BibleProvider provider) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _buildDrawerHeader(context, provider),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildBooksList(context, provider),
            ),
          ],
        ),
      ),
    );
  }

  /// Drawer header showing current selection and language
  Widget _buildDrawerHeader(BuildContext context, BibleProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Passage',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.book,
                size: 16,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  provider.selectedBook,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.language,
                size: 16,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 4),
              Text(
                provider.currentLanguage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// List of books with expandable chapters
  Widget _buildBooksList(BuildContext context, BibleProvider provider) {
    final books = provider.currentBible.keys.toList();

    // The 'return' keyword right here is what the compiler was begging for!
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        final isSelected = provider.selectedBook == book;
        
        final bookData = provider.currentBible[book];
        List<int> chapters = [];
        if (bookData is Map) {
          chapters = bookData.keys
              .map((k) => int.tryParse(k.toString()) ?? 1)
              .toList()
            ..sort();
        }

        return ExpansionTile(
          key: PageStorageKey(book), 
          leading: Icon(
            Icons.book_outlined,
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
          ),
          title: Text(
            book,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
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
        );
      },
    );
  }

  /// Builds chapter buttons for each book
  List<Widget> _buildChapters(BuildContext context, BibleProvider provider, String book) {
    final bookData = provider.currentBible[book];
    if (bookData == null) return [];

    final chapters = bookData.keys.where((k) => int.tryParse(k) != null).toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chapters.map((chapterNum) {
            final chapter = int.parse(chapterNum);
            final isSelected = book == provider.selectedBook && 
                              chapter == provider.selectedChapter;
            
            return SizedBox(
              width: 48,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  provider.selectBook(book);
                  provider.selectChapter(chapter);
                  Navigator.pop(context); // Close drawer
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: isSelected 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  foregroundColor: isSelected 
                      ? Theme.of(context).colorScheme.onPrimary 
                      : Theme.of(context).colorScheme.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '$chapter',
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      const Divider(),
    ];
  }

  /// Main body showing verses
  Widget _buildBody(BuildContext context, BibleProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading Bible...'),
          ],
        ),
      );
    }

    if (provider.selectedBook.isEmpty) {
      return const Center(
        child: Text('Please select a book'),
      );
    }

    final verses = provider.verses;
    if (verses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No verses found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return _buildVerseList(context, provider, verses);
  }

  /// List of verses with verse numbers
  Widget _buildVerseList(
    BuildContext context, 
    BibleProvider provider, 
    Map<String, String> verses,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: verses.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildChapterHeader(context, provider);
        }

        final verseNum = verses.keys.elementAt(index - 1);
        final verseText = verses[verseNum]!;

        return _buildVerseCard(context, verseNum, verseText, provider);
      },
    );
  }

  /// Chapter header with navigation
  Widget _buildChapterHeader(BuildContext context, BibleProvider provider) {
    final chapters = provider.chapters;
    final currentChapter = provider.selectedChapter;
    final hasPrev = currentChapter > 1;
    final hasNext = currentChapter < chapters.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: hasPrev 
                ? () => provider.selectChapter(currentChapter - 1) 
                : null,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous Chapter',
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Chapter $currentChapter',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: hasNext 
                ? () => provider.selectChapter(currentChapter + 1) 
                : null,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next Chapter',
          ),
        ],
      ),
    );
  }

  /// Individual verse card
  Widget _buildVerseCard(
    BuildContext context, 
    String verseNum, 
    String verseText,
    BibleProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verse number
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              verseNum,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Verse text
          Expanded(
            child: Text(
              verseText,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.6,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}