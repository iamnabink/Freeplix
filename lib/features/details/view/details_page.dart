import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freeplix/core/share/share_link.dart';
import 'package:freeplix/core/theme/app_colors.dart';
import 'package:freeplix/core/theme/app_spacing.dart';
import 'package:freeplix/core/theme/app_typography.dart';
import 'package:freeplix/core/widgets/media_row.dart';
import 'package:freeplix/core/widgets/meta_bar.dart';
import 'package:freeplix/core/widgets/net_image.dart';
import 'package:freeplix/core/widgets/selectable_copy.dart';
import 'package:freeplix/core/widgets/state_views.dart';
import 'package:freeplix/data/models/credits.dart';
import 'package:freeplix/data/models/media_detail.dart';
import 'package:freeplix/data/models/media_type.dart';
import 'package:freeplix/data/models/title_collection.dart';
import 'package:freeplix/data/repositories/tmdb_repository.dart';
import 'package:freeplix/features/details/bloc/details_cubit.dart';
import 'package:freeplix/features/details/widgets/cast_rail.dart';
import 'package:freeplix/features/details/widgets/episode_list.dart';
import 'package:freeplix/features/watchlist/bloc/watched_cubit.dart';
import 'package:freeplix/features/watchlist/bloc/watchlist_cubit.dart';
import 'package:freeplix/shell/view/app_footer.dart';
import 'package:freeplix/shell/view/app_shell.dart';
import 'package:freeplix/shell/view/page_padding.dart';
import 'package:go_router/go_router.dart';

class DetailsPage extends StatelessWidget {
  const DetailsPage({required this.type, required this.id, super.key});

  final MediaType type;
  final int id;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey('details-${type.wire}-$id'),
      create: (context) {
        final cubit = DetailsCubit(
          repository: context.read<TmdbRepository>(),
          type: type,
          id: id,
        );
        unawaited(cubit.load());
        return cubit;
      },
      child: const DetailsView(),
    );
  }
}

class DetailsView extends StatelessWidget {
  const DetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DetailsCubit, DetailsState>(
      builder: (context, state) {
        final detail = state.detail;

        if (state.status == DetailsStatus.failure) {
          return ErrorView(
            message: state.error ?? 'Freeplix could not load that title.',
            onRetry: context.read<DetailsCubit>().load,
          );
        }

        if (detail == null) return const LoadingView();

        return Title(
          title: '${detail.titleWithYear} · Freeplix',
          color: AppColors.ink,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Banner(detail: detail)),
              SliverToBoxAdapter(
                child: PagePadding(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (detail.seasons.isNotEmpty) ...[
                        const SizedBox(height: Insets.xxl),
                        _Episodes(detail: detail, state: state),
                      ],
                      if (detail.cast.isNotEmpty) ...[
                        const SizedBox(height: Insets.xxl),
                        const _SectionTitle('Cast'),
                        const SizedBox(height: Insets.md),
                        CastRail(cast: detail.cast),
                      ],
                      if (detail.collection != null) ...[
                        const SizedBox(height: Insets.xxl),
                        _CollectionRow(collection: detail.collection!),
                      ],
                      if (detail.similar.isNotEmpty) ...[
                        const SizedBox(height: Insets.xxl),
                        MediaRow(
                          title: 'More like this',
                          items: detail.similar,
                          onSelect: (item) => context.go(
                            '/title/${item.type.wire}/${item.id}',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SliverAppFooter(),
            ],
          ),
        );
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.detail});

  final MediaDetail detail;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < Breakpoints.compact;
    final isMedium = width < Breakpoints.medium;

    // On a phone the copy is taller than any backdrop worth showing, so the
    // artwork gets a fixed band at the top and the text flows beneath it.
    // Pinning both inside one fixed-height Stack overflowed and stacked the
    // buttons on top of the cast row.
    if (isCompact) {
      return Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 320,
            child: Stack(
              fit: StackFit.expand,
              children: [
                NetImage(url: detail.backdrop()),
                const DecoratedBox(
                  decoration: BoxDecoration(gradient: AppColors.backdropFade),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clears the shell header, then lets the artwork read before
              // the copy begins over its lower half.
              SizedBox(height: ShellChrome.of(context) + 150),
              PagePadding(child: _Headline(detail: detail)),
            ],
          ),
        ],
      );
    }

    return Stack(
      children: [
        SizedBox(
          height: 520,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              NetImage(url: detail.backdrop()),
              const DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.backdropScrim),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.backdropFade),
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: PagePadding(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: Insets.lg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isMedium) ...[
                      _Poster(detail: detail),
                      const SizedBox(width: Insets.xl),
                    ],
                    Expanded(child: _Headline(detail: detail)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.detail});

  final MediaDetail detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: AppColors.ash),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.6),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.lg - 1),
        child: SizedBox(
          width: 208,
          height: 312,
          child: NetImage(url: detail.poster()),
        ),
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.detail});

  final MediaDetail detail;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < Breakpoints.compact;

    // One selectable region so a reader can sweep from title to credits in a
    // single drag; the genre chips and action buttons opt out of it.
    return SelectableCopy(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Eyebrow(detail.type.label, color: AppColors.lamp),
          const SizedBox(height: Insets.xs),
          Text(
            detail.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.displayStyle(size: isCompact ? 32 : 54),
          ),
          if (detail.tagline.isNotEmpty) ...[
            const SizedBox(height: Insets.xs),
            Text(
              detail.tagline,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyStyle(
                size: isCompact ? 14 : 16,
              ),
            ),
          ],
          const SizedBox(height: Insets.sm),
          Row(
            children: [
              RatingPip(rating: detail.rating, size: 12),
              if (detail.rating != '—') const SizedBox(width: Insets.sm),
              Flexible(
                child: MetaBar(
                  size: 12,
                  entries: [
                    detail.year,
                    if (detail.runtime != null) detail.runtime!,
                    if (detail.seasonSummary != null) detail.seasonSummary!,
                    if (detail.certification.isNotEmpty) detail.certification,
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.md),
          if (detail.genres.isNotEmpty)
            SelectionContainer.disabled(
              child: Wrap(
                spacing: Insets.xs,
                runSpacing: Insets.xs,
                children: [
                  for (final genre in detail.genres.take(4))
                    _GenreTag(
                      label: genre.name,
                      onTap: () => context.go(
                        '/${detail.type == MediaType.movie ? 'movies' : 'series'}'
                        '?genre=${genre.id}',
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: Insets.md),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Text(
              detail.overview.isEmpty
                  ? 'TMDB has no synopsis for this title yet.'
                  : detail.overview,
              style: AppTypography.bodyStyle(size: isCompact ? 14 : 15.5),
            ),
          ),
          if (detail.directors.isNotEmpty || detail.writers.isNotEmpty) ...[
            const SizedBox(height: Insets.sm),
            _Credits(detail: detail),
          ],
          const SizedBox(height: Insets.lg),
          SelectionContainer.disabled(child: _Actions(detail: detail)),
        ],
      ),
    );
  }
}

class _Credits extends StatelessWidget {
  const _Credits({required this.detail});

  final MediaDetail detail;

  @override
  Widget build(BuildContext context) {
    Widget line(String label, List<CrewMember> people) => Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 96, child: Eyebrow(label)),
          Expanded(
            child: Wrap(
              children: [
                for (var i = 0; i < people.length; i++) ...[
                  _PersonLink(person: people[i]),
                  if (i < people.length - 1)
                    Text(', ', style: AppTypography.bodyStyle(size: 13)),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (detail.directorCrew.isNotEmpty)
          line('Director', detail.directorCrew),
        if (detail.writerCrew.isNotEmpty) line('Writer', detail.writerCrew),
      ],
    );
  }
}

/// A crew member's name, linking to a browse of everything they made.
class _PersonLink extends StatelessWidget {
  const _PersonLink({required this.person});

  final CrewMember person;

  @override
  Widget build(BuildContext context) {
    // Carve the link out of the surrounding SelectableCopy so hovering shows
    // the click cursor, not the text selection I-beam, and a tap fires cleanly.
    return SelectionContainer.disabled(
      child: Semantics(
        button: true,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => context.go('/movies?cast=${person.id}'),
            child: Text(
              person.name,
              style: AppTypography.bodyStyle(
                size: 13,
                weight: 600,
                color: AppColors.lamp,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.detail});

  final MediaDetail detail;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WatchlistCubit, WatchlistState>(
      builder: (context, watchlist) {
        final item = detail.asItem;
        final saved = watchlist.contains(item);

        return Wrap(
          spacing: Insets.sm,
          runSpacing: Insets.sm,
          children: [
            FilledButton.icon(
              onPressed: () => context.go(
                '/watch/${detail.type.wire}/${detail.id}',
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: const Text('Watch'),
            ),
            // Its own action, not a fallback hiding behind Watch.
            if (detail.trailer != null)
              OutlinedButton.icon(
                onPressed: () => context.go(
                  '/watch/${detail.type.wire}/${detail.id}?trailer=1',
                ),
                icon: const Icon(Icons.movie_creation_outlined, size: 19),
                label: const Text('Trailer'),
              ),
            OutlinedButton.icon(
              onPressed: () => context.read<WatchlistCubit>().toggle(item),
              icon: Icon(
                saved ? Icons.check_rounded : Icons.add_rounded,
                size: 20,
                color: saved ? AppColors.verdant : null,
              ),
              label: Text(saved ? 'In my list' : 'My list'),
            ),
            BlocBuilder<WatchedCubit, WatchedState>(
              builder: (context, watched) {
                final seen = watched.contains(item);
                return OutlinedButton.icon(
                  onPressed: () => context.read<WatchedCubit>().toggle(item),
                  icon: Icon(
                    seen ? Icons.visibility_rounded : Icons.visibility_outlined,
                    size: 19,
                    color: seen ? AppColors.lamp : null,
                  ),
                  label: Text(seen ? 'Watched' : 'Mark watched'),
                );
              },
            ),
            OutlinedButton.icon(
              onPressed: () => _share(context, detail),
              icon: const Icon(Icons.ios_share_rounded, size: 19),
              label: const Text('Share'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _share(BuildContext context, MediaDetail detail) async {
    final messenger = ScaffoldMessenger.of(context);
    final url = shareUrlFor('title/${detail.type.wire}/${detail.id}');
    final result = await shareOrCopy(url: url, text: detail.titleWithYear);
    if (result == ShareResult.copied) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Link copied to clipboard'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

/// The films in this movie's franchise, fetched lazily and shown as a row.
class _CollectionRow extends HookWidget {
  const _CollectionRow({required this.collection});

  final TitleCollection collection;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<TmdbRepository>();
    final future = useMemoized(
      () => repository.collectionParts(collection.id),
      [collection.id],
    );
    final snapshot = useFuture(future);

    final parts = snapshot.data ?? const [];
    // Not worth a row until the franchise has more than just this title.
    if (parts.length < 2) return const SizedBox.shrink();

    return MediaRow(
      title: collection.name,
      items: parts,
      onSelect: (item) => context.go('/title/${item.type.wire}/${item.id}'),
    );
  }
}

class _GenreTag extends StatelessWidget {
  const _GenreTag({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.soot.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(Radii.sm),
            border: Border.all(color: AppColors.ash),
          ),
          child: Text(
            label,
            style: AppTypography.monoStyle(size: 10.5, letterSpacing: 0.8),
          ),
        ),
      ),
    );
  }
}

class _Episodes extends StatelessWidget {
  const _Episodes({required this.detail, required this.state});

  final MediaDetail detail;
  final DetailsState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            _SectionTitle('Episodes'),
            Spacer(),
          ],
        ),
        const SizedBox(height: Insets.md),
        SeasonPicker(
          seasons: detail.seasons,
          selected: state.selectedSeason,
          onSelect: context.read<DetailsCubit>().selectSeason,
        ),
        const SizedBox(height: Insets.md),
        EpisodeList(
          episodes: state.episodes,
          isLoading: state.isLoadingEpisodes,
          onPlay: (episode) => context.go(
            '/watch/tv/${detail.id}'
            '?s=${episode.seasonNumber}&e=${episode.episodeNumber}',
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.headlineSmall);
  }
}
