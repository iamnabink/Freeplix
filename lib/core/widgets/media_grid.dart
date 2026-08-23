import 'package:flutter/material.dart';
import 'package:freeplix/core/theme/app_spacing.dart';
import 'package:freeplix/core/widgets/poster_card.dart';
import 'package:freeplix/core/widgets/skeletons.dart';
import 'package:freeplix/data/models/media_item.dart';

/// A responsive poster grid. Column count follows the available width so
/// posters keep a comfortable size instead of stretching.
class MediaGridSliver extends StatelessWidget {
  const MediaGridSliver({
    required this.items,
    required this.onSelect,
    super.key,
  });

  final List<MediaItem> items;
  final ValueChanged<MediaItem> onSelect;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final metrics = _GridMetrics.of(constraints.crossAxisExtent);
        return SliverGrid.builder(
          gridDelegate: metrics.delegate,
          itemCount: items.length,
          itemBuilder: (context, index) => PosterCard(
            item: items[index],
            width: metrics.cardWidth,
            onTap: () => onSelect(items[index]),
          ),
        );
      },
    );
  }
}

class MediaGridSkeletonSliver extends StatelessWidget {
  const MediaGridSkeletonSliver({this.count = 18, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final metrics = _GridMetrics.of(constraints.crossAxisExtent);
        return SliverGrid.builder(
          gridDelegate: metrics.delegate,
          itemCount: count,
          itemBuilder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Pulse(
                width: metrics.cardWidth,
                height: metrics.cardWidth * 1.5,
              ),
              const SizedBox(height: Insets.xs),
              Pulse(
                width: metrics.cardWidth * 0.7,
                height: 12,
                radius: Radii.sm,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GridMetrics {
  const _GridMetrics(this.columns, this.cardWidth);

  factory _GridMetrics.of(double width) {
    const target = 180.0;
    final columns = (width / target).floor().clamp(2, 8);
    final cardWidth = (width - (columns - 1) * Insets.md) / columns;
    return _GridMetrics(columns, cardWidth);
  }

  final int columns;
  final double cardWidth;

  SliverGridDelegate get delegate => SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: columns,
    crossAxisSpacing: Insets.md,
    mainAxisSpacing: Insets.lg,
    // Poster (2:3) plus the two lines of type beneath it.
    childAspectRatio: cardWidth / (cardWidth * 1.5 + 46),
  );
}
