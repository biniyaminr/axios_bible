import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite-backed storage for everything the user creates in the app:
/// journal notes, highlights, bookmarks, and reading progress.
///
/// Replaces the old persistence spread across SharedPreferences
/// ('journal_notes', 'read_chapters') and loose JSON files
/// (highlights.json, bookmarks.json); [_migrateLegacyData] imports those
/// once on first launch and then deletes them.
class UserDataStore {
  UserDataStore._();
  static final UserDataStore instance = UserDataStore._();

  // Cache the future (not the Database) so concurrent first accesses share
  // a single open/migration pass instead of racing.
  Future<Database>? _openFuture;

  Future<Database> get database => _openFuture ??= _open();

  /// Closes and deletes the database. Used by tests to start from a clean
  /// slate; the next [database] access re-creates it (and re-runs the
  /// legacy migration).
  @visibleForTesting
  Future<void> reset() async {
    final pending = _openFuture;
    if (pending != null) {
      try {
        final db = await pending;
        await db.close();
      } catch (_) {
        // Already closed or failed to open — nothing to clean up.
      }
    }
    await deleteDatabase(p.join(await getDatabasesPath(), 'user_data.db'));
    _openFuture = null;
  }

  Future<Database> _open() async {
    final db = await openDatabase(
      p.join(await getDatabasesPath(), 'user_data.db'),
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            reference TEXT NOT NULL,
            text TEXT NOT NULL DEFAULT '',
            user_note TEXT NOT NULL,
            category TEXT NOT NULL DEFAULT 'Personal',
            timestamp TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE highlights(
            verse_key TEXT PRIMARY KEY,
            color INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE bookmarks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            book TEXT NOT NULL,
            chapter INTEGER NOT NULL,
            verse_num TEXT NOT NULL,
            text TEXT NOT NULL DEFAULT ''
          )
        ''');
        await db.execute('''
          CREATE TABLE read_chapters(
            chapter_key TEXT PRIMARY KEY
          )
        ''');
        await _createPlanTables(db);
        await _createPrayerTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createPlanTables(db);
        }
        if (oldVersion < 3) {
          await _createPrayerTable(db);
        }
      },
    );
    await _migrateLegacyData(db);
    return db;
  }

  static Future<void> _createPlanTables(Database db) async {
    await db.execute('''
      CREATE TABLE started_plans(
        plan_id TEXT PRIMARY KEY,
        started_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE plan_progress(
        plan_id TEXT NOT NULL,
        day INTEGER NOT NULL,
        completed_at TEXT NOT NULL,
        PRIMARY KEY(plan_id, day)
      )
    ''');
  }

  static Future<void> _createPrayerTable(Database db) async {
    await db.execute('''
      CREATE TABLE prayers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        created_at TEXT NOT NULL,
        answered_at TEXT
      )
    ''');
  }

  Future<void> _migrateLegacyData(Database db) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('sqlite_migrated_v1') == true) return;

      // Journal notes lived in prefs as one JSON string.
      final notesString = prefs.getString('journal_notes');
      if (notesString != null) {
        final List<dynamic> decoded = json.decode(notesString);
        final batch = db.batch();
        // Old list was newest-first; insert oldest-first so autoincrement
        // ids preserve chronology.
        for (final note in decoded.reversed) {
          batch.insert('notes', {
            'reference': note['reference']?.toString() ?? '',
            'text': note['text']?.toString() ?? '',
            'user_note': note['userNote']?.toString() ?? '',
            'category': note['category']?.toString() ?? 'Personal',
            'timestamp':
                note['timestamp']?.toString() ??
                DateTime.now().toIso8601String(),
          });
        }
        await batch.commit(noResult: true);
        await prefs.remove('journal_notes');
      }

      // Reading progress lived in prefs as a string list.
      final readChapters = prefs.getStringList('read_chapters');
      if (readChapters != null) {
        final batch = db.batch();
        for (final key in readChapters) {
          batch.insert('read_chapters', {
            'chapter_key': key,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        await batch.commit(noResult: true);
        await prefs.remove('read_chapters');
      }

      // Highlights and bookmarks lived in JSON files in the documents dir.
      try {
        final dir = await getApplicationDocumentsDirectory();
        final highlightsFile = File(p.join(dir.path, 'highlights.json'));
        if (await highlightsFile.exists()) {
          final Map<String, dynamic> decoded = json.decode(
            await highlightsFile.readAsString(),
          );
          final batch = db.batch();
          decoded.forEach((key, value) {
            batch.insert('highlights', {
              'verse_key': key,
              'color': value,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          });
          await batch.commit(noResult: true);
          await highlightsFile.delete();
        }

        final bookmarksFile = File(p.join(dir.path, 'bookmarks.json'));
        if (await bookmarksFile.exists()) {
          final List<dynamic> decoded = json.decode(
            await bookmarksFile.readAsString(),
          );
          final batch = db.batch();
          for (final b in decoded) {
            batch.insert('bookmarks', {
              'book': b['book']?.toString() ?? '',
              'chapter': int.tryParse(b['chapter'].toString()) ?? 1,
              'verse_num': b['verseNum']?.toString() ?? '',
              'text': b['text']?.toString() ?? '',
            });
          }
          await batch.commit(noResult: true);
          await bookmarksFile.delete();
        }
      } catch (e) {
        // Documents dir may be unavailable (e.g. tests); prefs data has
        // already been imported, so continue.
        debugPrint('Legacy file migration skipped: $e');
      }

      await prefs.setBool('sqlite_migrated_v1', true);
    } catch (e) {
      debugPrint('Error migrating legacy user data: $e');
    }
  }

  // --- Journal notes ---

  /// Newest first. Each map carries its DB 'id'.
  Future<List<Map<String, dynamic>>> loadNotes() async {
    final db = await database;
    final rows = await db.query('notes', orderBy: 'id DESC');
    return rows
        .map(
          (r) => {
            'id': r['id'],
            'reference': r['reference'],
            'text': r['text'],
            'userNote': r['user_note'],
            'category': r['category'],
            'timestamp': r['timestamp'],
          },
        )
        .toList();
  }

  /// Returns the inserted note's id.
  Future<int> insertNote(Map<String, dynamic> note) async {
    final db = await database;
    return db.insert('notes', {
      'reference': note['reference'],
      'text': note['text'],
      'user_note': note['userNote'],
      'category': note['category'],
      'timestamp': note['timestamp'],
    });
  }

  Future<void> deleteNote(int id) async {
    final db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // --- Highlights ---

  Future<Map<String, int>> loadHighlights() async {
    final db = await database;
    final rows = await db.query('highlights');
    return {for (final r in rows) r['verse_key'] as String: r['color'] as int};
  }

  Future<void> setHighlight(String verseKey, int color) async {
    final db = await database;
    await db.insert('highlights', {
      'verse_key': verseKey,
      'color': color,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeHighlight(String verseKey) async {
    final db = await database;
    await db.delete(
      'highlights',
      where: 'verse_key = ?',
      whereArgs: [verseKey],
    );
  }

  // --- Bookmarks ---

  /// Each map carries its DB 'id'.
  Future<List<Map<String, dynamic>>> loadBookmarks() async {
    final db = await database;
    final rows = await db.query('bookmarks', orderBy: 'id ASC');
    return rows
        .map(
          (r) => {
            'id': r['id'],
            'book': r['book'],
            'chapter': r['chapter'],
            'verseNum': r['verse_num'],
            'text': r['text'],
          },
        )
        .toList();
  }

  /// Returns the inserted bookmark's id.
  Future<int> insertBookmark(Map<String, dynamic> bookmark) async {
    final db = await database;
    return db.insert('bookmarks', {
      'book': bookmark['book'],
      'chapter': bookmark['chapter'],
      'verse_num': bookmark['verseNum'],
      'text': bookmark['text'],
    });
  }

  Future<void> deleteBookmark(int id) async {
    final db = await database;
    await db.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
  }

  // --- Reading plans ---

  Future<Map<String, DateTime>> loadStartedPlans() async {
    final db = await database;
    final rows = await db.query('started_plans');
    return {
      for (final r in rows)
        r['plan_id'] as String:
            DateTime.tryParse(r['started_at'] as String) ?? DateTime.now(),
    };
  }

  Future<void> startPlan(String planId, DateTime startedAt) async {
    final db = await database;
    await db.insert('started_plans', {
      'plan_id': planId,
      'started_at': startedAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// plan id -> set of completed day indexes.
  Future<Map<String, Set<int>>> loadPlanProgress() async {
    final db = await database;
    final rows = await db.query('plan_progress');
    final result = <String, Set<int>>{};
    for (final r in rows) {
      result
          .putIfAbsent(r['plan_id'] as String, () => <int>{})
          .add(r['day'] as int);
    }
    return result;
  }

  Future<void> setPlanDay(String planId, int day, bool completed) async {
    final db = await database;
    if (completed) {
      await db.insert('plan_progress', {
        'plan_id': planId,
        'day': day,
        'completed_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.delete(
        'plan_progress',
        where: 'plan_id = ? AND day = ?',
        whereArgs: [planId, day],
      );
    }
  }

  /// Timestamps of every completed plan day, for streak calculation.
  Future<List<DateTime>> loadPlanCompletionDates() async {
    final db = await database;
    final rows = await db.query('plan_progress', columns: ['completed_at']);
    return [
      for (final r in rows) ?DateTime.tryParse(r['completed_at'] as String),
    ];
  }

  // --- Prayer list ---

  /// Newest first. Each map carries its DB 'id'; 'answeredAt' is null while
  /// the prayer is still active.
  Future<List<Map<String, dynamic>>> loadPrayers() async {
    final db = await database;
    final rows = await db.query('prayers', orderBy: 'id DESC');
    return rows
        .map(
          (r) => {
            'id': r['id'],
            'text': r['text'],
            'createdAt': r['created_at'],
            'answeredAt': r['answered_at'],
          },
        )
        .toList();
  }

  /// Returns the inserted prayer's id.
  Future<int> insertPrayer(String text, DateTime createdAt) async {
    final db = await database;
    return db.insert('prayers', {
      'text': text,
      'created_at': createdAt.toIso8601String(),
    });
  }

  /// Pass null to move an answered prayer back to the active list.
  Future<void> setPrayerAnswered(int id, DateTime? answeredAt) async {
    final db = await database;
    await db.update(
      'prayers',
      {'answered_at': answeredAt?.toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletePrayer(int id) async {
    final db = await database;
    await db.delete('prayers', where: 'id = ?', whereArgs: [id]);
  }

  // --- Reading progress ---

  Future<Set<String>> loadReadChapters() async {
    final db = await database;
    final rows = await db.query('read_chapters');
    return rows.map((r) => r['chapter_key'] as String).toSet();
  }

  Future<void> addReadChapter(String chapterKey) async {
    final db = await database;
    await db.insert('read_chapters', {
      'chapter_key': chapterKey,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}
