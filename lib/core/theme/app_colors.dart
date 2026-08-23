import 'package:flutter/material.dart';

/// Freeplix runs on a projection-booth palette: a cool screen in front of you,
/// a warm tungsten lamp behind you. Everything else is the dark of the room.
abstract final class AppColors {
  /// The dark of the room.
  static const ink = Color(0xFF0A0B0D);

  /// Raised surfaces — cards, sheets, the top rail.
  static const soot = Color(0xFF14161A);

  /// Slightly lifted surface for hovered/active chrome.
  static const soot2 = Color(0xFF1B1E24);

  /// Hairlines and borders.
  static const ash = Color(0xFF232830);

  /// Primary text — warm white, like exposed film emulsion.
  static const emulsion = Color(0xFFF4F1EC);

  /// Secondary text — the cool silver of a lit screen.
  static const screen = Color(0xFF97A3B2);

  /// Tertiary text and disabled states.
  static const screenDim = Color(0xFF5C6673);

  /// The projector lamp. Freeplix's one warm accent.
  static const lamp = Color(0xFFFFC24B);

  /// The hot tip of the filament. Live, airing, and error states only.
  static const filament = Color(0xFFFF5E3A);

  /// Success / "in your list".
  static const verdant = Color(0xFF4ADE80);

  /// Warm glow cast by the lamp, for rim lights and focus rings.
  static Color lampGlow(double opacity) => lamp.withValues(alpha: opacity);

  /// The vignette that falls across every backdrop image.
  static const backdropScrim = LinearGradient(
    colors: [
      Color(0xF00A0B0D),
      Color(0xA60A0B0D),
      Color(0x0D0A0B0D),
    ],
    stops: [0, 0.52, 1],
  );

  /// Bottom fade so a backdrop dissolves into the page instead of stopping.
  static const backdropFade = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x000A0B0D),
      Color(0x800A0B0D),
      Color(0xFF0A0B0D),
    ],
    stops: [0.5, 0.84, 1],
  );

  /// Poster placeholder while artwork loads.
  static const posterPlaceholder = Color(0xFF191C21);
}
