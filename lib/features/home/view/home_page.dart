import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freeplix/core/theme/app_spacing.dart';
import 'package:freeplix/core/widgets/media_row.dart';
import 'package:freeplix/core/widgets/state_views.dart';
import 'package:freeplix/data/models/media_item.dart';
import 'package:freeplix/data/repositories/tmdb_repository.dart';
import 'package:freeplix/features/home/bloc/home_bloc.dart';
import 'package:freeplix/features/home/widgets/hero_billboard.dart';
import 'package:freeplix/features/watchlist/bloc/watchlist_cubit.dart';
import 'package:freeplix/shell/view/app_footer.dart';
import 'package:freeplix/shell/view/page_padding.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          HomeBloc(repository: context.read<TmdbRepository>())
            ..add(const HomeRequested()),
      child: const HomeView(),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state.status == HomeStatus.failure) {
          return ErrorView(
            message: state.error ?? 'Freeplix could not reach TMDB.',
            onRetry: () => context.read<HomeBloc>().add(const HomeRequested()),
          );
        }

        final featured = state.featured;
        final isLoading =
            state.status == HomeStatus.loading ||
            state.status == HomeStatus.initial;

        return CustomScrollView(
          slivers: [
            if (featured != null)
              SliverToBoxAdapter(
                child: _Spotlight(item: featured, state: state),
              )
            else
              const SliverToBoxAdapter(child: SizedBox(height: Insets.xl)),
            SliverPadding(
              padding: const EdgeInsets.only(top: Insets.xl),
              sliver: SliverList.separated(
                itemCount: isLoading ? 3 : state.rails.length,
                separatorBuilder: (_, _) => const SizedBox(height: Insets.xxl),
                itemBuilder: (context, index) {
                  final rail = isLoading ? null : state.rails[index];
                  return PagePadding(
                    child: MediaRow(
                      title: rail?.title ?? 'Loading',
                      items: rail?.items ?? const [],
                      isLoading: isLoading,
                      onSeeAll: rail?.seeAll == null
                          ? null
                          : () => context.go(rail!.seeAll!),
                      onSelect: (item) => _openTitle(context, item),
                    ),
                  );
                },
              ),
            ),
            const SliverAppFooter(),
          ],
        );
      },
    );
  }
}

class _Spotlight extends StatelessWidget {
  const _Spotlight({required this.item, required this.state});

  final MediaItem item;
  final HomeState state;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WatchlistCubit, WatchlistState>(
      builder: (context, watchlist) => HeroBillboard(
        item: item,
        reelNumber: (state.spotlightIndex % state.spotlight.length) + 1,
        reelCount: state.spotlight.length,
        isSaved: watchlist.contains(item),
        onToggleSave: () => context.read<WatchlistCubit>().toggle(item),
        onAdvance: () =>
            context.read<HomeBloc>().add(const HomeSpotlightAdvanced()),
        onWatch: () => context.go('/watch/${item.type.wire}/${item.id}'),
        onTrailer: () =>
            context.go('/watch/${item.type.wire}/${item.id}?trailer=1'),
        onDetails: () => _openTitle(context, item),
      ),
    );
  }
}

void _openTitle(BuildContext context, MediaItem item) {
  context.go('/title/${item.type.wire}/${item.id}');
}
