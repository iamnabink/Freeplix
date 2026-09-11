import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:freeplix/data/models/media_item.dart';
import 'package:freeplix/data/repositories/watched_repository.dart';

class WatchedState extends Equatable {
  const WatchedState({this.items = const []});

  final List<MediaItem> items;

  bool contains(MediaItem item) =>
      items.any((e) => e.id == item.id && e.type == item.type);

  @override
  List<Object?> get props => [items];
}

/// Titles the viewer has marked as seen. Reads once at startup, writes through
/// on every change.
class WatchedCubit extends Cubit<WatchedState> {
  WatchedCubit({required this._repository}) : super(const WatchedState()) {
    emit(WatchedState(items: _repository.load()));
  }

  final WatchedRepository _repository;

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

    emit(WatchedState(items: next));
    await _repository.save(next);
  }

  Future<void> clear() async {
    emit(const WatchedState());
    await _repository.save(const []);
  }
}
