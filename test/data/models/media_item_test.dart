import 'package:flutter_test/flutter_test.dart';
import 'package:freeplix/data/models/media_item.dart';
import 'package:freeplix/data/models/media_type.dart';

void main() {
  group('MediaItem', () {
    test('reads a movie payload', () {
      final item = MediaItem.fromJson(const {
        'id': 603,
        'media_type': 'movie',
        'title': 'The Matrix',
        'poster_path': '/poster.jpg',
        'backdrop_path': '/backdrop.jpg',
        'overview': 'A hacker learns the truth.',
        'vote_average': 8.213,
        'release_date': '1999-03-30',
        'genre_ids': [28, 878],
      });

      expect(item.id, 603);
      expect(item.type, MediaType.movie);
      expect(item.title, 'The Matrix');
      expect(item.year, '1999');
      expect(item.rating, '8.2');
      expect(item.genreIds, [28, 878]);
      expect(item.poster(), contains('/poster.jpg'));
    });

    test('infers series from first_air_date when media_type is absent', () {
      final item = MediaItem.fromJson(const {
        'id': 1396,
        'name': 'Breaking Bad',
        'first_air_date': '2008-01-20',
      });

      expect(item.type, MediaType.tv);
      expect(item.title, 'Breaking Bad');
      expect(item.year, '2008');
    });

    test('survives a payload with nothing but an id', () {
      final item = MediaItem.fromJson(const {'id': 1});

      expect(item.title, isEmpty);
      expect(item.year, '—');
      expect(item.rating, '—');
      expect(item.poster(), isNull);
    });
  });
}
