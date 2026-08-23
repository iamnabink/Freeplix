import 'package:flutter_test/flutter_test.dart';
import 'package:freeplix/data/models/discovery_refs.dart';
import 'package:freeplix/data/models/media_filter.dart';
import 'package:freeplix/data/models/media_type.dart';
import 'package:freeplix/data/models/person_ref.dart';

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

  group('MediaFilter discovery query', () {
    test('keywords and studios travel as comma lists', () {
      final query = MediaFilter(
        keywords: {
          const KeywordRef(id: 4379, name: 'time travel'),
          const KeywordRef(id: 10051, name: 'heist'),
        },
        companies: {const CompanyRef(id: 10342, name: 'Studio Ghibli')},
      ).toQuery(MediaType.movie);

      expect(query['with_keywords'], anyOf('4379,10051', '10051,4379'));
      expect(query['with_companies'], '10342');
    });

    test('a streaming service is only meaningful with its region', () {
      final query = const MediaFilter(
        provider: WatchProviderRef(id: 8, name: 'Netflix'),
        watchRegion: 'IN',
      ).toQuery(MediaType.movie);

      expect(query['with_watch_providers'], 8);
      expect(query['watch_region'], 'IN');
    });

    test('no region is sent when no service is chosen', () {
      final query = const MediaFilter(watchRegion: 'IN').toQuery(
        MediaType.movie,
      );
      expect(query.containsKey('watch_region'), isFalse);
    });

    test('runtime is an upper bound', () {
      final query = const MediaFilter(runtimeMax: 90).toQuery(MediaType.movie);
      expect(query['with_runtime.lte'], 90);
    });

    test('cast is sent for films but withheld for series', () {
      final filter = MediaFilter(
        cast: {const PersonRef(id: 6384, name: 'Keanu Reeves')},
      );

      expect(filter.toQuery(MediaType.movie)['with_cast'], '6384');
      // TMDB ignores with_cast on /discover/tv, returning the unfiltered set,
      // so sending it would quietly promise filtering that never happens.
      expect(filter.toQuery(MediaType.tv).containsKey('with_cast'), isFalse);
    });

    test('clearing keeps the region but drops the service', () {
      final filter = MediaFilter(
        provider: const WatchProviderRef(id: 8, name: 'Netflix'),
        watchRegion: 'IN',
        keywords: {const KeywordRef(id: 4379, name: 'time travel')},
      );
      final cleared = filter.cleared();

      expect(cleared.isEmpty, isTrue);
      expect(cleared.provider, isNull);
      expect(cleared.watchRegion, 'IN');
    });

    test('every narrowing counts toward the badge', () {
      final filter = MediaFilter(
        keywords: {const KeywordRef(id: 4379, name: 'time travel')},
        companies: {const CompanyRef(id: 3, name: 'Pixar')},
        provider: const WatchProviderRef(id: 8, name: 'Netflix'),
        runtimeMax: 90,
      );
      expect(filter.activeCount, 4);
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
