import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freeplix/core/theme/app_colors.dart';
import 'package:freeplix/core/theme/app_spacing.dart';
import 'package:freeplix/core/theme/app_typography.dart';
import 'package:freeplix/core/widgets/media_grid.dart';
import 'package:freeplix/core/widgets/meta_bar.dart';
import 'package:freeplix/core/widgets/state_views.dart';
import 'package:freeplix/data/repositories/tmdb_repository.dart';
import 'package:freeplix/features/search/bloc/search_cubit.dart';
import 'package:freeplix/shell/view/page_padding.dart';
import 'package:go_router/go_router.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({this.initialQuery = '', super.key});

  final String initialQuery;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SearchCubit(repository: context.read<TmdbRepository>())
            ..query(initialQuery),
      child: SearchView(initialQuery: initialQuery),
    );
  }
}

class SearchView extends HookWidget {
  const SearchView({required this.initialQuery, super.key});

  final String initialQuery;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: initialQuery);
    final focus = useFocusNode();
    final cubit = context.read<SearchCubit>();
    final isCompact =
        MediaQuery.sizeOf(context).width < Breakpoints.compact;

    useEffect(() {
      focus.requestFocus();
      return null;
    }, const []);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: PagePadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: isCompact ? Insets.lg : Insets.xxxl + Insets.md,
                ),
                const Eyebrow('Search the catalogue'),
                const SizedBox(height: Insets.xs),
                Text(
                  'Find something to watch',
                  style: AppTypography.displayStyle(
                    size: isCompact ? 30 : 42,
                  ),
                ),
                const SizedBox(height: Insets.lg),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: TextField(
                    controller: controller,
                    focusNode: focus,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    style: AppTypography.bodyStyle(
                      size: 16,
                      color: AppColors.emulsion,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Title, franchise, or character',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.screenDim,
                        size: 20,
                      ),
                      suffixIcon: controller.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.close_rounded, size: 18),
                              color: AppColors.screenDim,
                              onPressed: () {
                                controller.clear();
                                cubit.query('');
                                focus.requestFocus();
                              },
                            ),
                    ),
                    onChanged: (value) {
                      cubit.query(value);
                      // Keep the address bar in step so results are linkable.
                      context.go(
                        value.trim().isEmpty
                            ? '/search'
                            : '/search?q=${Uri.encodeQueryComponent(value.trim())}',
                      );
                    },
                  ),
                ),
                const SizedBox(height: Insets.xl),
              ],
            ),
          ),
        ),
        const _Results(),
        const SliverToBoxAdapter(child: SizedBox(height: Insets.xxxl)),
      ],
    );
  }
}

class _Results extends StatelessWidget {
  const _Results();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        final gutter = PagePadding.gutterFor(MediaQuery.sizeOf(context).width);
        final padding = EdgeInsets.symmetric(horizontal: gutter);

        return switch (state.status) {
          SearchStatus.idle => const SliverToBoxAdapter(
            child: EmptyView(
              compact: true,
              icon: Icons.search_rounded,
              eyebrow: 'Nothing searched yet',
              message: 'Start typing and results appear as you go.',
            ),
          ),
          SearchStatus.typing ||
          SearchStatus.loading => SliverPadding(
            padding: padding,
            sliver: const MediaGridSkeletonSliver(count: 12),
          ),
          SearchStatus.failure => SliverToBoxAdapter(
            child: ErrorView(
              compact: true,
              message: state.error ?? 'Search failed.',
              onRetry: context.read<SearchCubit>().retry,
            ),
          ),
          SearchStatus.ready when state.results.isEmpty =>
            SliverToBoxAdapter(
              child: EmptyView(
                compact: true,
                eyebrow: 'No matches',
                message:
                    'Nothing in TMDB matches "${state.query}". '
                    'Check the spelling, or try fewer words.',
              ),
            ),
          SearchStatus.ready => SliverPadding(
            padding: padding,
            sliver: MediaGridSliver(
              items: state.results,
              onSelect: (item) =>
                  context.go('/title/${item.type.wire}/${item.id}'),
            ),
          ),
        };
      },
    );
  }
}
