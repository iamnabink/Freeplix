import 'package:freeplix/core/config/app_config.dart';

enum PosterSize {
  w185('w185'),
  w342('w342'),
  w500('w500'),
  original('original');

  const PosterSize(this.path);

  final String path;
}

enum BackdropSize {
  w780('w780'),
  w1280('w1280'),
  original('original');

  const BackdropSize(this.path);

  final String path;
}

String? tmdbImage(String? path, String size) {
  if (path == null || path.isEmpty) return null;
  return '${AppConfig.tmdbImageBaseUrl}/$size$path';
}
