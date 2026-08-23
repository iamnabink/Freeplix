import 'package:flutter_test/flutter_test.dart';
import 'package:freeplix/data/models/media_filter.dart';
import 'package:freeplix/data/models/media_type.dart';

void main() {
  group('MediaFilter query', () {
    test('an empty filter still pins sort and an adult exclusion', () {
      final query = const MediaFilter().toQuery(MediaType.movie);

      expect(query['sort_by'], 'popularity.desc');
      expect(query['include_adult'], false);
      expect(query.containsKey('with_genres'), isFalse);
      expect(query.containsKey('with_original_language'), isFalse);
    });

    test('multiple genres are sent as a comma list', () {
      final query = const MediaFilter(
        genreIds: {28, 878},
      ).toQuery(MediaType.movie);

      expect(query['with_genres'], anyOf('28,878', '878,28'));
    });

    test('language and country map to the TMDB parameter names', () {
      final query = const MediaFilter(
        language: 'hi',
        country: 'IN',
      ).toQuery(MediaType.movie);

      expect(query['with_original_language'], 'hi');
      expect(query['with_origin_country'], 'IN');
    });

    test('a decade becomes a date range on the right field per type', () {
      const filter = MediaFilter(yearFrom: 1990, yearTo: 1999);

      final movie = filter.toQuery(MediaType.movie);
      expect(movie['primary_release_date.gte'], '1990-01-01');
      expect(movie['primary_release_date.lte'], '1999-12-31');

      final tv = filter.toQuery(MediaType.tv);
      expect(tv['first_air_date.gte'], '1990-01-01');
      expect(tv['first_air_date.lte'], '1999-12-31');
    });

    test('sorting by rating raises the vote floor', () {
      // Without this, a title with one 10/10 vote outranks everything.
      final byRating = const MediaFilter(
        sort: SortOption.rated,
      ).toQuery(MediaType.movie);
      final byPopularity = const MediaFilter().toQuery(MediaType.movie);

      expect(byRating['vote_count.gte'], 200);
      expect(byPopularity['vote_count.gte'], 50);
    });
  });

  group('SortOption', () {
    test('uses the series date field for series', () {
      expect(
        SortOption.newest.wireFor(MediaType.tv),
        'first_air_date.desc',
      );
      expect(
        SortOption.newest.wireFor(MediaType.movie),
        'primary_release_date.desc',
      );
    });

    test('revenue ordering is hidden for series, which have none', () {
      expect(SortOption.revenue.availableFor(MediaType.tv), isFalse);
      expect(SortOption.revenue.availableFor(MediaType.movie), isTrue);
    });
  });

  group('MediaFilter state', () {
    test('counts each active narrowing once', () {
      const filter = MediaFilter(
        genreIds: {28, 878},
        language: 'hi',
        minRating: 7,
        yearFrom: 1990,
        yearTo: 1999,
      );
      // two genres + language + rating + one date range
      expect(filter.activeCount, 5);
    });

    test('recognises an industry preset from its language and country', () {
      const bollywood = MediaFilter(language: 'hi', country: 'IN');
      expect(bollywood.matchingIndustry, 'Bollywood');

      const justHindi = MediaFilter(language: 'hi');
      expect(justHindi.matchingIndustry, isNull);
    });

    test('clearing keeps the sort but drops every narrowing', () {
      const filter = MediaFilter(
        genreIds: {28},
        language: 'ko',
        sort: SortOption.rated,
      );
      final cleared = filter.cleared();

      expect(cleared.isEmpty, isTrue);
      expect(cleared.sort, SortOption.rated);
    });

    test('copyWith can set a field back to null', () {
      const filter = MediaFilter(language: 'hi');
      expect(filter.copyWith(language: () => null).language, isNull);
      // Omitting the field leaves it untouched.
      expect(filter.copyWith().language, 'hi');
    });
  });
}
