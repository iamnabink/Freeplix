import 'package:flutter_test/flutter_test.dart';
import 'package:freeplix/core/config/stream_source.dart';

void main() {
  group('StreamSource', () {
    const source = StreamSource(
      id: 'library',
      name: 'Library',
      movieTemplate: 'https://example.com/movie/{tmdbId}',
      tvTemplate: 'https://example.com/tv/{tmdbId}/{season}/{episode}',
    );

    test('fills the movie template', () {
      expect(source.movieUrl(603), 'https://example.com/movie/603');
    });

    test('fills every episode placeholder', () {
      expect(
        source.episodeUrl(1396, 2, 7),
        'https://example.com/tv/1396/2/7',
      );
    });

    test('returns null when a template is not configured', () {
      const partial = StreamSource(
        id: 'x',
        name: 'X',
        movieTemplate: '',
        tvTemplate: '',
      );
      expect(partial.movieUrl(1), isNull);
      expect(partial.episodeUrl(1, 1, 1), isNull);
    });

    test('parses from JSON', () {
      final parsed = StreamSource.fromJson(const {
        'id': 'library',
        'name': 'Library',
        'movie': 'https://example.com/movie/{tmdbId}',
        'tv': 'https://example.com/tv/{tmdbId}/{season}/{episode}',
      });
      expect(parsed, source);
    });
  });

  group('StreamSources', () {
    test('a build with no FREEPLIX_SOURCES define ships no sources', () {
      // The default build must never carry a playback source it was not
      // explicitly given.
      expect(StreamSources.all, isEmpty);
      expect(StreamSources.isEmpty, isTrue);
    });
  });
}
