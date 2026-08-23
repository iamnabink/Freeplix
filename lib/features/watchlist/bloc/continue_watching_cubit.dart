import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:freeplix/data/models/media_detail.dart';
import 'package:freeplix/data/models/media_type.dart';
import 'package:freeplix/data/models/watch_progress.dart';
import 'package:freeplix/data/repositories/watch_progress_repository.dart';

class ContinueWatchingState extends Equatable {
  const ContinueWatchingState({this.entries = const []});

  final List<WatchProgress> entries;

  @override
  List<Object?> get props => [entries];
}

/// Remembers what was opened in the player, most recent first.
class ContinueWatchingCubit extends Cubit<ContinueWatchingState> {
  ContinueWatchingCubit({required this._repository})
    : super(const ContinueWatchingState()) {
    emit(ContinueWatchingState(entries: _repository.load()));
  }

  final WatchProgressRepository _repository;

  /// Called when the player opens a title. Re-opening a series at a new
  /// episode replaces the earlier entry rather than stacking up.
  Future<void> record(
    MediaDetail detail, {
    int? season,
    int? episode,
    DateTime? at,
  }) async {
    final entry = WatchProgress(
      id: detail.id,
      type: detail.type,
      title: detail.title,
      openedAt: at ?? DateTime.now(),
      posterPath: detail.posterPath,
      backdropPath: detail.backdropPath,
      season: detail.type == MediaType.tv ? season : null,
      episode: detail.type == MediaType.tv ? episode : null,
    );

    final next = [
      entry,
      ...state.entries.where((e) => e.key != entry.key),
    ];

    emit(ContinueWatchingState(entries: next));
    await _repository.save(next);
  }

  Future<void> remove(WatchProgress entry) async {
    final next = state.entries.where((e) => e.key != entry.key).toList();
    emit(ContinueWatchingState(entries: next));
    await _repository.save(next);
  }

  Future<void> clear() async {
    emit(const ContinueWatchingState());
    await _repository.save(const []);
  }
}
