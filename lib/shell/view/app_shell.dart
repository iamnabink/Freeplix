import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freeplix/core/theme/app_colors.dart';
import 'package:freeplix/core/theme/app_spacing.dart';
import 'package:freeplix/core/theme/app_typography.dart';
import 'package:freeplix/core/widgets/wordmark.dart';
import 'package:freeplix/shell/view/page_padding.dart';
import 'package:go_router/go_router.dart';

/// The height the shell's header occupies, published so pages can clear it
/// instead of hard-coding a number that drifts out of date.
class ShellChrome extends InheritedWidget {
  const ShellChrome({
    required this.headerHeight,
    required super.child,
    super.key,
  });

  final double headerHeight;

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellChrome>()?.headerHeight ??
      0;

  @override
  bool updateShouldNotify(ShellChrome oldWidget) =>
      oldWidget.headerHeight != headerHeight;
}

class NavDestination {
  const NavDestination(this.label, this.path, this.icon);

  final String label;
  final String path;
  final IconData icon;
}

const navDestinations = [
  NavDestination('Home', '/', Icons.home_rounded),
  NavDestination('Films', '/movies', Icons.movie_rounded),
  NavDestination('Series', '/series', Icons.live_tv_rounded),
  NavDestination('My list', '/list', Icons.bookmark_rounded),
];

/// Persistent chrome. On wide screens the navigation lives in a top rail that
/// stays transparent over the hero until the reader scrolls; on phones it
/// drops to a bottom bar so titles keep the full width.
class AppShell extends HookWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scrolled = useState(false);
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < Breakpoints.compact;
    final location = GoRouterState.of(context).uri.path;

    // Status bar inset plus the bar's own content height.
    final headerHeight =
        MediaQuery.paddingOf(context).top + (isCompact ? 52.0 : 58.0);

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: NotificationListener<ScrollUpdateNotification>(
        onNotification: (notification) {
          if (notification.depth != 0) return false;
          final next = notification.metrics.pixels > 24;
          if (next != scrolled.value) scrolled.value = next;
          return false;
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: ShellChrome(headerHeight: headerHeight, child: child),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: isCompact
                  ? _CompactBar(scrolled: scrolled.value)
                  : _TopRail(scrolled: scrolled.value, location: location),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isCompact ? _BottomBar(location: location) : null,
      floatingActionButton: isCompact
          ? FloatingActionButton.small(
              onPressed: () => context.go('/search'),
              backgroundColor: AppColors.lamp,
              foregroundColor: AppColors.ink,
              tooltip: 'Search',
              child: const Icon(Icons.search_rounded),
            )
          : null,
    );
  }
}

/// Phones get the wordmark and search; navigation lives in the bottom bar.
/// Transparent over a hero until the reader scrolls, like the wide rail.
class _CompactBar extends StatelessWidget {
  const _CompactBar({required this.scrolled});

  final bool scrolled;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Motion.base,
      decoration: BoxDecoration(
        color: scrolled
            ? AppColors.ink.withValues(alpha: 0.94)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: scrolled ? AppColors.ash : Colors.transparent,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.md,
            vertical: Insets.xs,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.go('/'),
                child: const Wordmark(size: 19),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Search Freeplix',
                onPressed: () => context.go('/search'),
                icon: const Icon(Icons.search_rounded, size: 22),
                color: AppColors.screen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopRail extends StatelessWidget {
  const _TopRail({required this.scrolled, required this.location});

  final bool scrolled;
  final String location;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Motion.base,
      decoration: BoxDecoration(
        color: scrolled
            ? AppColors.ink.withValues(alpha: 0.94)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: scrolled ? AppColors.ash : Colors.transparent,
          ),
        ),
      ),
      child: PagePadding(
        vertical: Insets.sm,
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              _WordmarkLink(),
              const SizedBox(width: Insets.xl),
              for (final destination in navDestinations)
                _RailLink(
                  destination: destination,
                  active: _isActive(destination.path, location),
                ),
              const Spacer(),
              _SearchAffordance(active: location.startsWith('/search')),
            ],
          ),
        ),
      ),
    );
  }
}

class _WordmarkLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Freeplix, go to home',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => context.go('/'),
          child: const Wordmark(),
        ),
      ),
    );
  }
}

class _RailLink extends HookWidget {
  const _RailLink({required this.destination, required this.active});

  final NavDestination destination;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final hovered = useState(false);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => hovered.value = true,
      onExit: (_) => hovered.value = false,
      child: GestureDetector(
        onTap: () => context.go(destination.path),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.sm,
            vertical: Insets.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                destination.label,
                style: AppTypography.bodyStyle(
                  size: 14.5,
                  weight: active ? 600 : 500,
                  color: active || hovered.value
                      ? AppColors.emulsion
                      : AppColors.screen,
                ),
              ),
              const SizedBox(height: 5),
              AnimatedContainer(
                duration: Motion.fast,
                height: 2,
                width: active ? 18 : 0,
                color: AppColors.lamp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchAffordance extends StatelessWidget {
  const _SearchAffordance({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Search Freeplix',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => context.go('/search'),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.sm,
              vertical: Insets.xs + 1,
            ),
            decoration: BoxDecoration(
              color: AppColors.soot.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(Radii.sm),
              border: Border.all(
                color: active ? AppColors.lamp : AppColors.ash,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.search_rounded,
                  size: 17,
                  color: AppColors.screen,
                ),
                const SizedBox(width: Insets.xs),
                Text(
                  'Search titles',
                  style: AppTypography.bodyStyle(
                    size: 13.5,
                    color: AppColors.screenDim,
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

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.soot,
        border: Border(top: BorderSide(color: AppColors.ash)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              for (final destination in navDestinations)
                Expanded(
                  child: _BottomItem(
                    destination: destination,
                    active: _isActive(destination.path, location),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({required this.destination, required this.active});

  final NavDestination destination;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.lamp : AppColors.screenDim;

    return Semantics(
      button: true,
      selected: active,
      label: destination.label,
      child: InkWell(
        onTap: () => context.go(destination.path),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(destination.icon, size: 21, color: color),
            const SizedBox(height: 3),
            Text(
              destination.label,
              style: AppTypography.monoStyle(
                size: 9,
                letterSpacing: 0.6,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _isActive(String path, String location) {
  if (path == '/') return location == '/';
  return location.startsWith(path);
}
