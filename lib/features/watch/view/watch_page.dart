import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freeplix/core/config/app_config.dart';
import 'package:freeplix/core/theme/app_colors.dart';
import 'package:freeplix/core/theme/app_spacing.dart';
import 'package:freeplix/core/theme/app_typography.dart';
import 'package:freeplix/core/widgets/embed/web_embed.dart';
import 'package:freeplix/core/widgets/meta_bar.dart';
import 'package:freeplix/core/widgets/state_views.dart';
import 'package:freeplix/core/widgets/wordmark.dart';
import 'package:freeplix/data/models/media_type.dart';
import 'package:freeplix/data/repositories/tmdb_repository.dart';
import 'package:freeplix/features/details/bloc/details_cubit.dart';
import 'package:freeplix/features/details/widgets/episode_list.dart';
import 'package:freeplix/features/watch/bloc/watch_cubit.dart';
import 'package:freeplix/shell/view/page_padding.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class WatchPage extends StatelessWidget {
  const WatchPage({
    required this.type,
    required this.id,
    this.season,
    this.episode,
    this.trailer = false,
    super.key,
  });

  final MediaType type;
  final int id;
  final int? season;
  final int? episode;

  /// Arrived via "Watch trailer" rather than "Watch".
  final bool trailer;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<TmdbRepository>();

    return MultiBlocProvider(
      key: ValueKey('watch-${type.wire}-$id-$trailer'),
      providers: [
        BlocProvider(
          create: (_) {
            final cubit = WatchCubit(
              repository: repository,
              type: type,
              id: id,
              season: season,
              episode: episode,
              trailer: trailer,
            );
            unawaited(cubit.load());
            return cubit;
          },
        ),
        BlocProvider(
          create: (_) {
            final cubit = DetailsCubit(
              repository: repository,
              type: type,
              id: id,
            );
            unawaited(cubit.load());
            return cubit;
          },
        ),
      ],
      child: const WatchView(),
    );
  }
}

class WatchView extends StatelessWidget {
  const WatchView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: BlocBuilder<WatchCubit, WatchState>(
        builder: (context, state) {
          if (state.status == WatchStatus.failure) {
            return ErrorView(
              message: state.error ?? 'Freeplix could not load that title.',
              onRetry: context.read<WatchCubit>().load,
            );
          }

          final detail = state.detail;
          if (detail == null) return const LoadingView();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _PlayerBar(state: state)),
              SliverToBoxAdapter(child: _Stage(state: state)),
              SliverToBoxAdapter(
                child: PagePadding(
                  vertical: Insets.lg,
                  child: _BelowStage(state: state),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: Insets.xxl)),
            ],
          );
        },
      ),
    );
  }
}

class _PlayerBar extends StatelessWidget {
  const _PlayerBar({required this.state});

  final WatchState state;

  @override
  Widget build(BuildContext context) {
    final detail = state.detail!;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.soot,
        border: Border(bottom: BorderSide(color: AppColors.ash)),
      ),
      child: SafeArea(
        bottom: false,
        child: PagePadding(
          vertical: Insets.sm,
          child: Row(
            children: [
              IconButton(
                tooltip: 'Back to details',
                onPressed: () => context.go(
                  '/title/${detail.type.wire}/${detail.id}',
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                color: AppColors.screen,
              ),
              const SizedBox(width: Insets.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      detail.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyStyle(
                        size: 15,
                        weight: 600,
                        color: AppColors.emulsion,
                      ),
                    ),
                    MetaBar(
                      size: 10,
                      entries: [
                        if (state.episodeLabel != null) state.episodeLabel!,
                        detail.year,
                        switch (state.kind) {
                          PlaybackKind.source =>
                            state.activeSource?.name ?? 'Source',
                          PlaybackKind.trailer => 'Official trailer',
                          PlaybackKind.nothing => 'Nothing to play',
                        },
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Insets.md),
              GestureDetector(
                onTap: () => context.go('/'),
                child: const MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Wordmark(size: 17),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The picture itself, always 16:9 and always the widest thing on the page.
class _Stage extends StatelessWidget {
  const _Stage({required this.state});

  final WatchState state;

  @override
  Widget build(BuildContext context) {
    final url = state.playbackUrl;

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1600),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: switch (state.kind) {
              PlaybackKind.nothing => _NoPlayback(state: state),
              _ when !WebEmbed.isSupported => _OpenExternally(url: url!),
              _ => WebEmbed(url: url!),
            },
          ),
        ),
      ),
    );
  }
}

class _NoPlayback extends StatelessWidget {
  const _NoPlayback({required this.state});

  final WatchState state;

  @override
  Widget build(BuildContext context) {
    // Two very different reasons to be here — say which one it is.
    if (state.hasNoSourceConfigured) {
      return EmptyView(
        compact: true,
        icon: Icons.settings_input_antenna_rounded,
        eyebrow: 'No playback source',
        message: kReleaseMode
            ? 'Freeplix is a catalogue — this deployment has no playback '
                  'source, so there is no feature to stream here. The '
                  'official trailer is available.'
            : 'This build has no playback source configured. Add '
                  'FREEPLIX_SOURCES to .env (or the repository secret of '
                  'the same name for a deploy) to point Freeplix at a '
                  'library you can stream.',
        action: state.hasTrailer
            ? OutlinedButton.icon(
                onPressed: context.read<WatchCubit>().selectTrailer,
                icon: const Icon(Icons.movie_creation_outlined, size: 18),
                label: const Text('Watch the trailer instead'),
              )
            : null,
      );
    }

    return const EmptyView(
      compact: true,
      icon: Icons.videocam_off_outlined,
      eyebrow: 'Nothing to play',
      message: 'TMDB has no trailer for this title.',
    );
  }
}

/// Mobile and desktop builds hand playback to the system browser rather than
/// embedding a frame the platform cannot sandbox.
class _OpenExternally extends StatelessWidget {
  const _OpenExternally({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return EmptyView(
      compact: true,
      icon: Icons.open_in_new_rounded,
      eyebrow: 'Opens outside Freeplix',
      message:
          'The in-app player is web-only for now. Open this title in your '
          'browser to watch it.',
      action: FilledButton(
        onPressed: () => launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        ),
        child: const Text('Open in browser'),
      ),
    );
  }
}

class _BelowStage extends StatelessWidget {
  const _BelowStage({required this.state});

  final WatchState state;

  @override
  Widget build(BuildContext context) {
    final detail = state.detail!;

    // Only worth a switcher when there is more than one thing to switch to.
    final hasChoice =
        state.sources.isNotEmpty && state.hasTrailer ||
        state.sources.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasChoice) ...[
          const Eyebrow('Playing'),
          const SizedBox(height: Insets.xs),
          _PlaybackSwitcher(state: state),
          const SizedBox(height: Insets.lg),
        ],
        if (state.hasNoSourceConfigured) const _TrailerNotice(),
        if (detail.type == MediaType.tv) ...[
          const SizedBox(height: Insets.lg),
          _EpisodePicker(state: state),
        ],
      ],
    );
  }
}

/// Every playback source, plus the trailer as a peer rather than a fallback.
class _PlaybackSwitcher extends StatelessWidget {
  const _PlaybackSwitcher({required this.state});

  final WatchState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WatchCubit>();
    final onSource = state.kind == PlaybackKind.source;

    return Wrap(
      spacing: Insets.xs,
      runSpacing: Insets.xs,
      children: [
        for (var i = 0; i < state.sources.length; i++)
          _PlaybackChip(
            label: state.sources[i].name,
            icon: Icons.play_arrow_rounded,
            selected: onSource && i == state.sourceIndex,
            onTap: () => cubit.selectSource(i),
          ),
        if (state.hasTrailer)
          _PlaybackChip(
            label: 'Trailer',
            icon: Icons.movie_creation_outlined,
            selected: state.kind == PlaybackKind.trailer,
            onTap: cubit.selectTrailer,
          ),
      ],
    );
  }
}

class _PlaybackChip extends StatelessWidget {
  const _PlaybackChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: Motion.fast,
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.sm,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: selected ? AppColors.lamp : AppColors.soot,
              borderRadius: BorderRadius.circular(Radii.sm),
              border: Border.all(
                color: selected ? AppColors.lamp : AppColors.ash,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected ? AppColors.ink : AppColors.screenDim,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTypography.bodyStyle(
                    size: 13,
                    weight: 600,
                    color: selected ? AppColors.ink : AppColors.screen,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Explains, once, why the trailer is playing instead of the feature.
class _TrailerNotice extends StatelessWidget {
  const _TrailerNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: AppColors.soot,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: AppColors.ash),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.lamp,
          ),
          const SizedBox(width: Insets.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Playing the official trailer',
                  style: AppTypography.bodyStyle(
                    size: 14,
                    weight: 600,
                    color: AppColors.emulsion,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Freeplix ships with no playback source. It reads its '
                  'catalogue from TMDB and plays the trailers TMDB '
                  'publishes. To point this build at a library you are '
                  'licensed to stream, set FREEPLIX_SOURCES at build time.',
                  style: AppTypography.bodyStyle(size: 13.5),
                ),
                const SizedBox(height: Insets.xs),
                TextButton(
                  onPressed: () => launchUrl(
                    Uri.parse('${AppConfig.repositoryUrl}#playback-sources'),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: const Text('How to configure a source'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EpisodePicker extends StatelessWidget {
  const _EpisodePicker({required this.state});

  final WatchState state;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DetailsCubit, DetailsState>(
      builder: (context, details) {
        final detail = details.detail;
        if (detail == null || detail.seasons.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Episodes',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: Insets.md),
            SeasonPicker(
              seasons: detail.seasons,
              selected: details.selectedSeason,
              onSelect: context.read<DetailsCubit>().selectSeason,
            ),
            const SizedBox(height: Insets.md),
            EpisodeList(
              episodes: details.episodes,
              isLoading: details.isLoadingEpisodes,
              onPlay: context.read<WatchCubit>().selectEpisode,
            ),
          ],
        );
      },
    );
  }
}
