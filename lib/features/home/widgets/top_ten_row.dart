import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freeplix/core/theme/app_colors.dart';
import 'package:freeplix/core/theme/app_spacing.dart';
import 'package:freeplix/core/theme/app_typography.dart';
import 'package:freeplix/core/widgets/meta_bar.dart';
import 'package:freeplix/core/widgets/net_image.dart';
import 'package:freeplix/core/widgets/sprocket_rail.dart';
import 'package:freeplix/data/models/media_item.dart';
import 'package:freeplix/data/repositories/tmdb_repository.dart';
import 'package:freeplix/features/watchlist/bloc/watched_cubit.dart';
import 'package:freeplix/shell/view/page_padding.dart';
import 'package:go_router/go_router.dart';

/// The day's ten most trending titles, ranked — each poster rides in front of
/// a big ghosted numeral, the way a chart should read at a glance.
class TopTenRow extends HookWidget {
  const TopTenRow({super.key});

  static const double _posterWidth = 132;
  static const double _posterHeight = _posterWidth * 1.5;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<TmdbRepository>();
    final future = useMemoized(() => repository.trending(window: 'day'));
    final snapshot = useFuture(future);

    final items =
        snapshot.data?.items
            .where((e) => e.posterPath != null)
            .take(10)
            .toList() ??
        const <MediaItem>[];
    if (items.length < 5) return const SizedBox.shrink();

    final hovered = useState(false);

    return PagePadding(
      vertical: Insets.xl,
      child: MouseRegion(
        onEnter: (_) => hovered.value = true,
        onExit: (_) => hovered.value = false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top 10 today',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: Insets.sm),
            SprocketRail(lit: hovered.value),
            const SizedBox(height: Insets.md),
            SizedBox(
              height: _posterHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Insets.xxs),
                itemCount: items.length,
                // Wide enough for the next card's numeral, which bleeds left
                // into this gap.
                separatorBuilder: (_, _) => const SizedBox(width: 80),
                itemBuilder: (context, index) => _RankedCard(
                  rank: index + 1,
                  item: items[index],
                  posterWidth: _posterWidth,
                  posterHeight: _posterHeight,
                  onTap: () => context.go(
                    '/title/${items[index].type.wire}/${items[index].id}',
                  ),
                ),
              ),
            ),
            const SizedBox(height: Insets.md),
            SprocketRail(lit: hovered.value),
          ],
        ),
      ),
    );
  }
}

class _RankedCard extends HookWidget {
  const _RankedCard({
    required this.rank,
    required this.item,
    required this.posterWidth,
    required this.posterHeight,
    required this.onTap,
  });

  final int rank;
  final MediaItem item;
  final double posterWidth;
  final double posterHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hovered = useState(false);
    final watched = context.select<WatchedCubit, bool>(
      (cubit) => cubit.state.contains(item),
    );

    final digits = '$rank';
    // The poster covers the numeral's right edge by [overlap]; the rest of the
    // numeral bleeds out to the left (Clip.none), so the poster itself lines up
    // with the first poster of every other row instead of being pushed in.
    const overlap = 46.0;

    return Semantics(
      button: true,
      label: 'Number $rank, ${item.title}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => hovered.value = true,
        onExit: (_) => hovered.value = false,
        child: GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: posterWidth,
            height: posterHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: posterWidth - overlap,
                  bottom: 0,
                  child: _RankNumeral(digits: digits, fontSize: posterHeight),
                ),
                AnimatedContainer(
                  duration: Motion.base,
                  curve: Curves.easeOutCubic,
                  transform: Matrix4.translationValues(
                    0,
                    hovered.value ? -6 : 0,
                    0,
                  ),
                  width: posterWidth,
                  height: posterHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Radii.md),
                    border: Border.all(
                      color: hovered.value ? AppColors.lamp : AppColors.ash,
                    ),
                    boxShadow: hovered.value
                        ? [
                            BoxShadow(
                              color: AppColors.lampGlow(0.18),
                              blurRadius: 28,
                              spreadRadius: -4,
                              offset: const Offset(0, 10),
                            ),
                          ]
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Radii.md - 1),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        NetImage(url: item.poster()),
                        if (watched)
                          ColoredBox(
                            color: AppColors.ink.withValues(alpha: 0.5),
                          ),
                        _CardInfo(item: item),
                        if (watched)
                          Positioned(
                            top: Insets.xs,
                            right: Insets.xs,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.lamp,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 12,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                      ],
                    ),
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

/// The scrim, title and rating/year/genre laid over a poster, so a card is
/// judgeable at a glance without opening it.
class _CardInfo extends StatelessWidget {
  const _CardInfo({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    final genre = _firstGenre(item.genreIds) ?? item.type.label;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0xF00A0B0D)],
          stops: [0.4, 1],
        ),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.all(Insets.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyStyle(
                  size: 12,
                  weight: 700,
                  height: 1.15,
                  color: AppColors.emulsion,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (item.rating != '—') ...[
                    RatingPip(rating: item.rating, size: 9),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: MetaBar(entries: [genre], size: 9),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// First recognisable genre name for [ids], or null. Covers the common TMDB
/// movie and TV genre ids.
String? _firstGenre(List<int> ids) {
  for (final id in ids) {
    final name = _genreNames[id];
    if (name != null) return name;
  }
  return null;
}

const _genreNames = <int, String>{
  28: 'Action',
  12: 'Adventure',
  16: 'Animation',
  35: 'Comedy',
  80: 'Crime',
  99: 'Documentary',
  18: 'Drama',
  10751: 'Family',
  14: 'Fantasy',
  36: 'History',
  27: 'Horror',
  10402: 'Music',
  9648: 'Mystery',
  10749: 'Romance',
  878: 'Sci-Fi',
  53: 'Thriller',
  10752: 'War',
  37: 'Western',
  10759: 'Action',
  10762: 'Kids',
  10763: 'News',
  10764: 'Reality',
  10765: 'Sci-Fi',
  10766: 'Soap',
  10767: 'Talk',
  10768: 'War',
};

/// A big rank numeral: a faint body filled with a lifted grey, outlined by a
/// hairline so it reads as a ghost behind the poster rather than a solid slab.
class _RankNumeral extends StatelessWidget {
  const _RankNumeral({required this.digits, required this.fontSize});

  final String digits;
  final double fontSize;

  TextStyle _style({Color? color, Paint? foreground}) => TextStyle(
    fontFamily: AppTypography.display,
    fontSize: fontSize,
    height: 1,
    letterSpacing: -6,
    color: color,
    foreground: foreground,
    fontVariations: const [
      FontVariation('wght', 800),
      FontVariation('wdth', 100),
    ],
  );

  @override
  Widget build(BuildContext context) {
    // Shrink-wraps its glyph so the enclosing Positioned can place it precisely.
    return Stack(
      children: [
        Text(digits, style: _style(color: AppColors.soot2)),
        Text(
          digits,
          style: _style(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..strokeJoin = StrokeJoin.round
              ..color = AppColors.ash,
          ),
        ),
      ],
    );
  }
}
