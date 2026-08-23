import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freeplix/core/theme/app_colors.dart';
import 'package:freeplix/core/theme/app_spacing.dart';

/// A slow warm pulse, like a lamp settling. Respects reduced-motion.
class Pulse extends HookWidget {
  const Pulse({
    required this.width,
    required this.height,
    this.radius = Radii.md,
    super.key,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 1200),
    );

    useEffect(() {
      if (!reduced) unawaited(controller.repeat(reverse: true));
      return null;
    }, [reduced]);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Color.lerp(
            AppColors.posterPlaceholder,
            AppColors.soot2,
            reduced ? 0.4 : controller.value,
          ),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class PosterRowSkeleton extends StatelessWidget {
  const PosterRowSkeleton({required this.cardWidth, super.key});

  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: Insets.xxs),
      itemCount: 8,
      separatorBuilder: (_, _) => const SizedBox(width: Insets.sm),
      itemBuilder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Pulse(width: cardWidth, height: cardWidth * 1.5),
          const SizedBox(height: Insets.xs),
          Pulse(width: cardWidth * 0.75, height: 12, radius: Radii.sm),
          const SizedBox(height: 6),
          Pulse(width: cardWidth * 0.4, height: 9, radius: Radii.sm),
        ],
      ),
    );
  }
}
