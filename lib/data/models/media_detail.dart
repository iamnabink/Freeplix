import 'package:equatable/equatable.dart';
import 'package:freeplix/data/models/credits.dart';
import 'package:freeplix/data/models/genre.dart';
import 'package:freeplix/data/models/image_size.dart';
import 'package:freeplix/data/models/media_item.dart';
import 'package:freeplix/data/models/media_type.dart';
import 'package:freeplix/data/models/season.dart';
import 'package:freeplix/data/models/video.dart';

/// Everything the detail screen needs, folded out of a single
/// `append_to_response` call.
class MediaDetail extends Equatable {
  const MediaDetail({
    required this.id,
    required this.type,
    required this.title,
    required this.overview,
    required this.genres,
    required this.cast,
    required this.crew,
    required this.videos,
    required this.similar,
    required this.seasons,
    this.tagline = '',
    this.posterPath,
    this.backdropPath,
    this.voteAverage = 0,
    this.voteCount = 0,
    this.releaseDate,
    this.runtimeMinutes,
    this.numberOfSeasons,
    this.numberOfEpisodes,
    this.status = '',
    this.homepage = '',
    this.certification = '',
  });

  factory MediaDetail.fromJson(
    Map<String, dynamic> json, {
    required MediaType type,
  }) {
    final credits = json['credits'] as Map<String, dynamic>? ?? const {};
    final videos = json['videos'] as Map<String, dynamic>? ?? const {};
    final similar =
        json['recommendations'] as Map<String, dynamic>? ??
        json['similar'] as Map<String, dynamic>? ??
        const {};
    final date =
        (json['release_date'] ?? json['first_air_date']) as String? ?? '';

    return MediaDetail(
      id: json['id'] as int,
      type: type,
      title: (json['title'] ?? json['name'] ?? '') as String,
      tagline: json['tagline'] as String? ?? '',
      overview: json['overview'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0,
      voteCount: json['vote_count'] as int? ?? 0,
      releaseDate: date.isEmpty ? null : DateTime.tryParse(date),
      runtimeMinutes:
          json['runtime'] as int? ??
          (json['episode_run_time'] as List<dynamic>?)
              ?.whereType<int>()
              .firstOrNull,
      numberOfSeasons: json['number_of_seasons'] as int?,
      numberOfEpisodes: json['number_of_episodes'] as int?,
      status: json['status'] as String? ?? '',
      homepage: json['homepage'] as String? ?? '',
      certification: _certification(json, type),
      genres:
          (json['genres'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(Genre.fromJson)
              .toList() ??
          const [],
      cast:
          (credits['cast'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(CastMember.fromJson)
              .take(20)
              .toList() ??
          const [],
      crew:
          (credits['crew'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(CrewMember.fromJson)
              .toList() ??
          const [],
      videos:
          (videos['results'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(Video.fromJson)
              .where((v) => v.isYouTube)
              .toList() ??
          const [],
      similar:
          (similar['results'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => MediaItem.fromJson(e, fallbackType: type))
              .where((e) => e.posterPath != null)
              .toList() ??
          const [],
      seasons:
          (json['seasons'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(Season.fromJson)
              .where((s) => s.episodeCount > 0)
              .toList() ??
          const [],
    );
  }

  final int id;
  final MediaType type;
  final String title;
  final String tagline;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final int voteCount;
  final DateTime? releaseDate;
  final int? runtimeMinutes;
  final int? numberOfSeasons;
  final int? numberOfEpisodes;
  final String status;
  final String homepage;
  final String certification;
  final List<Genre> genres;
  final List<CastMember> cast;
  final List<CrewMember> crew;
  final List<Video> videos;
  final List<MediaItem> similar;
  final List<Season> seasons;

  String? poster([PosterSize size = PosterSize.w500]) =>
      tmdbImage(posterPath, size.path);

  String? backdrop([BackdropSize size = BackdropSize.original]) =>
      tmdbImage(backdropPath, size.path);

  String get year => releaseDate?.year.toString() ?? '—';

  /// `Inception (2010)`, or just the title when the year is unknown. Used for
  /// the browser tab / OS task-switcher label.
  String get titleWithYear => year == '—' ? title : '$title ($year)';

  String get rating => voteAverage <= 0 ? '—' : voteAverage.toStringAsFixed(1);

  /// `2h 46m`, or `48m` for a single-hour-or-less runtime.
  String? get runtime {
    final minutes = runtimeMinutes;
    if (minutes == null || minutes <= 0) return null;
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (hours == 0) return '${rest}m';
    if (rest == 0) return '${hours}h';
    return '${hours}h ${rest}m';
  }

  String? get seasonSummary {
    final count = numberOfSeasons;
    if (count == null || count <= 0) return null;
    return count == 1 ? '1 season' : '$count seasons';
  }

  List<String> get directors => crew
      .where((c) => c.job == 'Director' || c.job == 'Series Director')
      .map((c) => c.name)
      .toSet()
      .toList();

  List<String> get writers => crew
      .where((c) => c.job == 'Writer' || c.job == 'Screenplay')
      .map((c) => c.name)
      .toSet()
      .take(3)
      .toList();

  Video? get trailer {
    final ranked = [...videos]
      ..sort((a, b) {
        int score(Video v) =>
            (v.type == 'Trailer' ? 4 : 0) +
            (v.type == 'Teaser' ? 2 : 0) +
            (v.official ? 1 : 0);
        return score(b).compareTo(score(a));
      });
    return ranked.firstOrNull;
  }

  MediaItem get asItem => MediaItem(
    id: id,
    type: type,
    title: title,
    posterPath: posterPath,
    backdropPath: backdropPath,
    overview: overview,
    voteAverage: voteAverage,
    releaseDate: releaseDate,
  );

  static String _certification(Map<String, dynamic> json, MediaType type) {
    if (type == MediaType.tv) {
      final results =
          (json['content_ratings'] as Map<String, dynamic>?)?['results']
              as List<dynamic>?;
      final match = results
          ?.whereType<Map<String, dynamic>>()
          .where((e) => e['iso_3166_1'] == 'US')
          .firstOrNull;
      return match?['rating'] as String? ?? '';
    }
    final results =
        (json['release_dates'] as Map<String, dynamic>?)?['results']
            as List<dynamic>?;
    final us = results
        ?.whereType<Map<String, dynamic>>()
        .where((e) => e['iso_3166_1'] == 'US')
        .firstOrNull;
    final dates =
        (us?['release_dates'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>() ??
        const <Map<String, dynamic>>[];
    for (final entry in dates) {
      final cert = entry['certification'] as String? ?? '';
      if (cert.isNotEmpty) return cert;
    }
    return '';
  }

  @override
  List<Object?> get props => [id, type];
}
