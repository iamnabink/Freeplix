import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freeplix/core/theme/app_colors.dart';
import 'package:freeplix/core/theme/app_spacing.dart';
import 'package:freeplix/core/theme/app_typography.dart';
import 'package:freeplix/core/widgets/net_image.dart';
import 'package:freeplix/data/models/media_item.dart';
import 'package:freeplix/data/models/media_type.dart';
import 'package:freeplix/data/repositories/tmdb_repository.dart';
import 'package:freeplix/features/watchlist/bloc/watchlist_cubit.dart';
import 'package:freeplix/shell/view/page_padding.dart';
import 'package:go_router/go_router.dart';

/// One tracked show with a next episode on the way.
class _Upcoming {
  const _Upcoming({
    required this.item,
    required this.label,
    required this.date,
  });

  final MediaItem item;
  final String label;
  final DateTime date;
}

/// "Coming up" — the next episode of each series in the viewer's list that has
/// one scheduled, soonest first. Quiet until there is something to show.
class UpcomingRow extends HookWidget {
  const UpcomingRow({super.key});

  @override
  Widget build(BuildContext context) {
    // A stable key of the tracked series ids, so the fetch only re-runs when
    // the set of tracked shows actually changes.
    final ids = context.select<WatchlistCubit, String>(
      (cubit) => cubit.state.items
          .where((e) => e.type == MediaType.tv)
          .map((e) => e.id)
          .join(','),
    );
    if (ids.isEmpty) return const SizedBox.shrink();

    final repository = context.read<TmdbRepository>();
    final future = useMemoized(() => _load(repository, ids), [ids]);
    final snapshot = useFuture(future);
    final upcoming = snapshot.data ?? const <_Upcoming>[];
    if (upcoming.isEmpty) return const SizedBox.shrink();

    return PagePadding(
      vertical: Insets.xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Coming up', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: Insets.md),
          SizedBox(
            height: 150 * 1.5 + 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Insets.xxs),
              itemCount: upcoming.length,
              separatorBuilder: (_, _) => const SizedBox(width: Insets.sm),
              itemBuilder: (context, index) =>
                  _UpcomingCard(entry: upcoming[index]),
            ),
          ),
        ],
      ),
    );
  }

  static Future<List<_Upcoming>> _load(
    TmdbRepository repository,
    String ids,
  ) async {
    final tracked = ids
        .split(',')
        .where((s) => s.isNotEmpty)
        .map(int.parse)
        .take(12);

    final results = <_Upcoming>[];
    for (final id in tracked) {
      try {
        final detail = await repository.detail(MediaType.tv, id);
        final date = detail.nextEpisodeAirDate;
        if (date != null) {
          results.add(
            _Upcoming(
              item: detail.asItem,
              label: detail.nextEpisodeLabel ?? '',
              date: date,
            ),
          );
        }
      } on Object catch (_) {
        // Skip a show that failed to load rather than dropping the whole row.
      }
    }
    return results..sort((a, b) => a.date.compareTo(b.date));
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.entry});

  final _Upcoming entry;

  static const _width = 150.0;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () =>
            context.go('/title/${entry.item.type.wire}/${entry.item.id}'),
        child: SizedBox(
          width: _width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.md),
                child: SizedBox(
                  width: _width,
                  height: _width * 1.5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      NetImage(url: entry.item.poster()),
                      Positioned(
                        left: Insets.xs,
                        bottom: Insets.xs,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.lamp,
                            borderRadius: BorderRadius.circular(Radii.sm),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            child: Text(
                              _when(entry.date),
                              style: AppTypography.monoStyle(
                                size: 10,
                                letterSpacing: 0.4,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Insets.xs),
              Text(
                entry.item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyStyle(size: 13.5, weight: 600),
              ),
              const SizedBox(height: 2),
              Text(
                entry.label,
                style: AppTypography.monoStyle(
                  size: 10,
                  color: AppColors.screenDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _when(DateTime date) {
    final now = DateTime.now();
    final day = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    final days = day.difference(today).inDays;
    if (days <= 0) return 'TODAY';
    if (days == 1) return 'TOMORROW';
    if (days < 7) return 'IN $days DAYS';
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
