import 'package:flutter/material.dart';
import 'package:freeplix/core/theme/app_colors.dart';
import 'package:freeplix/core/theme/app_spacing.dart';
import 'package:freeplix/core/theme/app_typography.dart';

/// Year · runtime · rating, set in the mono face — the way it would be
/// written on the can.
class MetaBar extends StatelessWidget {
  const MetaBar({
    required this.entries,
    this.size = 11,
    this.color = AppColors.screen,
    super.key,
  });

  final List<String> entries;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final visible = entries.where((e) => e.trim().isNotEmpty).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.xs),
              child: Text(
                '·',
                style: AppTypography.monoStyle(
                  size: size,
                  color: AppColors.screenDim,
                ),
              ),
            ),
          Text(
            visible[i],
            style: AppTypography.monoStyle(size: size, color: color),
          ),
        ],
      ],
    );
  }
}

/// A rating rendered as a lamp-lit pip. Used on posters and hero blocks.
class RatingPip extends StatelessWidget {
  const RatingPip({required this.rating, this.size = 11, super.key});

  final String rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (rating == '—') return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: size + 4, color: AppColors.lamp),
        const SizedBox(width: 3),
        Text(
          rating,
          style: AppTypography.monoStyle(
            size: size,
            weight: FontWeight.w700,
            color: AppColors.emulsion,
          ),
        ),
      ],
    );
  }
}

/// Eyebrow label — mono, tracked wide, dim. Marks a section without shouting.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {this.color = AppColors.screenDim, super.key});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTypography.monoStyle(
        size: 10,
        letterSpacing: 2.4,
        color: color,
      ),
    );
  }
}
