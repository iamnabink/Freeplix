import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freeplix/core/config/app_config.dart';
import 'package:freeplix/core/theme/app_colors.dart';
import 'package:freeplix/core/theme/app_spacing.dart';
import 'package:freeplix/core/theme/app_typography.dart';
import 'package:freeplix/core/widgets/meta_bar.dart';
import 'package:freeplix/core/widgets/sprocket_rail.dart';
import 'package:freeplix/core/widgets/wordmark.dart';
import 'package:freeplix/shell/view/page_padding.dart';
import 'package:url_launcher/url_launcher.dart';

/// The tail of the reel. Every scrolling page ends here.
class SliverAppFooter extends StatelessWidget {
  const SliverAppFooter({super.key});

  @override
  Widget build(BuildContext context) =>
      const SliverToBoxAdapter(child: AppFooter());
}

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < Breakpoints.compact;

    return Padding(
      padding: const EdgeInsets.only(top: Insets.xxxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SprocketRail(lit: false),
          Container(
            width: double.infinity,
            color: AppColors.soot.withValues(alpha: 0.4),
            child: PagePadding(
              vertical: Insets.xl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isCompact)
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Identity(),
                        SizedBox(height: Insets.lg),
                        _Links(),
                      ],
                    )
                  else
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _Identity()),
                        _Links(),
                      ],
                    ),
                  const SizedBox(height: Insets.xl),
                  const Divider(),
                  const SizedBox(height: Insets.md),
                  const _Attribution(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Wordmark(size: 20),
        const SizedBox(height: Insets.xs),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(
            'An open source catalogue for films and series, built for '
            'learning. MIT licensed, with no accounts and no tracking.',
            style: AppTypography.bodyStyle(size: 13.5),
          ),
        ),
        const SizedBox(height: Insets.md),
        const Row(
          children: [
            Eyebrow('Built by'),
            SizedBox(width: Insets.xs),
            _TextLink(
              label: AppConfig.authorName,
              url: AppConfig.authorUrl,
            ),
          ],
        ),
      ],
    );
  }
}

class _Links extends StatelessWidget {
  const _Links();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: Insets.sm,
      runSpacing: Insets.sm,
      children: [
        _ActionLink(
          label: 'Star on GitHub',
          icon: Icons.star_rounded,
          url: AppConfig.repositoryUrl,
          emphasis: true,
        ),
        _ActionLink(
          label: '@${AppConfig.authorHandle}',
          icon: Icons.person_outline_rounded,
          url: AppConfig.authorUrl,
        ),
      ],
    );
  }
}

class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Insets.md,
      runSpacing: Insets.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppConfig.purposeNotice,
                style: AppTypography.monoStyle(
                  size: 10,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 5),
              // Wording required by TMDB's terms of use.
              Text(
                AppConfig.tmdbAttribution,
                style: AppTypography.monoStyle(
                  size: 10,
                  letterSpacing: 0.8,
                  color: AppColors.screenDim,
                ),
              ),
            ],
          ),
        ),
        const _TextLink(
          label: 'MIT licence',
          url: '${AppConfig.repositoryUrl}/blob/main/LICENSE',
          small: true,
        ),
      ],
    );
  }
}

class _ActionLink extends HookWidget {
  const _ActionLink({
    required this.label,
    required this.icon,
    required this.url,
    this.emphasis = false,
  });

  final String label;
  final IconData icon;
  final String url;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final hovered = useState(false);

    return Semantics(
      link: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => hovered.value = true,
        onExit: (_) => hovered.value = false,
        child: GestureDetector(
          onTap: () => _open(url),
          child: AnimatedContainer(
            duration: Motion.fast,
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.sm,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: emphasis && hovered.value
                  ? AppColors.lamp
                  : AppColors.soot,
              borderRadius: BorderRadius.circular(Radii.sm),
              border: Border.all(
                color: emphasis || hovered.value
                    ? AppColors.lamp
                    : AppColors.ash,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: emphasis && hovered.value
                      ? AppColors.ink
                      : AppColors.lamp,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTypography.bodyStyle(
                    size: 13,
                    weight: 600,
                    color: emphasis && hovered.value
                        ? AppColors.ink
                        : AppColors.emulsion,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TextLink extends HookWidget {
  const _TextLink({
    required this.label,
    required this.url,
    this.small = false,
  });

  final String label;
  final String url;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final hovered = useState(false);

    return Semantics(
      link: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => hovered.value = true,
        onExit: (_) => hovered.value = false,
        child: GestureDetector(
          onTap: () => _open(url),
          child: Text(
            label,
            style: small
                ? AppTypography.monoStyle(
                    size: 10,
                    letterSpacing: 0.8,
                    color: hovered.value ? AppColors.lamp : AppColors.screenDim,
                  )
                : AppTypography.bodyStyle(
                    size: 13,
                    weight: 600,
                    color: hovered.value ? AppColors.lamp : AppColors.emulsion,
                  ),
          ),
        ),
      ),
    );
  }
}

void _open(String url) => unawaited(
  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
);
