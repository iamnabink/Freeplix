import 'dart:convert';

import 'package:freeplix/data/models/watch_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the recently opened titles on the device. No account, no server.
class WatchProgressRepository {
  WatchProgressRepository(this._prefs);

  static const _key = 'freeplix.progress.v1';

  /// Enough to fill a rail without the list growing forever.
  static const maxEntries = 20;

  final SharedPreferences _prefs;

  List<WatchProgress> load() {
    final raw = _prefs.getStringList(_key) ?? const [];
    final entries =
        raw
            .map((entry) {
              try {
                return WatchProgress.fromJson(
                  jsonDecode(entry) as Map<String, dynamic>,
                );
              } on FormatException {
                return null;
              }
            })
            .whereType<WatchProgress>()
            .toList()
          ..sort((a, b) => b.openedAt.compareTo(a.openedAt));
    return entries;
  }

  Future<void> save(List<WatchProgress> entries) {
    return _prefs.setStringList(
      _key,
      entries.take(maxEntries).map((e) => jsonEncode(e.toJson())).toList(),
    );
  }
}
