import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:freeplix/core/network/api_exception.dart';
import 'package:freeplix/data/models/media_item.dart';
import 'package:freeplix/data/repositories/tmdb_repository.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({required this._repository}) : super(const HomeState()) {
    on<HomeRequested>(_onRequested);
    on<HomeSpotlightAdvanced>(_onSpotlightAdvanced);
  }

  final TmdbRepository _repository;

  Future<void> _onRequested(
    HomeRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loading));

    try {
      // One round trip per rail, all in flight together.
      final results = await Future.wait([
        _repository.trending(),
        _repository.movies(MovieFeed.nowPlaying),
        _repository.series(SeriesFeed.popular),
        _repository.movies(MovieFeed.topRated),
        _repository.series(SeriesFeed.onTheAir),
        _repository.movies(MovieFeed.upcoming),
      ]);

      final trending = results[0].items;

      emit(
        state.copyWith(
          status: HomeStatus.ready,
          spotlight: trending
              .where((e) => e.backdropPath != null && e.overview.isNotEmpty)
              .take(6)
              .toList(),
          rails: [
            HomeRail(title: 'Trending this week', items: trending),
            HomeRail(
              title: 'In theatres now',
              items: results[1].items,
              seeAll: '/movies',
            ),
            HomeRail(
              title: 'Popular series',
              items: results[2].items,
              seeAll: '/series',
            ),
            HomeRail(title: 'Top rated films', items: results[3].items),
            HomeRail(title: 'On the air', items: results[4].items),
            HomeRail(title: 'Coming soon', items: results[5].items),
          ],
        ),
      );
    } on ApiException catch (error) {
      emit(state.copyWith(status: HomeStatus.failure, error: error.message));
    }
  }

  void _onSpotlightAdvanced(
    HomeSpotlightAdvanced event,
    Emitter<HomeState> emit,
  ) {
    if (state.spotlight.isEmpty) return;
    emit(state.copyWith(spotlightIndex: state.spotlightIndex + 1));
  }
}
