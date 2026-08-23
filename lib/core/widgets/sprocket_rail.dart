import 'package:flutter/material.dart';
import 'package:freeplix/core/theme/app_colors.dart';
import 'package:freeplix/core/theme/app_spacing.dart';

/// Freeplix's signature: every carousel sits between two strips of film
/// perforation, so a row of titles reads as a length of film running through
/// a gate. The perforations warm toward the lamp when the row has focus.
class SprocketRail extends StatelessWidget {
  const SprocketRail({required this.lit, super.key});

  final bool lit;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Motion.slow,
      curve: Curves.easeOut,
      tween: Tween(begin: 0, end: lit ? 1 : 0),
      builder: (context, warmth, _) => CustomPaint(
        painter: _SprocketPainter(warmth: warmth),
        size: const Size.fromHeight(_SprocketPainter.railHeight),
        child: const SizedBox(
          height: _SprocketPainter.railHeight,
          width: double.infinity,
        ),
      ),
    );
  }
}

class _SprocketPainter extends CustomPainter {
  const _SprocketPainter({required this.warmth});

  static const railHeight = 9.0;
  static const _holeWidth = 11.0;
  static const _holeHeight = 5.0;
  static const _gap = 13.0;

  final double warmth;

  @override
  void paint(Canvas canvas, Size size) {
    final color = Color.lerp(
      AppColors.ash,
      AppColors.lampGlow(0.55),
      warmth,
    )!;
    final paint = Paint()..color = color;

    const pitch = _holeWidth + _gap;
    final count = (size.width / pitch).ceil();
    const top = (railHeight - _holeHeight) / 2;

    for (var i = 0; i < count; i++) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(i * pitch, top, _holeWidth, _holeHeight),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_SprocketPainter oldDelegate) =>
      oldDelegate.warmth != warmth;
}
