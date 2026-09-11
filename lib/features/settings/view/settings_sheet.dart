import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freeplix/core/config/stream_source.dart';
import 'package:freeplix/core/theme/app_colors.dart';
import 'package:freeplix/core/theme/app_spacing.dart';
import 'package:freeplix/core/theme/app_typography.dart';
import 'package:freeplix/features/settings/bloc/settings_cubit.dart';

/// Accents a viewer can give their avatar. The first is the default.
const kAccentPalette = <int>[
  0xFFFFC24B, // lamp
  0xFFFF5E3A, // filament
  0xFF4ADE80, // verdant
  0xFF5AA9FF, // sky
  0xFFB57BFF, // violet
  0xFFFF6FA5, // rose
];

/// The round profile avatar. Shows the viewer's initials over their accent,
/// or a person glyph before they have set a name.
class UserAvatar extends StatelessWidget {
  const UserAvatar({this.size = 32, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final color = Color(state.accent);
        final initials = state.initials;
        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.9), width: 1.5),
          ),
          child: initials.isEmpty
              ? Icon(Icons.person_rounded, size: size * 0.55, color: color)
              : Text(
                  initials,
                  style: AppTypography.bodyStyle(
                    size: size * 0.4,
                    weight: 700,
                    color: color,
                  ),
                ),
        );
      },
    );
  }
}

/// Opens the profile and preferences sheet, carrying the ambient
/// [SettingsCubit] into the modal.
Future<void> openSettingsSheet(BuildContext context) {
  final cubit = context.read<SettingsCubit>();
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.soot,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: const _SettingsSheet(),
    ),
  );
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: context.read<SettingsCubit>().state.name,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    final sources = StreamSources.all;

    return Padding(
      padding: EdgeInsets.only(
        left: Insets.lg,
        right: Insets.lg,
        top: Insets.xs,
        bottom: Insets.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const UserAvatar(size: 44),
                const SizedBox(width: Insets.md),
                Text(
                  'Your profile',
                  style: AppTypography.displayStyle(size: 22),
                ),
              ],
            ),
            const SizedBox(height: Insets.lg),

            const _Label('Display name'),
            const SizedBox(height: Insets.xs),
            TextField(
              controller: _name,
              onChanged: cubit.setName,
              textInputAction: TextInputAction.done,
              style: AppTypography.bodyStyle(
                size: 15,
                color: AppColors.emulsion,
              ),
              decoration: InputDecoration(
                hintText: 'Add a name for your avatar',
                hintStyle: AppTypography.bodyStyle(
                  size: 14,
                  color: AppColors.screenDim,
                ),
                filled: true,
                fillColor: AppColors.ink,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Radii.sm),
                  borderSide: const BorderSide(color: AppColors.ash),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Radii.sm),
                  borderSide: const BorderSide(color: AppColors.ash),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Radii.sm),
                  borderSide: const BorderSide(color: AppColors.lamp),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Insets.sm,
                  vertical: Insets.sm,
                ),
              ),
            ),
            const SizedBox(height: Insets.lg),

            const _Label('Avatar colour'),
            const SizedBox(height: Insets.sm),
            BlocBuilder<SettingsCubit, SettingsState>(
              buildWhen: (a, b) => a.accent != b.accent,
              builder: (context, state) => Wrap(
                spacing: Insets.sm,
                runSpacing: Insets.sm,
                children: [
                  for (final swatch in kAccentPalette)
                    _Swatch(
                      color: Color(swatch),
                      selected: state.accent == swatch,
                      onTap: () => cubit.setAccent(swatch),
                    ),
                ],
              ),
            ),
            const SizedBox(height: Insets.xl),

            const _Label('Default video source'),
            const SizedBox(height: Insets.xs),
            Text(
              'Applies to every title you play. You can still switch sources '
              'from the player.',
              style: AppTypography.bodyStyle(
                size: 12.5,
                color: AppColors.screenDim,
              ),
            ),
            const SizedBox(height: Insets.sm),
            if (sources.isEmpty)
              Text(
                'This build has no playback sources configured.',
                style: AppTypography.bodyStyle(size: 13.5),
              )
            else
              BlocBuilder<SettingsCubit, SettingsState>(
                buildWhen: (a, b) => a.defaultSourceId != b.defaultSourceId,
                builder: (context, state) {
                  final valid = sources.any(
                    (s) => s.id == state.defaultSourceId,
                  );
                  final selected = valid ? state.defaultSourceId : null;
                  return Column(
                    children: [
                      _SourceOption(
                        title: 'First available',
                        subtitle:
                            'Let Freeplix pick the first configured source',
                        selected: selected == null,
                        onTap: () => cubit.setDefaultSource(null),
                      ),
                      for (final source in sources)
                        _SourceOption(
                          title: source.name,
                          selected: selected == source.id,
                          onTap: () => cubit.setDefaultSource(source.id),
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTypography.monoStyle(letterSpacing: 1),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.emulsion : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: selected
                ? const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: AppColors.ink,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.xs),
      child: Semantics(
        button: true,
        selected: selected,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Insets.sm,
                vertical: Insets.sm,
              ),
              decoration: BoxDecoration(
                color: selected ? AppColors.soot2 : AppColors.ink,
                borderRadius: BorderRadius.circular(Radii.sm),
                border: Border.all(
                  color: selected ? AppColors.lamp : AppColors.ash,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 20,
                    color: selected ? AppColors.lamp : AppColors.screenDim,
                  ),
                  const SizedBox(width: Insets.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.bodyStyle(
                            size: 14.5,
                            weight: 600,
                            color: AppColors.emulsion,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: AppTypography.bodyStyle(
                              size: 12,
                              color: AppColors.screenDim,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
