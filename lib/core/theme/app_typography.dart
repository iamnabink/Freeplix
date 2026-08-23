import 'package:flutter/material.dart';
import 'package:freeplix/core/theme/app_colors.dart';

/// Three voices: a display face with character, a dense body face, and a
/// mono for anything the projectionist would have written on the can —
/// runtimes, years, reel numbers, ratings.
abstract final class AppTypography {
  static const display = 'BricolageGrotesque';
  static const body = 'InterTight';
  static const mono = 'SpaceMono';

  static List<FontVariation> _wght(double weight) => [
    FontVariation('wght', weight),
  ];

  /// Bricolage is a variable face; weight has to travel as a variation.
  static TextStyle displayStyle({
    required double size,
    double weight = 800,
    double height = 0.98,
    double letterSpacing = -1.6,
    Color color = AppColors.emulsion,
  }) {
    return TextStyle(
      fontFamily: display,
      fontSize: size,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
      fontVariations: [
        FontVariation('wght', weight),
        const FontVariation('wdth', 100),
        const FontVariation('opsz', 24),
      ],
    );
  }

  static TextStyle bodyStyle({
    required double size,
    double weight = 400,
    double height = 1.5,
    double letterSpacing = 0,
    Color color = AppColors.screen,
  }) {
    return TextStyle(
      fontFamily: body,
      fontSize: size,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
      fontVariations: _wght(weight),
    );
  }

  /// Small caps-ish utility type for data. Space Mono ships static weights.
  static TextStyle monoStyle({
    double size = 11,
    FontWeight weight = FontWeight.w400,
    double letterSpacing = 1.4,
    Color color = AppColors.screen,
  }) {
    return TextStyle(
      fontFamily: mono,
      fontSize: size,
      height: 1.2,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  static TextTheme get textTheme => TextTheme(
    displayLarge: displayStyle(size: 72),
    displayMedium: displayStyle(size: 56),
    displaySmall: displayStyle(size: 40, letterSpacing: -1.2),
    headlineLarge: displayStyle(size: 32, weight: 700, letterSpacing: -0.8),
    headlineMedium: displayStyle(size: 24, weight: 700, letterSpacing: -0.5),
    headlineSmall: displayStyle(size: 19, weight: 700, letterSpacing: -0.3),
    titleLarge: bodyStyle(size: 17, weight: 600, color: AppColors.emulsion),
    titleMedium: bodyStyle(size: 15, weight: 600, color: AppColors.emulsion),
    titleSmall: bodyStyle(size: 13, weight: 600, color: AppColors.emulsion),
    bodyLarge: bodyStyle(size: 16),
    bodyMedium: bodyStyle(size: 14),
    bodySmall: bodyStyle(size: 13, color: AppColors.screenDim),
    labelLarge: bodyStyle(size: 14, weight: 600, color: AppColors.emulsion),
    labelMedium: monoStyle(),
    labelSmall: monoStyle(size: 10),
  );
}
