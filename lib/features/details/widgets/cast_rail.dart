import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freeplix/core/theme/app_colors.dart';
import 'package:freeplix/core/theme/app_spacing.dart';
import 'package:freeplix/core/theme/app_typography.dart';
import 'package:freeplix/core/widgets/net_image.dart';
import 'package:freeplix/data/models/credits.dart';
import 'package:go_router/go_router.dart';

class CastRail extends StatelessWidget {
  const CastRail({required this.cast, super.key});

  final List<CastMember> cast;

  @override
  Widget build(BuildContext context) {
    if (cast.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cast.length,
        separatorBuilder: (_, _) => const SizedBox(width: Insets.md),
        itemBuilder: (context, index) => _CastCard(member: cast[index]),
      ),
    );
  }
}

/// Tapping a performer browses their films.
///
/// It goes to /movies because TMDB honours `with_cast` on /discover/movie
/// only — it silently ignores the parameter for series.
class _CastCard extends HookWidget {
  const _CastCard({required this.member});

  final CastMember member;

  @override
  Widget build(BuildContext context) {
    final hovered = useState(false);

    return Semantics(
      button: true,
      label: 'Browse films with ${member.name}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => hovered.value = true,
        onExit: (_) => hovered.value = false,
        child: GestureDetector(
          onTap: () => context.go('/movies?cast=${member.id}'),
          child: SizedBox(
            width: 108,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: Motion.base,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Radii.md),
                    border: Border.all(
                      color: hovered.value
                          ? AppColors.lamp
                          : Colors.transparent,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Radii.md - 1),
                    child: SizedBox(
                      height: 128,
                      width: 108,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          NetImage(
                            url: member.profile,
                            fallbackIcon: Icons.person_outline_rounded,
                          ),
                          AnimatedOpacity(
                            duration: Motion.fast,
                            opacity: hovered.value ? 1 : 0,
                            child: ColoredBox(
                              color: AppColors.ink.withValues(alpha: 0.55),
                              child: const Center(
                                child: Icon(
                                  Icons.search_rounded,
                                  size: 20,
                                  color: AppColors.lamp,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Insets.xs),
                Text(
                  member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyStyle(
                    size: 12.5,
                    weight: 600,
                    color: hovered.value ? AppColors.lamp : AppColors.emulsion,
                  ),
                ),
                Text(
                  member.character,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyStyle(
                    size: 11.5,
                    height: 1.3,
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
