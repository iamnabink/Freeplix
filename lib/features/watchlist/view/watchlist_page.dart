import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freeplix/core/theme/app_spacing.dart';
import 'package:freeplix/core/theme/app_typography.dart';
import 'package:freeplix/core/widgets/media_grid.dart';
import 'package:freeplix/core/widgets/meta_bar.dart';
import 'package:freeplix/core/widgets/state_views.dart';
import 'package:freeplix/features/watchlist/bloc/watchlist_cubit.dart';
import 'package:freeplix/shell/view/page_padding.dart';
import 'package:go_router/go_router.dart';

class WatchlistPage extends StatelessWidget {
  const WatchlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isCompact =
        MediaQuery.sizeOf(context).width < Breakpoints.compact;

    return BlocBuilder<WatchlistCubit, WatchlistState>(
      builder: (context, state) {
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
                    const Eyebrow('Saved on this device'),
                    const SizedBox(height: Insets.xs),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            'My list',
                            style: AppTypography.displayStyle(
                              size: isCompact ? 34 : 46,
                            ),
                          ),
                        ),
                        if (state.items.isNotEmpty)
                          TextButton(
                            onPressed: () =>
                                context.read<WatchlistCubit>().clear(),
                            child: const Text('Clear list'),
                          ),
                      ],
                    ),
                    const SizedBox(height: Insets.xl),
                  ],
                ),
              ),
            ),
            if (state.items.isEmpty)
              SliverToBoxAdapter(
                child: EmptyView(
                  icon: Icons.bookmark_border_rounded,
                  eyebrow: 'Your list is empty',
                  message:
                      'Save a title from anywhere in Freeplix and it lands '
                      'here. The list stays in this browser — no account, '
                      'no server.',
                  action: FilledButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Browse titles'),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: PagePadding.gutterFor(
                    MediaQuery.sizeOf(context).width,
                  ),
                ),
                sliver: MediaGridSliver(
                  items: state.items,
                  onSelect: (item) =>
                      context.go('/title/${item.type.wire}/${item.id}'),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: Insets.xxxl)),
          ],
        );
      },
    );
  }
}
