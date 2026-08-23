import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freeplix/core/theme/app_colors.dart';
import 'package:freeplix/core/theme/app_spacing.dart';
import 'package:freeplix/core/theme/app_typography.dart';
import 'package:freeplix/core/widgets/media_grid.dart';
import 'package:freeplix/core/widgets/meta_bar.dart';
import 'package:freeplix/core/widgets/state_views.dart';
import 'package:freeplix/data/models/genre.dart';
import 'package:freeplix/data/models/media_type.dart';
import 'package:freeplix/data/repositories/tmdb_repository.dart';
import 'package:freeplix/features/browse/bloc/browse_cubit.dart';
import 'package:freeplix/shell/view/page_padding.dart';
import 'package:go_router/go_router.dart';

class BrowsePage extends StatelessWidget {
  const BrowsePage({required this.type, this.genreId, super.key});

  final MediaType type;
  final int? genreId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Keyed on the filter so arriving from a link rebuilds cleanly.
      key: ValueKey('browse-${type.wire}-$genreId'),
      create: (context) {
        final cubit = BrowseCubit(
          repository: context.read<TmdbRepository>(),
          type: type,
          genreId: genreId,
        );
        // The cubit reports progress through its state; nothing awaits this.
        unawaited(cubit.start());
        return cubit;
      },
      child: BrowseView(type: type),
    );
  }
}

class BrowseView extends HookWidget {
  const BrowseView({required this.type, super.key});

  final MediaType type;

  @override
  Widget build(BuildContext context) {
    final controller = useScrollController();
    final cubit = context.read<BrowseCubit>();

    useEffect(() {
      void onScroll() {
        if (!controller.hasClients) return;
        final position = controller.position;
        if (position.pixels > position.maxScrollExtent - 900) {
          unawaited(cubit.loadMore());
        }
      }

      controller.addListener(onScroll);
      return () => controller.removeListener(onScroll);
    }, [controller]);

    return BlocBuilder<BrowseCubit, BrowseState>(
      builder: (context, state) {
        if (state.status == BrowseStatus.failure && state.items.isEmpty) {
          return ErrorView(
            message: state.error ?? 'Freeplix could not reach TMDB.',
            onRetry: cubit.start,
          );
        }

        final isLoading =
            state.status == BrowseStatus.loading ||
            state.status == BrowseStatus.initial;

        return CustomScrollView(
          controller: controller,
          slivers: [
            SliverToBoxAdapter(
              child: PagePadding(
                child: _BrowseHeader(type: type, state: state),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: PagePadding.gutterFor(
                  MediaQuery.sizeOf(context).width,
                ),
              ),
              sliver: isLoading
                  ? const MediaGridSkeletonSliver()
                  : MediaGridSliver(
                      items: state.items,
                      onSelect: (item) => context.go(
                        '/title/${item.type.wire}/${item.id}',
                      ),
                    ),
            ),
            if (!isLoading && state.items.isEmpty)
              const SliverToBoxAdapter(
                child: EmptyView(
                  eyebrow: 'Nothing here',
                  message: 'No titles match that filter. Try another genre.',
                ),
              ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: Insets.xxxl,
                child: state.status == BrowseStatus.loadingMore
                    ? const LoadingView()
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BrowseHeader extends StatelessWidget {
  const _BrowseHeader({required this.type, required this.state});

  final MediaType type;
  final BrowseState state;

  @override
  Widget build(BuildContext context) {
    final isCompact =
        MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final cubit = context.read<BrowseCubit>();
    final heading = type == MediaType.movie ? 'Films' : 'Series';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: isCompact ? Insets.lg : Insets.xxxl + Insets.md),
        const Eyebrow('Browse the catalogue'),
        const SizedBox(height: Insets.xs),
        Text(
          state.activeGenre == null
              ? heading
              : '${state.activeGenre!.name} $heading'.trim(),
          style: AppTypography.displayStyle(size: isCompact ? 34 : 46),
        ),
        const SizedBox(height: Insets.lg),
        _SortRow(sort: state.sort, onSelect: cubit.selectSort),
        const SizedBox(height: Insets.md),
        _GenreChips(
          genres: state.genres,
          activeId: state.genreId,
          onSelect: cubit.selectGenre,
        ),
        const SizedBox(height: Insets.xl),
      ],
    );
  }
}

class _SortRow extends StatelessWidget {
  const _SortRow({required this.sort, required this.onSelect});

  final BrowseSort sort;
  final ValueChanged<BrowseSort> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Insets.xs,
      runSpacing: Insets.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Padding(
          padding: EdgeInsets.only(right: Insets.xxs),
          child: Eyebrow('Sort'),
        ),
        for (final option in BrowseSort.values)
          _Pill(
            label: option.label,
            active: option == sort,
            onTap: () => onSelect(option),
          ),
      ],
    );
  }
}

class _GenreChips extends StatelessWidget {
  const _GenreChips({
    required this.genres,
    required this.activeId,
    required this.onSelect,
  });

  final List<Genre> genres;
  final int? activeId;
  final ValueChanged<int?> onSelect;

  @override
  Widget build(BuildContext context) {
    if (genres.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: Insets.xs,
      runSpacing: Insets.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Padding(
          padding: EdgeInsets.only(right: Insets.xxs),
          child: Eyebrow('Genre'),
        ),
        _Pill(
          label: 'All',
          active: activeId == null,
          onTap: () => onSelect(null),
        ),
        for (final genre in genres)
          _Pill(
            label: genre.name,
            active: genre.id == activeId,
            onTap: () => onSelect(genre.id),
          ),
      ],
    );
  }
}

class _Pill extends HookWidget {
  const _Pill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hovered = useState(false);

    return Semantics(
      button: true,
      selected: active,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => hovered.value = true,
        onExit: (_) => hovered.value = false,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: Motion.fast,
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.sm,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: active ? AppColors.lamp : AppColors.soot,
              borderRadius: BorderRadius.circular(Radii.sm),
              border: Border.all(
                color: active
                    ? AppColors.lamp
                    : (hovered.value ? AppColors.screenDim : AppColors.ash),
              ),
            ),
            child: Text(
              label,
              style: AppTypography.bodyStyle(
                size: 13,
                weight: active ? 600 : 500,
                color: active ? AppColors.ink : AppColors.screen,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
