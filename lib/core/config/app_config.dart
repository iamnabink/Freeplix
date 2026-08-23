import 'package:freeplix/core/config/stream_source.dart' show StreamSource;

/// Build-time configuration.
///
/// Values are injected with `--dart-define` (or `--dart-define-from-file=.env`)
/// so nothing secret is ever committed to the repository.
abstract final class AppConfig {
  /// TMDB v4 read access token. Preferred over the v3 key.
  static const tmdbReadToken = String.fromEnvironment(
    'TMDB_API_READ_ACCESS_TOKEN',
  );

  /// TMDB v3 API key. Used as a fallback when no read token is present.
  static const tmdbApiKey = String.fromEnvironment('TMDB_API_KEY');

  /// JSON array describing the playback sources this build ships with.
  /// Empty by default — see [StreamSource] for the shape.
  static const streamSourcesJson = String.fromEnvironment('FREEPLIX_SOURCES');

  static const tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const tmdbImageBaseUrl = 'https://image.tmdb.org/t/p';

  static bool get hasTmdbCredentials =>
      tmdbReadToken.isNotEmpty || tmdbApiKey.isNotEmpty;

  static const repositoryUrl = 'https://github.com/iamnabink/Freeplix';
  static const authorUrl = 'https://github.com/iamnabink';
  static const authorName = 'Nabraj Khadka';
  static const authorHandle = 'iamnabink';
  /// Required by TMDB's terms of use — the wording is theirs, not ours.
  static const tmdbAttribution =
      'This product uses the TMDB API but is not endorsed or certified by TMDB.';

  static const purposeNotice =
      'Freeplix is an open source project built purely for learning and '
      'education — a worked example of Flutter, BLoC and a public API.';
}
