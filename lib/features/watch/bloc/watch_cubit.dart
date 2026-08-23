import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:freeplix/core/config/stream_source.dart';
import 'package:freeplix/core/network/api_exception.dart';
import 'package:freeplix/data/models/media_detail.dart';
import 'package:freeplix/data/models/media_type.dart';
import 'package:freeplix/data/models/season.dart';
import 'package:freeplix/data/repositories/tmdb_repository.dart';

enum WatchStatus { loading, ready, failure }

/// What the player is showing. The trailer is its own choice, not a
/// consolation prize: it stays reachable even when a source is playing.
enum PlaybackKind {
  /// A configured playback source (see [StreamSource]).
  source,

  /// The official TMDB trailer.
  trailer,

  /// Nothing to play: no source selected and TMDB has no trailer.
  nothing,
}

class WatchState extends Equatable {
  WatchState({
    this.status = WatchStatus.loading,
    this.detail,
    this.sourceIndex = 0,
    this.season,
    this.episode,
    this.error,
    this.requestedKind,
    List<StreamSource>? sources,
  }) : sources = sources ?? StreamSources.all;

  final WatchStatus status;
  final MediaDetail? detail;
  final int sourceIndex;
  final int? season;
  final int? episode;
  final String? error;

  /// What the reader explicitly asked for, or null to let Freeplix decide.
  final PlaybackKind? requestedKind;

  /// Defaults to what the build was configured with; injectable for tests.
  final List<StreamSource> sources;

  StreamSource? get activeSource =>
      sources.isEmpty ? null : sources[sourceIndex % sources.length];

  bool get hasTrailer => detail?.trailer != null;

  /// The URL for the currently selected source, if it can build one.
  String? get sourceUrl {
    final media = detail;
    final source = activeSource;
    if (media == null || source == null) return null;
    return media.type == MediaType.movie
        ? source.movieUrl(media.id)
        : source.episodeUrl(media.id, season ?? 1, episode ?? 1);
  }

  /// What the player is showing.
  ///
  /// Watching and watching the trailer are separate intents: asking for the
  /// feature never silently gives you the trailer instead. When no source is
  /// configured the player says so rather than quietly substituting.
  PlaybackKind get kind {
    if (requestedKind == PlaybackKind.trailer) {
      return hasTrailer ? PlaybackKind.trailer : PlaybackKind.nothing;
    }
    return sourceUrl != null ? PlaybackKind.source : PlaybackKind.nothing;
  }

  /// The URL the player frame should load, or null when there is nothing.
  String? get playbackUrl => switch (kind) {
    PlaybackKind.source => sourceUrl,
    PlaybackKind.trailer => detail?.trailer?.embedUrl,
    PlaybackKind.nothing => null,
  };

  /// True when this build has no playback source at all — the state that
  /// needs explaining, and the one a clean checkout is in.
  bool get hasNoSourceConfigured => sources.isEmpty;

  /// `S02 · E07` for the currently selected episode.
  String? get episodeLabel {
    if (detail?.type != MediaType.tv || season == null || episode == null) {
      return null;
    }
    return 'S${season.toString().padLeft(2, '0')} · '
        'E${episode.toString().padLeft(2, '0')}';
  }

  WatchState copyWith({
    WatchStatus? status,
    MediaDetail? detail,
    int? sourceIndex,
    int? season,
    int? episode,
    String? error,
    PlaybackKind? Function()? requestedKind,
    List<StreamSource>? sources,
  }) {
    return WatchState(
      sources: sources ?? this.sources,
      status: status ?? this.status,
      detail: detail ?? this.detail,
      sourceIndex: sourceIndex ?? this.sourceIndex,
      season: season ?? this.season,
      episode: episode ?? this.episode,
      error: error,
      requestedKind: requestedKind == null
          ? this.requestedKind
          : requestedKind(),
    );
  }

  @override
  List<Object?> get props => [
    status,
    detail,
    sourceIndex,
    season,
    episode,
    error,
    requestedKind,
    sources,
  ];
}

class WatchCubit extends Cubit<WatchState> {
  WatchCubit({
    required this._repository,
    required this.type,
    required this.id,
    int? season,
    int? episode,
    bool trailer = false,
  }) : super(
         WatchState(
           season: season,
           episode: episode,
           requestedKind: trailer ? PlaybackKind.trailer : null,
         ),
       );

  final TmdbRepository _repository;
  final MediaType type;
  final int id;

  Future<void> load() async {
    emit(state.copyWith(status: WatchStatus.loading));
    try {
      final detail = await _repository.detail(type, id);

      // A series always needs a season and episode to play something.
      final season =
          state.season ??
          detail.seasons
              .where((s) => s.seasonNumber > 0)
              .firstOrNull
              ?.seasonNumber;

      emit(
        state.copyWith(
          status: WatchStatus.ready,
          detail: detail,
          season: type == MediaType.tv ? (season ?? 1) : null,
          episode: type == MediaType.tv ? (state.episode ?? 1) : null,
        ),
      );
    } on ApiException catch (error) {
      emit(state.copyWith(status: WatchStatus.failure, error: error.message));
    }
  }

  /// Play through one of the configured sources.
  void selectSource(int index) => emit(
    state.copyWith(
      sourceIndex: index,
      requestedKind: () => PlaybackKind.source,
    ),
  );

  /// Play the official trailer, whether or not a source is available.
  void selectTrailer() =>
      emit(state.copyWith(requestedKind: () => PlaybackKind.trailer));

  void selectEpisode(Episode episode) => emit(
    state.copyWith(
      season: episode.seasonNumber,
      episode: episode.episodeNumber,
    ),
  );
}
