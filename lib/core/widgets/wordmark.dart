import 'package:flutter/material.dart';
import 'package:freeplix/core/theme/app_colors.dart';
import 'package:freeplix/core/theme/app_typography.dart';

/// FREEPLIX, with the lamp burning through the middle of the word.
class Wordmark extends StatelessWidget {
  const Wordmark({this.size = 22, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final base = AppTypography.displayStyle(
      size: size,
      letterSpacing: -0.4,
    );

    return Semantics(
      label: 'Freeplix, home',
      child: ExcludeSemantics(
        child: RichText(
          text: TextSpan(
            style: base,
            children: [
              const TextSpan(text: 'FREE'),
              TextSpan(
                text: 'P',
                style: base.copyWith(color: AppColors.lamp),
              ),
              const TextSpan(text: 'LIX'),
            ],
          ),
        ),
      ),
    );
  }
}
