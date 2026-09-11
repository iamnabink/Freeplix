import 'package:flutter_test/flutter_test.dart';
import 'package:freeplix/data/models/media_item.dart';
import 'package:freeplix/data/models/media_type.dart';
import 'package:freeplix/data/repositories/watched_repository.dart';
import 'package:freeplix/features/watchlist/bloc/watched_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const matrix = MediaItem(
    id: 603,
    type: MediaType.movie,
    title: 'The Matrix',
    posterPath: '/poster.jpg',
  );

  late WatchedRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = WatchedRepository(await SharedPreferences.getInstance());
  });

  group('WatchedCubit', () {
    test('starts empty', () {
      expect(WatchedCubit(repository: repository).state.items, isEmpty);
    });

    test('toggle marks, then unmarks, a title as watched', () async {
      final cubit = WatchedCubit(repository: repository);

      await cubit.toggle(matrix);
      expect(cubit.state.contains(matrix), isTrue);

      await cubit.toggle(matrix);
      expect(cubit.state.contains(matrix), isFalse);
    });

    test('survives a round trip through storage', () async {
      await WatchedCubit(repository: repository).toggle(matrix);

      final reloaded = WatchedCubit(repository: repository);
      expect(reloaded.state.contains(matrix), isTrue);
    });

    test('a movie and a series with the same id stay distinct', () async {
      final cubit = WatchedCubit(repository: repository);
      const sameIdSeries = MediaItem(
        id: 603,
        type: MediaType.tv,
        title: 'Something Else',
      );

      await cubit.toggle(matrix);
      expect(cubit.state.contains(sameIdSeries), isFalse);
    });
  });
}
