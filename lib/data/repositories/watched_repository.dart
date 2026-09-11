import 'dart:convert';

import 'package:freeplix/data/models/media_item.dart';
import 'package:freeplix/data/models/media_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Titles the viewer has marked as already seen. Kept on the device, like the
/// watchlist — Freeplix has no accounts and no backend.
class WatchedRepository {
  WatchedRepository(this._prefs);

  static const _key = 'freeplix.watched.v1';

  final SharedPreferences _prefs;

  List<MediaItem> load() {
    final raw = _prefs.getStringList(_key) ?? const [];
    return raw
        .map((entry) {
          try {
            final json = jsonDecode(entry) as Map<String, dynamic>;
            return MediaItem(
              id: json['id'] as int,
              type: MediaType.fromWire(json['type'] as String?),
              title: json['title'] as String? ?? '',
              posterPath: json['poster'] as String?,
              backdropPath: json['backdrop'] as String?,
              voteAverage: (json['vote'] as num?)?.toDouble() ?? 0,
              releaseDate: DateTime.tryParse(json['date'] as String? ?? ''),
            );
          } on FormatException {
            return null;
          }
        })
        .whereType<MediaItem>()
        .toList();
  }

  Future<void> save(List<MediaItem> items) {
    return _prefs.setStringList(
      _key,
      items
          .map(
            (e) => jsonEncode({
              'id': e.id,
              'type': e.type.wire,
              'title': e.title,
              'poster': e.posterPath,
              'backdrop': e.backdropPath,
              'vote': e.voteAverage,
              'date': e.releaseDate?.toIso8601String(),
            }),
          )
          .toList(),
    );
  }
}
