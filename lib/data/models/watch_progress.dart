import 'package:equatable/equatable.dart';
import 'package:freeplix/data/models/media_item.dart';
import 'package:freeplix/data/models/media_type.dart';

/// A title the reader opened in the player, so Freeplix can offer it back.
///
/// The embedded player runs cross-origin, so its playback position is not
/// readable from here. What is honestly known is *what* was opened and
/// *when* — for a series, down to the episode. That is what this records,
/// and the UI says "jump back in" rather than claiming a percentage.
class WatchProgress extends Equatable {
  const WatchProgress({
    required this.id,
    required this.type,
    required this.title,
    required this.openedAt,
    this.posterPath,
    this.backdropPath,
    this.season,
    this.episode,
  });

  factory WatchProgress.fromJson(Map<String, dynamic> json) => WatchProgress(
    id: json['id'] as int,
    type: MediaType.fromWire(json['type'] as String?),
    title: json['title'] as String? ?? '',
    openedAt:
        DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime(2000),
    posterPath: json['poster'] as String?,
    backdropPath: json['backdrop'] as String?,
    season: json['s'] as int?,
    episode: json['e'] as int?,
  );

  final int id;
  final MediaType type;
  final String title;
  final DateTime openedAt;
  final String? posterPath;
  final String? backdropPath;
  final int? season;
  final int? episode;

  String get key => '${type.wire}/$id';

  /// `S02 · E07`, or null for a film.
  String? get episodeLabel {
    if (season == null || episode == null) return null;
    return 'S${season.toString().padLeft(2, '0')} · '
        'E${episode.toString().padLeft(2, '0')}';
  }

  /// Where the resume action should go.
  String get watchRoute {
    if (type == MediaType.tv && season != null && episode != null) {
      return '/watch/${type.wire}/$id?s=$season&e=$episode';
    }
    return '/watch/${type.wire}/$id';
  }

  MediaItem get asItem => MediaItem(
    id: id,
    type: type,
    title: title,
    posterPath: posterPath,
    backdropPath: backdropPath,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.wire,
    'title': title,
    'at': openedAt.toIso8601String(),
    'poster': posterPath,
    'backdrop': backdropPath,
    's': season,
    'e': episode,
  };

  @override
  List<Object?> get props => [id, type, season, episode, openedAt];
}
