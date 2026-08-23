import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:freeplix/core/network/api_exception.dart';
import 'package:freeplix/data/models/genre.dart';
import 'package:freeplix/data/models/media_item.dart';
import 'package:freeplix/data/models/media_type.dart';
import 'package:freeplix/data/repositories/tmdb_repository.dart';

enum BrowseStatus { initial, loading, ready, loadingMore, failure }

enum BrowseSort {
  popular('popularity.desc', 'Most popular'),
  rated('vote_average.desc', 'Highest rated'),
  newest('primary_release_date.desc', 'Newest first');

  const BrowseSort(this.wire, this.label);

  final String wire;
  final String label;

  /// TMDB names the release-date field differently for series.
  String wireFor(MediaType type) =>
      this == BrowseSort.newest && type == MediaType.tv
      ? 'first_air_date.desc'
      : wire;
}

class BrowseState extends Equatable {
  const BrowseState({
    this.status = BrowseStatus.initial,
    this.items = const [],
    this.genres = const [],
    this.genreId,
    this.sort = BrowseSort.popular,
    this.page = 0,
    this.hasMore = false,
    this.error,
  });

  final BrowseStatus status;
  final List<MediaItem> items;
  final List<Genre> genres;
  final int? genreId;
  final BrowseSort sort;
  final int page;
  final bool hasMore;
  final String? error;

  Genre? get activeGenre => genres.where((g) => g.id == genreId).firstOrNull;

  BrowseState copyWith({
    BrowseStatus? status,
    List<MediaItem>? items,
    List<Genre>? genres,
    int? Function()? genreId,
    BrowseSort? sort,
    int? page,
    bool? hasMore,
    String? error,
  }) {
    return BrowseState(
      status: status ?? this.status,
      items: items ?? this.items,
      genres: genres ?? this.genres,
      genreId: genreId == null ? this.genreId : genreId(),
      sort: sort ?? this.sort,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    genres,
    genreId,
    sort,
    page,
    hasMore,
    error,
  ];
}

class BrowseCubit extends Cubit<BrowseState> {
  BrowseCubit({
    required this._repository,
    required this.type,
    int? genreId,
  }) : super(BrowseState(genreId: genreId));

  final TmdbRepository _repository;
  final MediaType type;

  Future<void> start() async {
    emit(state.copyWith(status: BrowseStatus.loading));
    try {
      final genres = await _repository.genres(type);
      emit(state.copyWith(genres: genres));
      await _fetch(reset: true);
    } on ApiException catch (error) {
      emit(state.copyWith(status: BrowseStatus.failure, error: error.message));
    }
  }

  Future<void> selectGenre(int? id) async {
    if (id == state.genreId) return;
    emit(state.copyWith(genreId: () => id, status: BrowseStatus.loading));
    await _fetch(reset: true);
  }

  Future<void> selectSort(BrowseSort sort) async {
    if (sort == state.sort) return;
    emit(state.copyWith(sort: sort, status: BrowseStatus.loading));
    await _fetch(reset: true);
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.status == BrowseStatus.loadingMore) return;
    emit(state.copyWith(status: BrowseStatus.loadingMore));
    await _fetch(reset: false);
  }

  Future<void> _fetch({required bool reset}) async {
    try {
      final page = reset ? 1 : state.page + 1;
      final result = await _repository.discover(
        type,
        page: page,
        genreId: state.genreId,
        sortBy: state.sort.wireFor(type),
      );

      final merged = reset ? result.items : [...state.items, ...result.items];

      emit(
        state.copyWith(
          status: BrowseStatus.ready,
          items: merged,
          page: result.page,
          hasMore: result.hasMore,
        ),
      );
    } on ApiException catch (error) {
      emit(state.copyWith(status: BrowseStatus.failure, error: error.message));
    }
  }
}
