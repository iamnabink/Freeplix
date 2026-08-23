import 'package:flutter/material.dart';
import 'package:freeplix/core/theme/app_colors.dart';
import 'package:freeplix/core/theme/app_spacing.dart';
import 'package:freeplix/core/theme/app_typography.dart';
import 'package:freeplix/core/widgets/meta_bar.dart';

/// Something broke. Say what, and give the reader the one move that helps.
class ErrorView extends StatelessWidget {
  const ErrorView({
    required this.message,
    this.onRetry,
    this.compact = false,
    super.key,
  });

  final String message;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _CenteredNotice(
      compact: compact,
      icon: Icons.wifi_tethering_off_rounded,
      iconColor: AppColors.filament,
      eyebrow: 'Signal lost',
      message: message,
      action: onRetry == null
          ? null
          : FilledButton(onPressed: onRetry, child: const Text('Try again')),
    );
  }
}

/// Nothing here yet. Point at the way out.
class EmptyView extends StatelessWidget {
  const EmptyView({
    required this.eyebrow,
    required this.message,
    this.icon = Icons.theaters_outlined,
    this.action,
    this.compact = false,
    super.key,
  });

  final String eyebrow;
  final String message;
  final IconData icon;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _CenteredNotice(
      compact: compact,
      icon: icon,
      iconColor: AppColors.screenDim,
      eyebrow: eyebrow,
      message: message,
      action: action,
    );
  }
}

class _CenteredNotice extends StatelessWidget {
  const _CenteredNotice({
    required this.icon,
    required this.iconColor,
    required this.eyebrow,
    required this.message,
    required this.compact,
    this.action,
  });

  final IconData icon;
  final Color iconColor;
  final String eyebrow;
  final String message;
  final bool compact;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? Insets.lg : Insets.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: compact ? 28 : 36, color: iconColor),
              const SizedBox(height: Insets.md),
              Eyebrow(eyebrow),
              const SizedBox(height: Insets.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyStyle(size: 15),
              ),
              if (action != null) ...[
                const SizedBox(height: Insets.lg),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The lamp warming up.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
