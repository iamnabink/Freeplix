part of 'home_bloc.dart';

enum HomeStatus { initial, loading, ready, failure }

/// One carousel on the home page.
class HomeRail extends Equatable {
  const HomeRail({required this.title, required this.items, this.seeAll});

  final String title;
  final List<MediaItem> items;

  /// Where "See all" goes, if this rail has a browse equivalent.
  final String? seeAll;

  @override
  List<Object?> get props => [title, items, seeAll];
}

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.spotlight = const [],
    this.spotlightIndex = 0,
    this.rails = const [],
    this.error,
  });

  final HomeStatus status;
  final List<MediaItem> spotlight;
  final int spotlightIndex;
  final List<HomeRail> rails;
  final String? error;

  MediaItem? get featured =>
      spotlight.isEmpty ? null : spotlight[spotlightIndex % spotlight.length];

  HomeState copyWith({
    HomeStatus? status,
    List<MediaItem>? spotlight,
    int? spotlightIndex,
    List<HomeRail>? rails,
    String? error,
  }) {
    return HomeState(
      status: status ?? this.status,
      spotlight: spotlight ?? this.spotlight,
      spotlightIndex: spotlightIndex ?? this.spotlightIndex,
      rails: rails ?? this.rails,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    spotlight,
    spotlightIndex,
    rails,
    error,
  ];
}
