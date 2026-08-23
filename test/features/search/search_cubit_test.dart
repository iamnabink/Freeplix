import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freeplix/core/network/api_exception.dart';
import 'package:freeplix/data/models/media_item.dart';
import 'package:freeplix/data/models/media_type.dart';
import 'package:freeplix/data/repositories/tmdb_repository.dart';
import 'package:freeplix/features/search/bloc/search_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _MockTmdbRepository extends Mock implements TmdbRepository {}

void main() {
  const matrix = MediaItem(
    id: 603,
    type: MediaType.movie,
    title: 'The Matrix',
  );

  late TmdbRepository repository;

  setUp(() {
    repository = _MockTmdbRepository();
  });

  group('SearchCubit', () {
    blocTest<SearchCubit, SearchState>(
      'debounces, then reports results',
      build: () {
        when(() => repository.search(any())).thenAnswer(
          (_) async => const MediaPage(items: [matrix], page: 1, totalPages: 1),
        );
        return SearchCubit(repository: repository);
      },
      act: (cubit) => cubit.query('matrix'),
      wait: const Duration(milliseconds: 500),
      expect: () => [
        const SearchState(status: SearchStatus.typing, query: 'matrix'),
        const SearchState(status: SearchStatus.loading, query: 'matrix'),
        const SearchState(
          status: SearchStatus.ready,
          query: 'matrix',
          results: [matrix],
        ),
      ],
    );

    blocTest<SearchCubit, SearchState>(
      'sends one request for a burst of keystrokes',
      build: () {
        when(() => repository.search(any())).thenAnswer(
          (_) async => const MediaPage(items: [matrix], page: 1, totalPages: 1),
        );
        return SearchCubit(repository: repository);
      },
      act: (cubit) {
        cubit
          ..query('m')
          ..query('ma')
          ..query('mat')
          ..query('matrix');
      },
      wait: const Duration(milliseconds: 500),
      verify: (_) {
        verify(() => repository.search('matrix')).called(1);
        verifyNever(() => repository.search('mat'));
      },
    );

    blocTest<SearchCubit, SearchState>(
      'clearing the field returns to idle without asking TMDB',
      build: () => SearchCubit(repository: repository),
      act: (cubit) => cubit.query('   '),
      expect: () => [const SearchState()],
      verify: (_) => verifyNever(() => repository.search(any())),
    );

    blocTest<SearchCubit, SearchState>(
      'surfaces the API message on failure',
      build: () {
        when(
          () => repository.search(any()),
        ).thenThrow(const ApiException('Too many requests.'));
        return SearchCubit(repository: repository);
      },
      act: (cubit) => cubit.query('matrix'),
      wait: const Duration(milliseconds: 500),
      expect: () => [
        const SearchState(status: SearchStatus.typing, query: 'matrix'),
        const SearchState(status: SearchStatus.loading, query: 'matrix'),
        const SearchState(
          status: SearchStatus.failure,
          query: 'matrix',
          error: 'Too many requests.',
        ),
      ],
    );
  });
}
