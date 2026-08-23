import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:freeplix/data/models/media_item.dart';
import 'package:freeplix/data/repositories/watchlist_repository.dart';

class WatchlistState extends Equatable {
  const WatchlistState({this.items = const []});

  final List<MediaItem> items;

  bool contains(MediaItem item) =>
      items.any((e) => e.id == item.id && e.type == item.type);

  @override
  List<Object?> get props => [items];
}

/// My List. Reads once at startup, writes through on every change.
class WatchlistCubit extends Cubit<WatchlistState> {
  WatchlistCubit({required this._repository}) : super(const WatchlistState()) {
    emit(WatchlistState(items: _repository.load()));
  }

  final WatchlistRepository _repository;

  Future<void> toggle(MediaItem item) async {
    final next = [...state.items];
    final index = next.indexWhere(
      (e) => e.id == item.id && e.type == item.type,
    );

    if (index >= 0) {
      next.removeAt(index);
    } else {
      next.insert(0, item);
    }

    emit(WatchlistState(items: next));
    await _repository.save(next);
  }

  Future<void> clear() async {
    emit(const WatchlistState());
    await _repository.save(const []);
  }
}
