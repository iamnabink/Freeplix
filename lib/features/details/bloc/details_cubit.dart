import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:freeplix/core/network/api_exception.dart';
import 'package:freeplix/data/models/media_detail.dart';
import 'package:freeplix/data/models/media_type.dart';
import 'package:freeplix/data/models/season.dart';
import 'package:freeplix/data/repositories/tmdb_repository.dart';

enum DetailsStatus { initial, loading, ready, failure }

class DetailsState extends Equatable {
  const DetailsState({
    this.status = DetailsStatus.initial,
    this.detail,
    this.selectedSeason,
    this.episodes = const [],
    this.isLoadingEpisodes = false,
    this.error,
  });

  final DetailsStatus status;
  final MediaDetail? detail;
  final int? selectedSeason;
  final List<Episode> episodes;
  final bool isLoadingEpisodes;
  final String? error;

  DetailsState copyWith({
    DetailsStatus? status,
    MediaDetail? detail,
    int? selectedSeason,
    List<Episode>? episodes,
    bool? isLoadingEpisodes,
    String? error,
  }) {
    return DetailsState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      selectedSeason: selectedSeason ?? this.selectedSeason,
      episodes: episodes ?? this.episodes,
      isLoadingEpisodes: isLoadingEpisodes ?? this.isLoadingEpisodes,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    detail,
    selectedSeason,
    episodes,
    isLoadingEpisodes,
    error,
  ];
}

class DetailsCubit extends Cubit<DetailsState> {
  DetailsCubit({
    required this._repository,
    required this.type,
    required this.id,
  }) : super(const DetailsState());

  final TmdbRepository _repository;
  final MediaType type;
  final int id;

  Future<void> load() async {
    emit(state.copyWith(status: DetailsStatus.loading));
    try {
      final detail = await _repository.detail(type, id);
      emit(state.copyWith(status: DetailsStatus.ready, detail: detail));

      // Series open on their first real season, episodes already loading.
      final firstSeason = detail.seasons
          .where((s) => s.seasonNumber > 0)
          .firstOrNull;
      if (firstSeason != null) await selectSeason(firstSeason.seasonNumber);
    } on ApiException catch (error) {
      emit(
        state.copyWith(status: DetailsStatus.failure, error: error.message),
      );
    }
  }

  Future<void> selectSeason(int seasonNumber) async {
    emit(
      state.copyWith(
        selectedSeason: seasonNumber,
        isLoadingEpisodes: true,
        episodes: const [],
      ),
    );

    try {
      final episodes = await _repository.episodes(id, seasonNumber);
      if (isClosed || state.selectedSeason != seasonNumber) return;
      emit(state.copyWith(episodes: episodes, isLoadingEpisodes: false));
    } on ApiException {
      if (isClosed) return;
      // A missing season listing is not worth losing the page over.
      emit(state.copyWith(isLoadingEpisodes: false));
    }
  }
}
