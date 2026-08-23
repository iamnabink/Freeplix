import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freeplix/core/theme/app_colors.dart';
import 'package:freeplix/core/theme/app_spacing.dart';
import 'package:freeplix/core/theme/app_typography.dart';
import 'package:freeplix/core/widgets/meta_bar.dart';
import 'package:freeplix/core/widgets/net_image.dart';
import 'package:freeplix/data/models/media_item.dart';

/// A title in the gate. Resting, it is a quiet 2:3 poster behind a hairline.
/// Under the pointer it lifts, the hairline warms to the lamp, and its
/// metadata rises from the bottom edge.
class PosterCard extends HookWidget {
  const PosterCard({
    required this.item,
    required this.onTap,
    this.width = 168,
    super.key,
  });

  final MediaItem item;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final hovered = useState(false);
    final focused = useState(false);
    final active = hovered.value || focused.value;

    return Semantics(
      button: true,
      label: '${item.title}, ${item.type.label}, rated ${item.rating}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => hovered.value = true,
        onExit: (_) => hovered.value = false,
        child: Focus(
          onFocusChange: (value) => focused.value = value,
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: Motion.base,
              curve: Curves.easeOutCubic,
              width: width,
              transform: Matrix4.translationValues(0, active ? -6 : 0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: Motion.base,
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Radii.md),
                      border: Border.all(
                        color: active ? AppColors.lamp : AppColors.ash,
                      ),
                      boxShadow: active
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
                      child: AspectRatio(
                        aspectRatio: 2 / 3,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            NetImage(url: item.poster()),
                            _RatingCorner(item: item, visible: active),
                            _PlayVeil(visible: active),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Insets.xs),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyStyle(
                      size: 13.5,
                      weight: 600,
                      color: active ? AppColors.emulsion : AppColors.screen,
                    ),
                  ),
                  const SizedBox(height: 2),
                  MetaBar(
                    entries: [item.year, item.type.label],
                    size: 10,
                    color: AppColors.screenDim,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RatingCorner extends StatelessWidget {
  const _RatingCorner({required this.item, required this.visible});

  final MediaItem item;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: Insets.xs,
      left: Insets.xs,
      child: AnimatedOpacity(
        duration: Motion.fast,
        opacity: visible ? 1 : 0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.ink.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            child: RatingPip(rating: item.rating, size: 10),
          ),
        ),
      ),
    );
  }
}

class _PlayVeil extends StatelessWidget {
  const _PlayVeil({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: Motion.base,
      opacity: visible ? 1 : 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              AppColors.ink.withValues(alpha: 0.75),
            ],
            stops: const [0.45, 1],
          ),
        ),
        child: Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(Insets.xs),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.lamp,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                size: 16,
                color: AppColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
