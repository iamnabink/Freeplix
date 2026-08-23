import 'package:flutter_test/flutter_test.dart';
import 'package:freeplix/core/config/stream_source.dart';
import 'package:freeplix/data/models/media_detail.dart';
import 'package:freeplix/data/models/media_type.dart';
import 'package:freeplix/features/watch/bloc/watch_cubit.dart';

void main() {
  const library = StreamSource(
    id: 'library',
    name: 'Library',
    movieTemplate: 'https://example.com/movie/{tmdbId}',
    tvTemplate: 'https://example.com/tv/{tmdbId}/{season}/{episode}',
  );

  MediaDetail detail({
    MediaType type = MediaType.movie,
    bool withTrailer = true,
  }) => MediaDetail.fromJson({
    'id': 603,
    if (type == MediaType.movie) 'title': 'The Matrix' else 'name': 'Series',
    'videos': {
      'results': [
        if (withTrailer)
          {
            'key': 'xyz',
            'name': 'Trailer',
            'site': 'YouTube',
            'type': 'Trailer',
            'official': true,
          },
      ],
    },
  }, type: type);

  group('WatchState playback selection', () {
    test('plays the configured source when one is available', () {
      final state = WatchState(
        detail: detail(),
        sources: const [library],
      );

      expect(state.kind, PlaybackKind.source);
      expect(state.playbackUrl, 'https://example.com/movie/603');
    });

    test('asking to watch never silently substitutes the trailer', () {
      // The regression this guards: with no source configured, "Watch" used
      // to quietly play the trailer, which reads as the feature failing to
      // start rather than as a missing configuration.
      final state = WatchState(detail: detail(), sources: const []);

      expect(state.kind, PlaybackKind.nothing);
      expect(state.playbackUrl, isNull);
      expect(state.hasNoSourceConfigured, isTrue);
      expect(state.hasTrailer, isTrue);
    });

    test('asking for the trailer plays the trailer', () {
      final state = WatchState(
        detail: detail(),
        sources: const [library],
        requestedKind: PlaybackKind.trailer,
      );

      expect(state.kind, PlaybackKind.trailer);
      expect(state.playbackUrl, contains('/embed/xyz'));
    });

    test('the trailer stays reachable while a source is configured', () {
      final watching = WatchState(detail: detail(), sources: const [library]);
      expect(watching.kind, PlaybackKind.source);
      expect(watching.hasTrailer, isTrue);
    });

    test('reports nothing when a trailer is asked for and none exists', () {
      final state = WatchState(
        detail: detail(withTrailer: false),
        sources: const [],
        requestedKind: PlaybackKind.trailer,
      );

      expect(state.kind, PlaybackKind.nothing);
      expect(state.playbackUrl, isNull);
    });

    test('a series builds a season and episode URL', () {
      final state = WatchState(
        detail: detail(type: MediaType.tv),
        sources: const [library],
        season: 2,
        episode: 7,
      );

      expect(state.playbackUrl, 'https://example.com/tv/603/2/7');
      expect(state.episodeLabel, 'S02 · E07');
    });

    test('a series defaults to the first episode', () {
      final state = WatchState(
        detail: detail(type: MediaType.tv),
        sources: const [library],
      );

      expect(state.playbackUrl, 'https://example.com/tv/603/1/1');
    });
  });
}
