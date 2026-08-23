import 'package:freeplix/core/network/tmdb_client.dart';
import 'package:freeplix/data/models/genre.dart';
import 'package:freeplix/data/models/media_detail.dart';
import 'package:freeplix/data/models/media_filter.dart';
import 'package:freeplix/data/models/media_item.dart';
import 'package:freeplix/data/models/media_type.dart';
import 'package:freeplix/data/models/person_ref.dart';
import 'package:freeplix/data/models/season.dart';

/// One page of results plus enough context to ask for the next one.
class MediaPage {
  const MediaPage({
    required this.items,
    required this.page,
    required this.totalPages,
    this.totalResults = 0,
  });

  const MediaPage.empty()
    : items = const [],
      page = 0,
      totalPages = 0,
      totalResults = 0;

  final List<MediaItem> items;
  final int page;
  final int totalPages;
  final int totalResults;

  bool get hasMore => page < totalPages;
}

/// Everything Freeplix asks of TMDB.
class TmdbRepository {
  TmdbRepository({TmdbClient? client}) : _client = client ?? TmdbClient();

  final TmdbClient _client;
  final _detailCache = <String, MediaDetail>{};
  final _genreCache = <MediaType, List<Genre>>{};

  Future<MediaPage> trending({String window = 'week', int page = 1}) =>
      _page('/trending/all/$window', page: page);

  Future<MediaPage> movies(MovieFeed feed, {int page = 1}) =>
      _page('/movie/${feed.path}', page: page, fallbackType: MediaType.movie);

  Future<MediaPage> series(SeriesFeed feed, {int page = 1}) =>
      _page('/tv/${feed.path}', page: page, fallbackType: MediaType.tv);

  Future<MediaPage> search(String query, {int page = 1}) async {
    if (query.trim().isEmpty) return const MediaPage.empty();
    final result = await _page(
      '/search/multi',
      page: page,
      query: {'query': query.trim(), 'include_adult': false},
    );
    return MediaPage(
      items: result.items.where((e) => e.type != MediaType.person).toList(),
      page: result.page,
      totalPages: result.totalPages,
    );
  }

  Future<MediaPage> discover(
    MediaType type, {
    int page = 1,
    MediaFilter filter = const MediaFilter(),
  }) => _page(
    '/discover/${type.wire}',
    page: page,
    fallbackType: type,
    query: filter.toQuery(type),
  );

  /// People, for the cast filter. Ordered by how well known they are, since
  /// a name like "Chris" otherwise returns dozens of unfamiliar matches.
  Future<List<PersonRef>> searchPeople(String query) async {
    if (query.trim().isEmpty) return const [];
    final json = await _client.get(
      '/search/person',
      query: {'query': query.trim(), 'include_adult': false},
    );
    final people =
        (json['results'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(PersonRef.fromJson)
            .toList() ??
        const <PersonRef>[];
    return people..sort((a, b) => b.popularity.compareTo(a.popularity));
  }

  Future<List<Genre>> genres(MediaType type) async {
    final cached = _genreCache[type];
    if (cached != null) return cached;
    final json = await _client.get('/genre/${type.wire}/list');
    final parsed =
        (json['genres'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(Genre.fromJson)
            .toList() ??
        const <Genre>[];
    return _genreCache[type] = parsed;
  }

  Future<MediaDetail> detail(MediaType type, int id) async {
    final key = '${type.wire}/$id';
    final cached = _detailCache[key];
    if (cached != null) return cached;

    final append = type == MediaType.movie
        ? 'credits,videos,recommendations,release_dates'
        : 'credits,videos,recommendations,content_ratings';

    final json = await _client.get(
      '/${type.wire}/$id',
      query: {'append_to_response': append},
    );
    return _detailCache[key] = MediaDetail.fromJson(json, type: type);
  }

  Future<List<Episode>> episodes(int tvId, int seasonNumber) async {
    final json = await _client.get('/tv/$tvId/season/$seasonNumber');
    return (json['episodes'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(Episode.fromJson)
            .toList() ??
        const [];
  }

  Future<MediaPage> _page(
    String path, {
    required int page,
    MediaType? fallbackType,
    Map<String, dynamic>? query,
  }) async {
    final json = await _client.get(
      path,
      query: {'page': page, ...?query},
    );
    final items =
        (json['results'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map((e) => MediaItem.fromJson(e, fallbackType: fallbackType))
            .toList() ??
        const <MediaItem>[];

    return MediaPage(
      items: items,
      page: json['page'] as int? ?? page,
      totalPages: json['total_pages'] as int? ?? 1,
      totalResults: json['total_results'] as int? ?? items.length,
    );
  }
}

enum MovieFeed {
  popular('popular', 'Popular movies'),
  topRated('top_rated', 'Top rated'),
  nowPlaying('now_playing', 'In theatres now'),
  upcoming('upcoming', 'Coming soon');

  const MovieFeed(this.path, this.label);

  final String path;
  final String label;
}

enum SeriesFeed {
  popular('popular', 'Popular series'),
  topRated('top_rated', 'Top rated series'),
  airingToday('airing_today', 'Airing today'),
  onTheAir('on_the_air', 'On the air');

  const SeriesFeed(this.path, this.label);

  final String path;
  final String label;
}
