import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freeplix/core/theme/app_spacing.dart';
import 'package:freeplix/core/widgets/media_row.dart';
import 'package:freeplix/data/models/media_item.dart';
import 'package:freeplix/data/repositories/tmdb_repository.dart';
import 'package:freeplix/features/watchlist/bloc/watchlist_cubit.dart';
import 'package:freeplix/shell/view/page_padding.dart';
import 'package:go_router/go_router.dart';

/// "Because you added …" — recommendations seeded from the newest title in
/// the viewer's list. Local and quiet: nothing shows until there is a list,
/// or when TMDB has too few recommendations to fill a row.
class RecommendedRow extends HookWidget {
  const RecommendedRow({super.key});

  @override
  Widget build(BuildContext context) {
    final seed = context.select<WatchlistCubit, MediaItem?>(
      (cubit) => cubit.state.items.isEmpty ? null : cubit.state.items.first,
    );
    if (seed == null) return const SizedBox.shrink();

    final repository = context.read<TmdbRepository>();
    final future = useMemoized(
      () => repository.recommendations(seed.type, seed.id),
      [seed.type, seed.id],
    );
    final snapshot = useFuture(future);
    final items = snapshot.data?.items ?? const [];
    if (items.length < 3) return const SizedBox.shrink();

    return PagePadding(
      vertical: Insets.xl,
      child: MediaRow(
        title: 'Because you added ${seed.title}',
        items: items,
        onSelect: (item) => context.go('/title/${item.type.wire}/${item.id}'),
      ),
    );
  }
}
