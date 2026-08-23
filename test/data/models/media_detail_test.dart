import 'package:flutter_test/flutter_test.dart';
import 'package:freeplix/data/models/media_detail.dart';
import 'package:freeplix/data/models/media_type.dart';

void main() {
  group('MediaDetail', () {
    Map<String, dynamic> payload({Map<String, dynamic> extra = const {}}) => {
      'id': 603,
      'title': 'The Matrix',
      'overview': 'A hacker learns the truth.',
      'runtime': 136,
      'vote_average': 8.2,
      'release_date': '1999-03-30',
      'genres': [
        {'id': 28, 'name': 'Action'},
      ],
      'credits': {
        'cast': [
          {'id': 6384, 'name': 'Keanu Reeves', 'character': 'Neo'},
        ],
        'crew': [
          {'id': 1, 'name': 'Lana Wachowski', 'job': 'Director'},
        ],
      },
      'videos': {
        'results': [
          {
            'key': 'abc',
            'name': 'Teaser',
            'site': 'YouTube',
            'type': 'Teaser',
            'official': true,
          },
          {
            'key': 'xyz',
            'name': 'Trailer',
            'site': 'YouTube',
            'type': 'Trailer',
            'official': true,
          },
          {
            'key': 'nope',
            'name': 'Vimeo cut',
            'site': 'Vimeo',
            'type': 'Trailer',
            'official': true,
          },
        ],
      },
      ...extra,
    };

    test('parses credits, genres and videos', () {
      final detail = MediaDetail.fromJson(
        payload(),
        type: MediaType.movie,
      );

      expect(detail.title, 'The Matrix');
      expect(detail.genres.single.name, 'Action');
      expect(detail.cast.single.character, 'Neo');
      expect(detail.directors, ['Lana Wachowski']);
    });

    test('keeps only YouTube videos and prefers the official trailer', () {
      final detail = MediaDetail.fromJson(
        payload(),
        type: MediaType.movie,
      );

      expect(detail.videos, hasLength(2));
      expect(detail.trailer?.key, 'xyz');
    });

    test('formats runtime for the reader, not the API', () {
      MediaDetail withRuntime(int? minutes) => MediaDetail.fromJson(
        payload(extra: {'runtime': minutes}),
        type: MediaType.movie,
      );

      expect(withRuntime(136).runtime, '2h 16m');
      expect(withRuntime(120).runtime, '2h');
      expect(withRuntime(48).runtime, '48m');
      expect(withRuntime(0).runtime, isNull);
      expect(withRuntime(null).runtime, isNull);
    });

    test('reads the US certification for a movie', () {
      final detail = MediaDetail.fromJson(
        payload(
          extra: {
            'release_dates': {
              'results': [
                {
                  'iso_3166_1': 'GB',
                  'release_dates': [
                    {'certification': '15'},
                  ],
                },
                {
                  'iso_3166_1': 'US',
                  'release_dates': [
                    {'certification': ''},
                    {'certification': 'R'},
                  ],
                },
              ],
            },
          },
        ),
        type: MediaType.movie,
      );

      expect(detail.certification, 'R');
    });

    test('summarises seasons for a series', () {
      final detail = MediaDetail.fromJson(
        const {
          'id': 1396,
          'name': 'Breaking Bad',
          'number_of_seasons': 5,
          'episode_run_time': [47],
          'seasons': [
            {
              'id': 1,
              'season_number': 0,
              'name': 'Specials',
              'episode_count': 0,
            },
            {
              'id': 2,
              'season_number': 1,
              'name': 'Season 1',
              'episode_count': 7,
            },
          ],
        },
        type: MediaType.tv,
      );

      expect(detail.seasonSummary, '5 seasons');
      expect(detail.runtime, '47m');
      // Seasons with no episodes are dropped.
      expect(detail.seasons.single.seasonNumber, 1);
    });
  });
}
