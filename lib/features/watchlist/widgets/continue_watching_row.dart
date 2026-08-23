import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freeplix/core/theme/app_colors.dart';
import 'package:freeplix/core/theme/app_spacing.dart';
import 'package:freeplix/core/theme/app_typography.dart';
import 'package:freeplix/core/widgets/meta_bar.dart';
import 'package:freeplix/core/widgets/net_image.dart';
import 'package:freeplix/core/widgets/sprocket_rail.dart';
import 'package:freeplix/data/models/watch_progress.dart';
import 'package:freeplix/features/watchlist/bloc/continue_watching_cubit.dart';
import 'package:go_router/go_router.dart';

/// Titles the reader opened in the player, offered back. Landscape cards,
/// because these are things already begun rather than things to browse.
class ContinueWatchingRow extends HookWidget {
  const ContinueWatchingRow({super.key});

  static const _cardWidth = 268.0;

  @override
  Widget build(BuildContext context) {
    final hovered = useState(false);

    return BlocBuilder<ContinueWatchingCubit, ContinueWatchingState>(
      builder: (context, state) {
        if (state.entries.isEmpty) return const SizedBox.shrink();

        return MouseRegion(
          onEnter: (_) => hovered.value = true,
          onExit: (_) => hovered.value = false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Jump back in',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: context.read<ContinueWatchingCubit>().clear,
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: Insets.sm),
              SprocketRail(lit: hovered.value),
              const SizedBox(height: Insets.sm),
              SizedBox(
                height: _cardWidth * 9 / 16 + 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: Insets.xxs),
                  itemCount: state.entries.length,
                  separatorBuilder: (_, _) => const SizedBox(width: Insets.sm),
                  itemBuilder: (context, index) =>
                      _ResumeCard(entry: state.entries[index]),
                ),
              ),
              const SizedBox(height: Insets.sm),
              SprocketRail(lit: hovered.value),
            ],
          ),
        );
      },
    );
  }
}

class _ResumeCard extends HookWidget {
  const _ResumeCard({required this.entry});

  final WatchProgress entry;

  @override
  Widget build(BuildContext context) {
    final hovered = useState(false);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => hovered.value = true,
      onExit: (_) => hovered.value = false,
      child: GestureDetector(
        onTap: () => context.go(entry.watchRoute),
        child: SizedBox(
          width: ContinueWatchingRow._cardWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: Motion.base,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: Border.all(
                    color: hovered.value ? AppColors.lamp : AppColors.ash,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.md - 1),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        NetImage(
                          url: entry.asItem.backdrop() ?? entry.asItem.poster(),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Color(0xCC0A0B0D),
                              ],
                              stops: [0.5, 1],
                            ),
                          ),
                        ),
                        Center(
                          child: AnimatedScale(
                            duration: Motion.base,
                            scale: hovered.value ? 1 : 0.85,
                            child: Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: AppColors.lamp.withValues(
                                  alpha: hovered.value ? 1 : 0.85,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                size: 22,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: _RemoveButton(entry: entry),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Insets.xs),
              Text(
                entry.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyStyle(
                  size: 13.5,
                  weight: 600,
                  color: hovered.value ? AppColors.emulsion : AppColors.screen,
                ),
              ),
              const SizedBox(height: 2),
              MetaBar(
                size: 10,
                color: AppColors.screenDim,
                entries: [
                  if (entry.episodeLabel != null) entry.episodeLabel!,
                  entry.type.label,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.entry});

  final WatchProgress entry;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Remove from this row',
      child: IconButton(
        onPressed: () =>
            context.read<ContinueWatchingCubit>().remove(entry),
        iconSize: 15,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.ink.withValues(alpha: 0.7),
          foregroundColor: AppColors.screen,
        ),
        icon: const Icon(Icons.close_rounded),
      ),
    );
  }
}
