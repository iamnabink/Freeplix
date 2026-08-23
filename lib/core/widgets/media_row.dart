import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freeplix/core/theme/app_colors.dart';
import 'package:freeplix/core/theme/app_spacing.dart';
import 'package:freeplix/core/widgets/poster_card.dart';
import 'package:freeplix/core/widgets/skeletons.dart';
import 'package:freeplix/core/widgets/sprocket_rail.dart';
import 'package:freeplix/data/models/media_item.dart';

/// A length of film running through the gate: perforation rails top and
/// bottom, titles between them, and a nudge control at each end.
class MediaRow extends HookWidget {
  const MediaRow({
    required this.title,
    required this.items,
    required this.onSelect,
    this.isLoading = false,
    this.onSeeAll,
    this.cardWidth = 168,
    super.key,
  });

  final String title;
  final List<MediaItem> items;
  final ValueChanged<MediaItem> onSelect;
  final bool isLoading;
  final VoidCallback? onSeeAll;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    final controller = useScrollController();
    final hovered = useState(false);

    if (!isLoading && items.isEmpty) return const SizedBox.shrink();

    void nudge(int direction) {
      final delta = (cardWidth + Insets.sm) * 3 * direction;
      unawaited(
        controller.animateTo(
          (controller.offset + delta).clamp(
            0,
            controller.position.maxScrollExtent,
          ),
          duration: Motion.slow,
          curve: Curves.easeOutCubic,
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => hovered.value = true,
      onExit: (_) => hovered.value = false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RowHeader(
            title: title,
            onSeeAll: onSeeAll,
            showControls: hovered.value && !isLoading,
            onNudge: nudge,
          ),
          const SizedBox(height: Insets.sm),
          SprocketRail(lit: hovered.value),
          const SizedBox(height: Insets.sm),
          SizedBox(
            height: cardWidth * 1.5 + 46,
            child: isLoading
                ? PosterRowSkeleton(cardWidth: cardWidth)
                : ListView.separated(
                    controller: controller,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: Insets.xxs,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: Insets.sm),
                    itemBuilder: (context, index) => PosterCard(
                      item: items[index],
                      width: cardWidth,
                      onTap: () => onSelect(items[index]),
                    ),
                  ),
          ),
          const SizedBox(height: Insets.sm),
          SprocketRail(lit: hovered.value),
        ],
      ),
    );
  }
}

class _RowHeader extends StatelessWidget {
  const _RowHeader({
    required this.title,
    required this.onSeeAll,
    required this.showControls,
    required this.onNudge,
  });

  final String title;
  final VoidCallback? onSeeAll;
  final bool showControls;
  final ValueChanged<int> onNudge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onSeeAll != null) ...[
          const SizedBox(width: Insets.sm),
          TextButton(onPressed: onSeeAll, child: const Text('See all')),
        ],
        const Spacer(),
        AnimatedOpacity(
          duration: Motion.fast,
          opacity: showControls ? 1 : 0,
          child: Row(
            children: [
              _NudgeButton(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Scroll left',
                onPressed: showControls ? () => onNudge(-1) : null,
              ),
              const SizedBox(width: Insets.xxs),
              _NudgeButton(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Scroll right',
                onPressed: showControls ? () => onNudge(1) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NudgeButton extends StatelessWidget {
  const _NudgeButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        iconSize: 20,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          foregroundColor: AppColors.screen,
          backgroundColor: AppColors.soot,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sm),
            side: const BorderSide(color: AppColors.ash),
          ),
        ),
        icon: Icon(icon),
      ),
    );
  }
}
