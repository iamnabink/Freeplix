import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freeplix/core/theme/app_colors.dart';
import 'package:freeplix/core/theme/app_spacing.dart';
import 'package:freeplix/core/theme/app_typography.dart';
import 'package:freeplix/core/widgets/meta_bar.dart';
import 'package:freeplix/core/widgets/net_image.dart';
import 'package:freeplix/data/models/media_item.dart';

/// The projected image: one title, filling the screen, with the room's
/// darkness closing in from the left so the type stays readable.
class HeroBillboard extends HookWidget {
  const HeroBillboard({
    required this.item,
    required this.reelNumber,
    required this.reelCount,
    required this.onWatch,
    required this.onTrailer,
    required this.onDetails,
    required this.onAdvance,
    required this.isSaved,
    required this.onToggleSave,
    super.key,
  });

  final MediaItem item;
  final int reelNumber;
  final int reelCount;
  final VoidCallback onWatch;
  final VoidCallback onTrailer;
  final VoidCallback onDetails;
  final VoidCallback onAdvance;
  final bool isSaved;
  final VoidCallback onToggleSave;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < Breakpoints.compact;
    final reduced = MediaQuery.disableAnimationsOf(context);

    // The spotlight advances on its own, slowly, unless the reader has asked
    // the system to stop moving things.
    useEffect(() {
      if (reduced || reelCount < 2) return null;
      final timer = Stream<void>.periodic(
        const Duration(seconds: 9),
      ).listen((_) => onAdvance());
      return timer.cancel;
    }, [reduced, reelCount, onAdvance]);

    final height = isCompact
        ? 500.0
        : (MediaQuery.sizeOf(context).height * 0.66).clamp(430.0, 600.0);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: Motion.slow,
            child: NetImage(
              key: ValueKey(item.id),
              url: item.backdrop(),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.backdropScrim),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.backdropFade),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isCompact ? Insets.lg : Insets.xxl,
                0,
                Insets.lg,
                isCompact ? Insets.xl : Insets.xxl,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: _Copy(
                  item: item,
                  isCompact: isCompact,
                  reelNumber: reelNumber,
                  reelCount: reelCount,
                  onWatch: onWatch,
                  onTrailer: onTrailer,
                  onDetails: onDetails,
                  isSaved: isSaved,
                  onToggleSave: onToggleSave,
                ),
              ),
            ),
          ),
          if (reelCount > 1)
            Positioned(
              right: isCompact ? Insets.lg : Insets.xxl,
              bottom: isCompact ? Insets.lg : Insets.xxl,
              child: _ReelTicks(index: reelNumber - 1, count: reelCount),
            ),
        ],
      ),
    );
  }
}

class _Copy extends StatelessWidget {
  const _Copy({
    required this.item,
    required this.isCompact,
    required this.reelNumber,
    required this.reelCount,
    required this.onWatch,
    required this.onTrailer,
    required this.onDetails,
    required this.isSaved,
    required this.onToggleSave,
  });

  final MediaItem item;
  final bool isCompact;
  final int reelNumber;
  final int reelCount;
  final VoidCallback onWatch;
  final VoidCallback onTrailer;
  final VoidCallback onDetails;
  final bool isSaved;
  final VoidCallback onToggleSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Eyebrow(
              'Reel ${reelNumber.toString().padLeft(2, '0')}',
              color: AppColors.lamp,
            ),
            const SizedBox(width: Insets.sm),
            Eyebrow(item.type.label),
          ],
        ),
        const SizedBox(height: Insets.sm),
        Text(
          item.title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.displayStyle(
            size: isCompact ? 40 : 64,
            letterSpacing: isCompact ? -1.2 : -2.2,
          ),
        ),
        const SizedBox(height: Insets.sm),
        Row(
          children: [
            RatingPip(rating: item.rating, size: 12),
            if (item.rating != '—') const SizedBox(width: Insets.sm),
            MetaBar(entries: [item.year], size: 12),
          ],
        ),
        const SizedBox(height: Insets.md),
        Text(
          item.overview,
          maxLines: isCompact ? 3 : 4,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodyStyle(size: isCompact ? 14 : 16),
        ),
        const SizedBox(height: Insets.lg),
        Wrap(
          spacing: Insets.sm,
          runSpacing: Insets.sm,
          children: [
            FilledButton.icon(
              onPressed: onWatch,
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: const Text('Watch'),
            ),
            OutlinedButton.icon(
              onPressed: onToggleSave,
              icon: Icon(
                isSaved ? Icons.check_rounded : Icons.add_rounded,
                size: 20,
                color: isSaved ? AppColors.verdant : null,
              ),
              label: Text(isSaved ? 'In my list' : 'My list'),
            ),
            OutlinedButton.icon(
              onPressed: onTrailer,
              icon: const Icon(Icons.movie_creation_outlined, size: 19),
              label: const Text('Trailer'),
            ),
            OutlinedButton(
              onPressed: onDetails,
              child: const Text('Details'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Reel position, drawn as frame ticks rather than dots.
class _ReelTicks extends StatelessWidget {
  const _ReelTicks({required this.index, required this.count});

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: AnimatedContainer(
              duration: Motion.base,
              width: i == index ? 22 : 10,
              height: 2,
              color: i == index ? AppColors.lamp : AppColors.ash,
            ),
          ),
      ],
    );
  }
}
