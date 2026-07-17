import 'package:flutter/foundation.dart';

import 'user_data_store.dart';

/// One entry in the user's prayer list.
class Prayer {
  final int id;
  final String text;
  final DateTime createdAt;
  final DateTime? answeredAt;

  const Prayer({
    required this.id,
    required this.text,
    required this.createdAt,
    this.answeredAt,
  });

  bool get isAnswered => answeredAt != null;
}

/// State for the prayer list: active requests plus a record of answered ones.
class PrayerProvider extends ChangeNotifier {
  PrayerProvider() {
    _load();
  }

  List<Prayer> _prayers = [];

  List<Prayer> get active =>
      _prayers.where((p) => !p.isAnswered).toList(growable: false);
  List<Prayer> get answered =>
      _prayers.where((p) => p.isAnswered).toList(growable: false);

  Future<void> _load() async {
    try {
      final rows = await UserDataStore.instance.loadPrayers();
      _prayers = [
        for (final r in rows)
          Prayer(
            id: r['id'] as int,
            text: r['text'] as String,
            createdAt:
                DateTime.tryParse(r['createdAt'] as String) ?? DateTime.now(),
            answeredAt: r['answeredAt'] == null
                ? null
                : DateTime.tryParse(r['answeredAt'] as String),
          ),
      ];
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading prayers: $e');
    }
  }

  Future<void> addPrayer(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    try {
      await UserDataStore.instance.insertPrayer(trimmed, DateTime.now());
      await _load();
    } catch (e) {
      debugPrint('Error adding prayer: $e');
    }
  }

  Future<void> setAnswered(int id, bool answered) async {
    try {
      await UserDataStore.instance.setPrayerAnswered(
        id,
        answered ? DateTime.now() : null,
      );
      await _load();
    } catch (e) {
      debugPrint('Error updating prayer: $e');
    }
  }

  Future<void> deletePrayer(int id) async {
    try {
      await UserDataStore.instance.deletePrayer(id);
      await _load();
    } catch (e) {
      debugPrint('Error deleting prayer: $e');
    }
  }
}
