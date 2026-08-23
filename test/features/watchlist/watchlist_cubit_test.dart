import 'package:flutter_test/flutter_test.dart';
import 'package:freeplix/data/models/media_item.dart';
import 'package:freeplix/data/models/media_type.dart';
import 'package:freeplix/data/repositories/watchlist_repository.dart';
import 'package:freeplix/features/watchlist/bloc/watchlist_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const matrix = MediaItem(
    id: 603,
    type: MediaType.movie,
    title: 'The Matrix',
    posterPath: '/poster.jpg',
  );
  const breakingBad = MediaItem(
    id: 1396,
    type: MediaType.tv,
    title: 'Breaking Bad',
  );

  late WatchlistRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = WatchlistRepository(await SharedPreferences.getInstance());
  });

  group('WatchlistCubit', () {
    test('starts empty', () {
      expect(WatchlistCubit(repository: repository).state.items, isEmpty);
    });

    test('toggle adds, then removes, the same title', () async {
      final cubit = WatchlistCubit(repository: repository);

      await cubit.toggle(matrix);
      expect(cubit.state.contains(matrix), isTrue);

      await cubit.toggle(matrix);
      expect(cubit.state.contains(matrix), isFalse);
    });

    test('newest saved title comes first', () async {
      final cubit = WatchlistCubit(repository: repository);

      await cubit.toggle(matrix);
      await cubit.toggle(breakingBad);

      expect(cubit.state.items.first, breakingBad);
    });

    test('a movie and a series with the same id stay distinct', () async {
      final cubit = WatchlistCubit(repository: repository);
      const sameIdSeries = MediaItem(
        id: 603,
        type: MediaType.tv,
        title: 'Something Else',
      );

      await cubit.toggle(matrix);
      expect(cubit.state.contains(sameIdSeries), isFalse);
    });

    test('survives a round trip through storage', () async {
      await WatchlistCubit(repository: repository).toggle(matrix);

      final reloaded = WatchlistCubit(repository: repository);
      expect(reloaded.state.contains(matrix), isTrue);
      expect(reloaded.state.items.single.title, 'The Matrix');
    });

    test('clear empties both memory and storage', () async {
      final cubit = WatchlistCubit(repository: repository);
      await cubit.toggle(matrix);
      await cubit.clear();

      expect(cubit.state.items, isEmpty);
      expect(repository.load(), isEmpty);
    });
  });
}
