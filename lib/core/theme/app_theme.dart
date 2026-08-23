import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freeplix/core/theme/app_colors.dart';
import 'package:freeplix/core/theme/app_spacing.dart';
import 'package:freeplix/core/theme/app_typography.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.lamp,
      onPrimary: AppColors.ink,
      secondary: AppColors.filament,
      onSecondary: AppColors.emulsion,
      surface: AppColors.ink,
      onSurface: AppColors.emulsion,
      surfaceContainer: AppColors.soot,
      surfaceContainerHigh: AppColors.soot2,
      outline: AppColors.ash,
      outlineVariant: AppColors.ash,
      error: AppColors.filament,
      onError: AppColors.ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.ink,
      canvasColor: AppColors.ink,
      textTheme: AppTypography.textTheme,
      fontFamily: AppTypography.body,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      dividerTheme: const DividerThemeData(
        color: AppColors.ash,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      scrollbarTheme: const ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(AppColors.ash),
        thickness: WidgetStatePropertyAll(6),
        radius: Radius.circular(Radii.pill),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.soot2,
          borderRadius: BorderRadius.circular(Radii.sm),
          border: Border.all(color: AppColors.ash),
        ),
        textStyle: AppTypography.monoStyle(
          color: AppColors.emulsion,
        ),
        waitDuration: const Duration(milliseconds: 500),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.lamp,
          foregroundColor: AppColors.ink,
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.lg,
            vertical: Insets.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
          textStyle: AppTypography.bodyStyle(
            size: 15,
            weight: 600,
            color: AppColors.ink,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.emulsion,
          side: const BorderSide(color: AppColors.ash),
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.lg,
            vertical: Insets.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
          textStyle: AppTypography.bodyStyle(
            size: 15,
            weight: 600,
            color: AppColors.emulsion,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lamp,
          textStyle: AppTypography.bodyStyle(size: 14, weight: 600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.soot,
        hintStyle: AppTypography.bodyStyle(
          size: 15,
          color: AppColors.screenDim,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Insets.md,
          vertical: Insets.sm,
        ),
        border: _inputBorder(AppColors.ash),
        enabledBorder: _inputBorder(AppColors.ash),
        focusedBorder: _inputBorder(AppColors.lamp),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.soot,
        side: const BorderSide(color: AppColors.ash),
        labelStyle: AppTypography.monoStyle(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.lamp,
        linearTrackColor: AppColors.ash,
        circularTrackColor: AppColors.ash,
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(Radii.sm),
    borderSide: BorderSide(color: color),
  );
}
