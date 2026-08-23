import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freeplix/core/theme/app_colors.dart';
import 'package:freeplix/core/theme/app_spacing.dart';
import 'package:freeplix/core/theme/app_typography.dart';
import 'package:freeplix/core/widgets/media_grid.dart';
import 'package:freeplix/core/widgets/meta_bar.dart';
import 'package:freeplix/core/widgets/state_views.dart';
import 'package:freeplix/data/models/media_filter.dart';
import 'package:freeplix/data/models/media_type.dart';
import 'package:freeplix/data/repositories/tmdb_repository.dart';
import 'package:freeplix/features/browse/bloc/browse_cubit.dart';
import 'package:freeplix/features/browse/widgets/filter_chip_tile.dart';
import 'package:freeplix/features/browse/widgets/filter_sheet.dart';
import 'package:freeplix/shell/view/app_footer.dart';
import 'package:freeplix/shell/view/app_shell.dart';
import 'package:freeplix/shell/view/page_padding.dart';
import 'package:go_router/go_router.dart';

class BrowsePage extends StatelessWidget {
  const BrowsePage({required this.type, this.genreId, super.key});

  final MediaType type;
  final int? genreId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey('browse-${type.wire}-$genreId'),
      create: (context) {
        final cubit = BrowseCubit(
          repository: context.read<TmdbRepository>(),
          type: type,
          initialFilter: MediaFilter(
            genreIds: {?genreId},
          ),
        );
        unawaited(cubit.start());
        return cubit;
      },
      child: BrowseView(type: type),
    );
  }
}

class BrowseView extends StatelessWidget {
  const BrowseView({required this.type, super.key});

  final MediaType type;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BrowseCubit, BrowseState>(
      builder: (context, state) {
        final cubit = context.read<BrowseCubit>();

        if (state.status == BrowseStatus.failure && state.items.isEmpty) {
          return ErrorView(
            message: state.error ?? 'Freeplix could not reach TMDB.',
            onRetry: cubit.start,
          );
        }

        final gutter = PagePadding.gutterFor(MediaQuery.sizeOf(context).width);

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PagePadding(
                child: _Header(type: type, state: state),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              sliver: state.isBusy
                  ? const MediaGridSkeletonSliver()
                  : MediaGridSliver(
                      items: state.items,
                      onSelect: (item) =>
                          context.go('/title/${item.type.wire}/${item.id}'),
                    ),
            ),
            if (!state.isBusy && state.items.isEmpty)
              SliverToBoxAdapter(
                child: EmptyView(
                  eyebrow: 'No matches',
                  message:
                      'Nothing in TMDB matches every filter at once. Try '
                      'removing one — genre plus language plus decade '
                      'narrows things quickly.',
                  action: OutlinedButton(
                    onPressed: cubit.clearFilter,
                    child: const Text('Clear filters'),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: PagePadding(
                vertical: Insets.xl,
                child: _LoadMore(state: state),
              ),
            ),
            const SliverAppFooter(),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.type, required this.state});

  final MediaType type;
  final BrowseState state;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final heading = type == MediaType.movie ? 'Films' : 'Series';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: ShellChrome.of(context) + Insets.lg),
        const Eyebrow('Browse the catalogue'),
        const SizedBox(height: Insets.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                state.filter.matchingIndustry == null
                    ? heading
                    : '${state.filter.matchingIndustry} $heading',
                style: AppTypography.displayStyle(size: isCompact ? 34 : 46),
              ),
            ),
            const SizedBox(width: Insets.md),
            _FilterButton(state: state, type: type),
          ],
        ),
        const SizedBox(height: Insets.md),
        _ActiveFilters(state: state),
        _ResultCount(state: state),
        const SizedBox(height: Insets.xl),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.state, required this.type});

  final BrowseState state;
  final MediaType type;

  @override
  Widget build(BuildContext context) {
    final count = state.filter.activeCount;
    final cubit = context.read<BrowseCubit>();

    return OutlinedButton.icon(
      onPressed: () async {
        final applied = await showFilterSheet(
          context,
          current: state.filter,
          genres: state.genres,
          type: type,
          repository: context.read<TmdbRepository>(),
        );
        if (applied != null) await cubit.applyFilter(applied);
      },
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: count > 0 ? AppColors.lamp : AppColors.ash,
        ),
      ),
      icon: Icon(
        Icons.tune_rounded,
        size: 18,
        color: count > 0 ? AppColors.lamp : AppColors.screen,
      ),
      label: Text(count > 0 ? 'Filters · $count' : 'Filters'),
    );
  }
}

/// What is currently narrowing the results, each removable in one tap.
class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({required this.state});

  final BrowseState state;

  @override
  Widget build(BuildContext context) {
    final filter = state.filter;
    if (filter.isEmpty) return const SizedBox.shrink();

    final cubit = context.read<BrowseCubit>();
    final industry = filter.matchingIndustry;

    String? languageLabel;
    if (filter.language != null && industry == null) {
      languageLabel = FilterOptions.languages
          .where((l) => l.code == filter.language)
          .map((l) => l.label)
          .firstOrNull;
    }
    String? countryLabel;
    if (filter.country != null && industry == null) {
      countryLabel = FilterOptions.countries
          .where((c) => c.code == filter.country)
          .map((c) => c.label)
          .firstOrNull;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.sm),
      child: Wrap(
        spacing: Insets.xs,
        runSpacing: Insets.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (industry != null)
            ActiveFilterChip(
              label: industry,
              onRemove: () => cubit.applyFilter(
                filter.copyWith(language: () => null, country: () => null),
              ),
            ),
          for (final genre in state.activeGenres)
            ActiveFilterChip(
              label: genre.name,
              onRemove: () => cubit.removeGenre(genre.id),
            ),
          if (languageLabel != null)
            ActiveFilterChip(
              label: languageLabel,
              onRemove: () =>
                  cubit.applyFilter(filter.copyWith(language: () => null)),
            ),
          if (countryLabel != null)
            ActiveFilterChip(
              label: countryLabel,
              onRemove: () =>
                  cubit.applyFilter(filter.copyWith(country: () => null)),
            ),
          if (filter.minRating != null)
            ActiveFilterChip(
              label: '${filter.minRating!.toStringAsFixed(0)}+ rating',
              onRemove: () =>
                  cubit.applyFilter(filter.copyWith(minRating: () => null)),
            ),
          if (filter.yearFrom != null)
            ActiveFilterChip(
              label: '${filter.yearFrom}s',
              onRemove: () => cubit.applyFilter(
                filter.copyWith(yearFrom: () => null, yearTo: () => null),
              ),
            ),
          TextButton(
            onPressed: cubit.clearFilter,
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
  }
}

class _ResultCount extends StatelessWidget {
  const _ResultCount({required this.state});

  final BrowseState state;

  @override
  Widget build(BuildContext context) {
    if (state.isBusy || state.items.isEmpty) return const SizedBox.shrink();

    return MetaBar(
      entries: [
        state.filter.sort.label,
        'Showing ${state.items.length} of ${state.totalResults}',
      ],
    );
  }
}

/// An explicit button rather than loading on scroll: the reader decides when
/// to fetch more, and the footer stays reachable.
class _LoadMore extends StatelessWidget {
  const _LoadMore({required this.state});

  final BrowseState state;

  @override
  Widget build(BuildContext context) {
    if (state.isBusy || state.items.isEmpty) return const SizedBox.shrink();

    if (!state.hasMore) {
      return Center(
        child: Text(
          "That's every match.",
          style: AppTypography.monoStyle(),
        ),
      );
    }

    final isLoading = state.status == BrowseStatus.loadingMore;

    return Center(
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : context.read<BrowseCubit>().loadMore,
        icon: isLoading
            ? const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.expand_more_rounded, size: 20),
        label: Text(isLoading ? 'Loading' : 'Load more'),
      ),
    );
  }
}
