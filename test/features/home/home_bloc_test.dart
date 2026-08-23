import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freeplix/core/network/api_exception.dart';
import 'package:freeplix/data/models/media_item.dart';
import 'package:freeplix/data/models/media_type.dart';
import 'package:freeplix/data/repositories/tmdb_repository.dart';
import 'package:freeplix/features/home/bloc/home_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockTmdbRepository extends Mock implements TmdbRepository {}

void main() {
  MediaItem item(int id, {String? backdrop, String overview = 'Synopsis.'}) =>
      MediaItem(
        id: id,
        type: MediaType.movie,
        title: 'Title $id',
        backdropPath: backdrop,
        overview: overview,
      );

  late TmdbRepository repository;

  setUpAll(() {
    registerFallbackValue(MovieFeed.popular);
    registerFallbackValue(SeriesFeed.popular);
  });

  setUp(() {
    repository = _MockTmdbRepository();
  });

  void stubAll(List<MediaItem> trending) {
    when(
      () => repository.trending(page: any(named: 'page')),
    ).thenAnswer(
      (_) async => MediaPage(items: trending, page: 1, totalPages: 1),
    );
    when(
      () => repository.movies(any(), page: any(named: 'page')),
    ).thenAnswer(
      (_) async => MediaPage(items: [item(10)], page: 1, totalPages: 1),
    );
    when(
      () => repository.series(any(), page: any(named: 'page')),
    ).thenAnswer(
      (_) async => MediaPage(items: [item(20)], page: 1, totalPages: 1),
    );
  }

  group('HomeBloc', () {
    blocTest<HomeBloc, HomeState>(
      'builds every rail and picks a spotlight',
      build: () {
        stubAll([item(1, backdrop: '/a.jpg'), item(2, backdrop: '/b.jpg')]);
        return HomeBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const HomeRequested()),
      verify: (bloc) {
        expect(bloc.state.status, HomeStatus.ready);
        expect(bloc.state.rails, hasLength(6));
        expect(bloc.state.spotlight, hasLength(2));
        expect(bloc.state.featured?.id, 1);
      },
    );

    blocTest<HomeBloc, HomeState>(
      'keeps titles without a backdrop or synopsis out of the spotlight',
      build: () {
        stubAll([
          item(1),
          item(2, backdrop: '/b.jpg', overview: ''),
          item(3, backdrop: '/c.jpg'),
        ]);
        return HomeBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const HomeRequested()),
      verify: (bloc) {
        expect(bloc.state.spotlight.map((e) => e.id), [3]);
        // The rail still shows everything trending.
        expect(bloc.state.rails.first.items, hasLength(3));
      },
    );

    blocTest<HomeBloc, HomeState>(
      'the spotlight wraps back to the first reel',
      build: () {
        stubAll([item(1, backdrop: '/a.jpg'), item(2, backdrop: '/b.jpg')]);
        return HomeBloc(repository: repository);
      },
      act: (bloc) async {
        bloc.add(const HomeRequested());
        await Future<void>.delayed(Duration.zero);
        bloc
          ..add(const HomeSpotlightAdvanced())
          ..add(const HomeSpotlightAdvanced());
      },
      verify: (bloc) => expect(bloc.state.featured?.id, 1),
    );

    blocTest<HomeBloc, HomeState>(
      'reports a reachable message when TMDB refuses the key',
      build: () {
        when(() => repository.trending(page: any(named: 'page'))).thenThrow(
          const ApiException('TMDB rejected the API key.', isRetryable: false),
        );
        when(
          () => repository.movies(any(), page: any(named: 'page')),
        ).thenAnswer((_) async => const MediaPage.empty());
        when(
          () => repository.series(any(), page: any(named: 'page')),
        ).thenAnswer((_) async => const MediaPage.empty());
        return HomeBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const HomeRequested()),
      verify: (bloc) {
        expect(bloc.state.status, HomeStatus.failure);
        expect(bloc.state.error, 'TMDB rejected the API key.');
      },
    );
  });
}
