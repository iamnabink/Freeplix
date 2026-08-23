import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:freeplix/core/config/app_config.dart';

/// A playback source Freeplix can hand a title off to.
///
/// Freeplix ships with **no** sources configured. The catalogue, artwork and
/// metadata all come from TMDB; where the actual video comes from is a
/// deployment decision, so operators supply their own licensed or
/// self-hosted endpoints at build time via `FREEPLIX_SOURCES`:
///
/// ```json
/// [
///   {
///     "id": "my-library",
///     "name": "My Library",
///     "movie": "https://example.com/embed/movie/{tmdbId}",
///     "tv": "https://example.com/embed/tv/{tmdbId}/{season}/{episode}"
///   }
/// ]
/// ```
///
/// With no sources configured the watch screen plays the official TMDB
/// trailer instead, which is what a clean checkout does out of the box.
class StreamSource extends Equatable {
  const StreamSource({
    required this.id,
    required this.name,
    required this.movieTemplate,
    required this.tvTemplate,
  });

  factory StreamSource.fromJson(Map<String, dynamic> json) {
    return StreamSource(
      id: json['id'] as String,
      name: json['name'] as String,
      movieTemplate: json['movie'] as String? ?? '',
      tvTemplate: json['tv'] as String? ?? '',
    );
  }

  final String id;
  final String name;
  final String movieTemplate;
  final String tvTemplate;

  String? movieUrl(int tmdbId) {
    if (movieTemplate.isEmpty) return null;
    return movieTemplate.replaceAll('{tmdbId}', '$tmdbId');
  }

  String? episodeUrl(int tmdbId, int season, int episode) {
    if (tvTemplate.isEmpty) return null;
    return tvTemplate
        .replaceAll('{tmdbId}', '$tmdbId')
        .replaceAll('{season}', '$season')
        .replaceAll('{episode}', '$episode');
  }

  @override
  List<Object?> get props => [id, name, movieTemplate, tvTemplate];
}

/// Parses the `FREEPLIX_SOURCES` define once, at first use.
abstract final class StreamSources {
  static List<StreamSource>? _cache;

  static List<StreamSource> get all => _cache ??= _parse();

  static bool get isEmpty => all.isEmpty;

  static List<StreamSource> _parse() {
    final raw = AppConfig.streamSourcesJson.trim();
    if (raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(StreamSource.fromJson)
          .toList();
    } on FormatException {
      return const [];
    }
  }
}
