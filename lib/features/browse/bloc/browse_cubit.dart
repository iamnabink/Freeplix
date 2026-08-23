import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:freeplix/core/network/api_exception.dart';
import 'package:freeplix/data/models/genre.dart';
import 'package:freeplix/data/models/media_filter.dart';
import 'package:freeplix/data/models/media_item.dart';
import 'package:freeplix/data/models/media_type.dart';
import 'package:freeplix/data/repositories/tmdb_repository.dart';

enum BrowseStatus { initial, loading, ready, loadingMore, failure }

class BrowseState extends Equatable {
  const BrowseState({
    this.status = BrowseStatus.initial,
    this.items = const [],
    this.genres = const [],
    this.filter = const MediaFilter(),
    this.page = 0,
    this.totalResults = 0,
    this.hasMore = false,
    this.error,
  });

  final BrowseStatus status;
  final List<MediaItem> items;
  final List<Genre> genres;
  final MediaFilter filter;
  final int page;
  final int totalResults;
  final bool hasMore;
  final String? error;

  bool get isBusy =>
      status == BrowseStatus.loading || status == BrowseStatus.initial;

  /// Genre objects for the ids in the filter, for the summary row.
  List<Genre> get activeGenres =>
      genres.where((g) => filter.genreIds.contains(g.id)).toList();

  BrowseState copyWith({
    BrowseStatus? status,
    List<MediaItem>? items,
    List<Genre>? genres,
    MediaFilter? filter,
    int? page,
    int? totalResults,
    bool? hasMore,
    String? error,
  }) {
    return BrowseState(
      status: status ?? this.status,
      items: items ?? this.items,
      genres: genres ?? this.genres,
      filter: filter ?? this.filter,
      page: page ?? this.page,
      totalResults: totalResults ?? this.totalResults,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    genres,
    filter,
    page,
    totalResults,
    hasMore,
    error,
  ];
}

class BrowseCubit extends Cubit<BrowseState> {
  BrowseCubit({
    required this._repository,
    required this.type,
    MediaFilter initialFilter = const MediaFilter(),
  }) : super(BrowseState(filter: initialFilter));

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

  /// Replaces the whole filter — what the filter sheet applies on close.
  Future<void> applyFilter(MediaFilter filter) async {
    if (filter == state.filter) return;
    emit(state.copyWith(filter: filter, status: BrowseStatus.loading));
    await _fetch(reset: true);
  }

  Future<void> clearFilter() => applyFilter(state.filter.cleared());

  Future<void> setSort(SortOption sort) =>
      applyFilter(state.filter.copyWith(sort: sort));

  /// Removes one genre from the summary row without opening the sheet.
  Future<void> removeGenre(int id) => applyFilter(
    state.filter.copyWith(genreIds: {...state.filter.genreIds}..remove(id)),
  );

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
        filter: state.filter,
      );

      emit(
        state.copyWith(
          status: BrowseStatus.ready,
          items: reset ? result.items : [...state.items, ...result.items],
          page: result.page,
          totalResults: result.totalResults,
          hasMore: result.hasMore,
        ),
      );
    } on ApiException catch (error) {
      emit(state.copyWith(status: BrowseStatus.failure, error: error.message));
    }
  }
}
