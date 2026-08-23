import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freeplix/core/theme/app_colors.dart';
import 'package:freeplix/core/theme/app_spacing.dart';
import 'package:freeplix/core/theme/app_typography.dart';
import 'package:freeplix/core/widgets/meta_bar.dart';
import 'package:freeplix/core/widgets/net_image.dart';
import 'package:freeplix/core/widgets/skeletons.dart';
import 'package:freeplix/data/models/season.dart';

class SeasonPicker extends StatelessWidget {
  const SeasonPicker({
    required this.seasons,
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final List<Season> seasons;
  final int? selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final real = seasons.where((s) => s.seasonNumber > 0).toList();
    if (real.length < 2) return const SizedBox.shrink();

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: real.length,
        separatorBuilder: (_, _) => const SizedBox(width: Insets.xs),
        itemBuilder: (context, index) {
          final season = real[index];
          final active = season.seasonNumber == selected;
          return _SeasonTab(
            label: 'S${season.seasonNumber}',
            active: active,
            onTap: () => onSelect(season.seasonNumber),
          );
        },
      ),
    );
  }
}

class _SeasonTab extends StatelessWidget {
  const _SeasonTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: Motion.fast,
            padding: const EdgeInsets.symmetric(horizontal: Insets.md),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? AppColors.lamp : AppColors.soot,
              borderRadius: BorderRadius.circular(Radii.sm),
              border: Border.all(
                color: active ? AppColors.lamp : AppColors.ash,
              ),
            ),
            child: Text(
              label,
              style: AppTypography.monoStyle(
                size: 12,
                weight: FontWeight.w700,
                letterSpacing: 0.6,
                color: active ? AppColors.ink : AppColors.screen,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EpisodeList extends StatelessWidget {
  const EpisodeList({
    required this.episodes,
    required this.isLoading,
    required this.onPlay,
    super.key,
  });

  final List<Episode> episodes;
  final bool isLoading;
  final ValueChanged<Episode> onPlay;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Column(
        children: List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: Insets.sm),
            child: Pulse(width: double.infinity, height: 92),
          ),
        ),
      );
    }

    if (episodes.isEmpty) {
      return Text(
        'TMDB has no episode listing for this season yet.',
        style: AppTypography.bodyStyle(size: 14),
      );
    }

    return Column(
      children: [
        for (final episode in episodes)
          Padding(
            padding: const EdgeInsets.only(bottom: Insets.sm),
            child: _EpisodeTile(episode: episode, onPlay: () => onPlay(episode)),
          ),
      ],
    );
  }
}

class _EpisodeTile extends HookWidget {
  const _EpisodeTile({required this.episode, required this.onPlay});

  final Episode episode;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final hovered = useState(false);
    final isCompact =
        MediaQuery.sizeOf(context).width < Breakpoints.compact;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => hovered.value = true,
      onExit: (_) => hovered.value = false,
      child: GestureDetector(
        onTap: onPlay,
        child: AnimatedContainer(
          duration: Motion.fast,
          padding: const EdgeInsets.all(Insets.sm),
          decoration: BoxDecoration(
            color: hovered.value ? AppColors.soot2 : AppColors.soot,
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(
              color: hovered.value ? AppColors.screenDim : AppColors.ash,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 44,
                child: Text(
                  episode.episodeNumber.toString().padLeft(2, '0'),
                  style: AppTypography.monoStyle(
                    size: 18,
                    weight: FontWeight.w700,
                    color: hovered.value
                        ? AppColors.lamp
                        : AppColors.screenDim,
                  ),
                ),
              ),
              if (!isCompact) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.sm),
                  child: SizedBox(
                    width: 132,
                    height: 74,
                    child: NetImage(url: episode.still),
                  ),
                ),
                const SizedBox(width: Insets.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      episode.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyStyle(
                        size: 14.5,
                        weight: 600,
                        color: AppColors.emulsion,
                      ),
                    ),
                    const SizedBox(height: 3),
                    MetaBar(
                      entries: [
                        if (episode.runtime != null) '${episode.runtime}m',
                        if (episode.airDate != null)
                          '${episode.airDate!.year}',
                        if (!episode.hasAired) 'Unaired',
                      ],
                      size: 10,
                    ),
                    if (episode.overview.isNotEmpty) ...[
                      const SizedBox(height: Insets.xs),
                      Text(
                        episode.overview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyStyle(size: 13, height: 1.45),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: Insets.sm),
              Icon(
                Icons.play_circle_outline_rounded,
                color: hovered.value ? AppColors.lamp : AppColors.screenDim,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
