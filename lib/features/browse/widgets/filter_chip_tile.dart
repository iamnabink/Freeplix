import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freeplix/core/theme/app_colors.dart';
import 'package:freeplix/core/theme/app_spacing.dart';
import 'package:freeplix/core/theme/app_typography.dart';

/// The one selectable control the filter sheet is built from.
class FilterChipTile extends HookWidget {
  const FilterChipTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final hovered = useState(false);

    return Semantics(
      button: true,
      selected: selected,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => hovered.value = true,
        onExit: (_) => hovered.value = false,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: Motion.fast,
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.sm,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: selected ? AppColors.lamp : AppColors.soot,
              borderRadius: BorderRadius.circular(Radii.sm),
              border: Border.all(
                color: selected
                    ? AppColors.lamp
                    : (hovered.value ? AppColors.screenDim : AppColors.ash),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 14,
                    color: selected ? AppColors.ink : AppColors.screenDim,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: AppTypography.bodyStyle(
                    size: 13,
                    weight: selected ? 600 : 500,
                    color: selected ? AppColors.ink : AppColors.screen,
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

/// A dismissible chip for the active-filter summary under the heading.
class ActiveFilterChip extends StatelessWidget {
  const ActiveFilterChip({
    required this.label,
    required this.onRemove,
    super.key,
  });

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Remove filter $label',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onRemove,
          child: Container(
            padding: const EdgeInsets.only(
              left: Insets.sm,
              right: 6,
              top: 6,
              bottom: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.lampGlow(0.12),
              borderRadius: BorderRadius.circular(Radii.sm),
              border: Border.all(color: AppColors.lampGlow(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTypography.bodyStyle(
                    size: 12.5,
                    weight: 600,
                    color: AppColors.lamp,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: AppColors.lamp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
