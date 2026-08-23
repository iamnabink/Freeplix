import 'package:flutter/material.dart';
import 'package:freeplix/core/theme/app_colors.dart';
import 'package:freeplix/core/theme/app_spacing.dart';
import 'package:freeplix/core/theme/app_typography.dart';
import 'package:freeplix/core/widgets/net_image.dart';
import 'package:freeplix/data/models/credits.dart';

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
        itemBuilder: (context, index) {
          final member = cast[index];
          return SizedBox(
            width: 108,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.md),
                  child: SizedBox(
                    height: 128,
                    width: 108,
                    child: NetImage(
                      url: member.profile,
                      fallbackIcon: Icons.person_outline_rounded,
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
                    color: AppColors.emulsion,
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
          );
        },
      ),
    );
  }
}
