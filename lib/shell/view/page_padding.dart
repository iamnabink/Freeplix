import 'package:flutter/material.dart';
import 'package:freeplix/core/theme/app_spacing.dart';

/// The page gutter. Wide screens get room to breathe; phones get their
/// content back.
class PagePadding extends StatelessWidget {
  const PagePadding({required this.child, this.vertical = 0, super.key});

  final Widget child;
  final double vertical;

  static double gutterFor(double width) {
    if (width < Breakpoints.compact) return Insets.md;
    if (width < Breakpoints.medium) return Insets.lg;
    return Insets.xxl;
  }

  @override
  Widget build(BuildContext context) {
    final gutter = gutterFor(MediaQuery.sizeOf(context).width);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: gutter, vertical: vertical),
      child: child,
    );
  }
}
