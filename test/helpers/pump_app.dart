import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freeplix/core/theme/app_theme.dart';
import 'package:freeplix/l10n/l10n.dart';

extension PumpApp on WidgetTester {
  /// Pumps [widget] inside Freeplix's real theme so widget tests exercise the
  /// same colours and type the app ships with.
  Future<void> pumpApp(Widget widget, {Size? surfaceSize}) async {
    if (surfaceSize != null) {
      await binding.setSurfaceSize(surfaceSize);
      addTearDown(() => binding.setSurfaceSize(null));
    }

    return pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: widget),
      ),
    );
  }
}
