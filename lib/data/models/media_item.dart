import 'package:equatable/equatable.dart';
import 'package:freeplix/data/models/image_size.dart';
import 'package:freeplix/data/models/media_type.dart';

/// One title as it appears in a row, a grid, or a search result.
class MediaItem extends Equatable {
  const MediaItem({
    required this.id,
    required this.type,
    required this.title,
    this.posterPath,
    this.backdropPath,
    this.overview = '',
    this.voteAverage = 0,
    this.releaseDate,
    this.genreIds = const [],
  });

  factory MediaItem.fromJson(
    Map<String, dynamic> json, {
    MediaType? fallbackType,
  }) {
    final type = json['media_type'] != null
        ? MediaType.fromWire(json['media_type'] as String?)
        : (fallbackType ??
              (json['first_air_date'] != null
                  ? MediaType.tv
                  : MediaType.movie));

    final date =
        (json['release_date'] ?? json['first_air_date']) as String? ?? '';

    return MediaItem(
      id: json['id'] as int,
      type: type,
      title:
          (json['title'] ?? json['name'] ?? json['original_title'] ?? '')
              as String,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      overview: json['overview'] as String? ?? '',
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0,
      releaseDate: date.isEmpty ? null : DateTime.tryParse(date),
      genreIds:
          (json['genre_ids'] as List<dynamic>?)?.whereType<int>().toList() ??
          const [],
    );
  }

  final int id;
  final MediaType type;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final String overview;
  final double voteAverage;
  final DateTime? releaseDate;
  final List<int> genreIds;

  String? poster([PosterSize size = PosterSize.w342]) =>
      tmdbImage(posterPath, size.path);

  String? backdrop([BackdropSize size = BackdropSize.w1280]) =>
      tmdbImage(backdropPath, size.path);

  String get year => releaseDate?.year.toString() ?? '—';

  String get rating => voteAverage <= 0 ? '—' : voteAverage.toStringAsFixed(1);

  @override
  List<Object?> get props => [id, type];
}
