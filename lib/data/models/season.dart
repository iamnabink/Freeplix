import 'package:equatable/equatable.dart';
import 'package:freeplix/data/models/image_size.dart';

class Season extends Equatable {
  const Season({
    required this.id,
    required this.seasonNumber,
    required this.name,
    required this.episodeCount,
    this.overview = '',
    this.posterPath,
    this.airDate,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    final date = json['air_date'] as String? ?? '';
    return Season(
      id: json['id'] as int? ?? 0,
      seasonNumber: json['season_number'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      episodeCount: json['episode_count'] as int? ?? 0,
      overview: json['overview'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      airDate: date.isEmpty ? null : DateTime.tryParse(date),
    );
  }

  final int id;
  final int seasonNumber;
  final String name;
  final int episodeCount;
  final String overview;
  final String? posterPath;
  final DateTime? airDate;

  String? get poster => tmdbImage(posterPath, PosterSize.w185.path);

  @override
  List<Object?> get props => [id, seasonNumber];
}

class Episode extends Equatable {
  const Episode({
    required this.id,
    required this.episodeNumber,
    required this.seasonNumber,
    required this.name,
    this.overview = '',
    this.stillPath,
    this.runtime,
    this.voteAverage = 0,
    this.airDate,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    final date = json['air_date'] as String? ?? '';
    return Episode(
      id: json['id'] as int? ?? 0,
      episodeNumber: json['episode_number'] as int? ?? 0,
      seasonNumber: json['season_number'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      overview: json['overview'] as String? ?? '',
      stillPath: json['still_path'] as String?,
      runtime: json['runtime'] as int?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0,
      airDate: date.isEmpty ? null : DateTime.tryParse(date),
    );
  }

  final int id;
  final int episodeNumber;
  final int seasonNumber;
  final String name;
  final String overview;
  final String? stillPath;
  final int? runtime;
  final double voteAverage;
  final DateTime? airDate;

  String? get still => tmdbImage(stillPath, BackdropSize.w780.path);

  bool get hasAired => airDate != null && airDate!.isBefore(DateTime.now());

  @override
  List<Object?> get props => [id, seasonNumber, episodeNumber];
}
