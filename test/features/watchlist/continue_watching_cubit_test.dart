import 'package:flutter_test/flutter_test.dart';
import 'package:freeplix/data/models/media_detail.dart';
import 'package:freeplix/data/models/media_type.dart';
import 'package:freeplix/data/repositories/watch_progress_repository.dart';
import 'package:freeplix/features/watchlist/bloc/continue_watching_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  MediaDetail detail(int id, String title, {MediaType type = MediaType.movie}) =>
      MediaDetail.fromJson({
        'id': id,
        if (type == MediaType.movie) 'title': title else 'name': title,
        'poster_path': '/p.jpg',
      }, type: type);

  late WatchProgressRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = WatchProgressRepository(await SharedPreferences.getInstance());
  });

  group('ContinueWatchingCubit', () {
    test('starts empty', () {
      expect(
        ContinueWatchingCubit(repository: repository).state.entries,
        isEmpty,
      );
    });

    test('records what was opened, most recent first', () async {
      final cubit = ContinueWatchingCubit(repository: repository);

      await cubit.record(detail(1, 'First'), at: DateTime(2026, 1, 1));
      await cubit.record(detail(2, 'Second'), at: DateTime(2026, 1, 2));

      expect(cubit.state.entries.map((e) => e.title), ['Second', 'First']);
    });

    test('re-opening a series moves it up rather than duplicating', () async {
      final cubit = ContinueWatchingCubit(repository: repository);
      final show = detail(1396, 'Breaking Bad', type: MediaType.tv);

      await cubit.record(show, season: 1, episode: 1, at: DateTime(2026, 1, 1));
      await cubit.record(detail(2, 'Other'), at: DateTime(2026, 1, 2));
      await cubit.record(show, season: 2, episode: 7, at: DateTime(2026, 1, 3));

      expect(cubit.state.entries, hasLength(2));
      final resumed = cubit.state.entries.first;
      expect(resumed.title, 'Breaking Bad');
      expect(resumed.season, 2);
      expect(resumed.episode, 7);
    });

    test('a series resumes at its episode; a film at its start', () async {
      final cubit = ContinueWatchingCubit(repository: repository);

      await cubit.record(
        detail(1396, 'Breaking Bad', type: MediaType.tv),
        season: 2,
        episode: 7,
      );
      await cubit.record(detail(603, 'The Matrix'));

      final film = cubit.state.entries.firstWhere((e) => e.id == 603);
      final show = cubit.state.entries.firstWhere((e) => e.id == 1396);

      expect(film.watchRoute, '/watch/movie/603');
      expect(film.episodeLabel, isNull);
      expect(show.watchRoute, '/watch/tv/1396?s=2&e=7');
      expect(show.episodeLabel, 'S02 · E07');
    });

    test('season and episode are ignored for a film', () async {
      final cubit = ContinueWatchingCubit(repository: repository);
      await cubit.record(detail(603, 'The Matrix'), season: 3, episode: 4);

      expect(cubit.state.entries.single.season, isNull);
      expect(cubit.state.entries.single.episode, isNull);
    });

    test('survives a round trip through storage', () async {
      await ContinueWatchingCubit(repository: repository).record(
        detail(1396, 'Breaking Bad', type: MediaType.tv),
        season: 3,
        episode: 2,
      );

      final reloaded = ContinueWatchingCubit(repository: repository);
      expect(reloaded.state.entries.single.episodeLabel, 'S03 · E02');
    });

    test('the list is capped so it cannot grow forever', () async {
      final cubit = ContinueWatchingCubit(repository: repository);
      for (var i = 0; i < WatchProgressRepository.maxEntries + 5; i++) {
        await cubit.record(detail(i, 'Title $i'), at: DateTime(2026, 1, 1, i));
      }

      expect(
        repository.load().length,
        WatchProgressRepository.maxEntries,
      );
    });

    test('remove drops one entry, clear drops them all', () async {
      final cubit = ContinueWatchingCubit(repository: repository);
      await cubit.record(detail(1, 'One'));
      await cubit.record(detail(2, 'Two'));

      await cubit.remove(cubit.state.entries.first);
      expect(cubit.state.entries, hasLength(1));

      await cubit.clear();
      expect(cubit.state.entries, isEmpty);
      expect(repository.load(), isEmpty);
    });
  });
}
