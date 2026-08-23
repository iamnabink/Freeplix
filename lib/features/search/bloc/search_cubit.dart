import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:freeplix/core/network/api_exception.dart';
import 'package:freeplix/data/models/media_item.dart';
import 'package:freeplix/data/repositories/tmdb_repository.dart';

enum SearchStatus { idle, typing, loading, ready, failure }

class SearchState extends Equatable {
  const SearchState({
    this.status = SearchStatus.idle,
    this.query = '',
    this.results = const [],
    this.error,
  });

  final SearchStatus status;
  final String query;
  final List<MediaItem> results;
  final String? error;

  @override
  List<Object?> get props => [status, query, results, error];
}

/// Search waits for a pause in typing before it asks TMDB anything —
/// one request per thought, not one per keystroke.
class SearchCubit extends Cubit<SearchState> {
  SearchCubit({required this._repository}) : super(const SearchState());

  static const _debounce = Duration(milliseconds: 320);

  final TmdbRepository _repository;
  Timer? _timer;
  int _requestId = 0;

  void query(String value) {
    _timer?.cancel();
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      emit(const SearchState());
      return;
    }

    emit(SearchState(status: SearchStatus.typing, query: trimmed));
    _timer = Timer(_debounce, () => _run(trimmed));
  }

  Future<void> retry() => _run(state.query);

  Future<void> _run(String value) async {
    if (value.isEmpty) return;
    final id = ++_requestId;
    emit(SearchState(status: SearchStatus.loading, query: value));

    try {
      final page = await _repository.search(value);
      // A slower earlier request must not overwrite a newer one.
      if (id != _requestId || isClosed) return;
      emit(
        SearchState(
          status: SearchStatus.ready,
          query: value,
          results: page.items,
        ),
      );
    } on ApiException catch (error) {
      if (id != _requestId || isClosed) return;
      emit(
        SearchState(
          status: SearchStatus.failure,
          query: value,
          error: error.message,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
