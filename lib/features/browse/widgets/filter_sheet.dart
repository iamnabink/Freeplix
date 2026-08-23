import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freeplix/core/theme/app_colors.dart';
import 'package:freeplix/core/theme/app_spacing.dart';
import 'package:freeplix/core/theme/app_typography.dart';
import 'package:freeplix/core/widgets/meta_bar.dart';
import 'package:freeplix/data/models/genre.dart';
import 'package:freeplix/data/models/media_filter.dart';
import 'package:freeplix/data/models/media_type.dart';
import 'package:freeplix/features/browse/widgets/filter_chip_tile.dart';

/// Opens the filter sheet and returns the filter to apply, or null if the
/// reader backed out.
Future<MediaFilter?> showFilterSheet(
  BuildContext context, {
  required MediaFilter current,
  required List<Genre> genres,
  required MediaType type,
}) {
  return showModalBottomSheet<MediaFilter>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.ink.withValues(alpha: 0.72),
    builder: (_) =>
        FilterSheet(current: current, genres: genres, type: type),
  );
}

class FilterSheet extends HookWidget {
  const FilterSheet({
    required this.current,
    required this.genres,
    required this.type,
    super.key,
  });

  final MediaFilter current;
  final List<Genre> genres;
  final MediaType type;

  @override
  Widget build(BuildContext context) {
    // Edits are held locally and only applied on confirm, so backing out of
    // the sheet leaves the results untouched.
    final draft = useState(current);
    final viewport = MediaQuery.sizeOf(context);

    return Container(
      constraints: BoxConstraints(maxHeight: viewport.height * 0.9),
      decoration: const BoxDecoration(
        color: AppColors.ink,
        border: Border(top: BorderSide(color: AppColors.ash)),
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Handle(),
          _Header(
            count: draft.value.activeCount,
            onClear: () => draft.value = draft.value.cleared(),
          ),
          const Divider(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                Insets.lg,
                Insets.lg,
                Insets.lg,
                Insets.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Industries(draft: draft),
                  _Section(
                    title: 'Sort by',
                    child: Wrap(
                      spacing: Insets.xs,
                      runSpacing: Insets.xs,
                      children: [
                        for (final option in SortOption.values)
                          if (option.availableFor(type))
                            FilterChipTile(
                              label: option.label,
                              selected: draft.value.sort == option,
                              onTap: () =>
                                  draft.value = draft.value.copyWith(
                                    sort: option,
                                  ),
                            ),
                      ],
                    ),
                  ),
                  if (genres.isNotEmpty)
                    _Section(
                      title: 'Genre',
                      hint: 'Pick more than one to narrow further',
                      child: Wrap(
                        spacing: Insets.xs,
                        runSpacing: Insets.xs,
                        children: [
                          for (final genre in genres)
                            FilterChipTile(
                              label: genre.name,
                              selected: draft.value.genreIds.contains(genre.id),
                              onTap: () {
                                final next = {...draft.value.genreIds};
                                if (!next.remove(genre.id)) next.add(genre.id);
                                draft.value = draft.value.copyWith(
                                  genreIds: next,
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  _Section(
                    title: 'Original language',
                    hint: 'The language a title was made in',
                    child: _SingleChoice(
                      options: [
                        for (final l in FilterOptions.languages)
                          (l.code, l.label),
                      ],
                      selected: draft.value.language,
                      onSelect: (code) => draft.value = draft.value.copyWith(
                        language: () => code,
                      ),
                    ),
                  ),
                  _Section(
                    title: 'Country of origin',
                    child: _SingleChoice(
                      options: [
                        for (final c in FilterOptions.countries)
                          (c.code, c.label),
                      ],
                      selected: draft.value.country,
                      onSelect: (code) => draft.value = draft.value.copyWith(
                        country: () => code,
                      ),
                    ),
                  ),
                  _Section(
                    title: 'Minimum rating',
                    child: Wrap(
                      spacing: Insets.xs,
                      runSpacing: Insets.xs,
                      children: [
                        FilterChipTile(
                          label: 'Any',
                          selected: draft.value.minRating == null,
                          onTap: () => draft.value = draft.value.copyWith(
                            minRating: () => null,
                          ),
                        ),
                        for (final threshold in [5.0, 6.0, 7.0, 8.0])
                          FilterChipTile(
                            label: '${threshold.toStringAsFixed(0)}+',
                            icon: Icons.star_rounded,
                            selected: draft.value.minRating == threshold,
                            onTap: () => draft.value = draft.value.copyWith(
                              minRating: () => threshold,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _Decades(draft: draft),
                ],
              ),
            ),
          ),
          _Footer(
            onApply: () => Navigator.of(context).pop(draft.value),
            changed: draft.value != current,
          ),
        ],
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Insets.sm, bottom: Insets.xs),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.ash,
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count, required this.onClear});

  final int count;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.xs, Insets.sm, Insets.sm),
      child: Row(
        children: [
          Text('Filters', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(width: Insets.xs),
          if (count > 0)
            Text(
              '$count',
              style: AppTypography.monoStyle(
                weight: FontWeight.w700,
                color: AppColors.lamp,
              ),
            ),
          const Spacer(),
          if (count > 0)
            TextButton(onPressed: onClear, child: const Text('Clear all')),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 20),
            color: AppColors.screen,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.hint});

  final String title;
  final Widget child;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(title),
          if (hint != null) ...[
            const SizedBox(height: 3),
            Text(hint!, style: AppTypography.bodyStyle(size: 12.5)),
          ],
          const SizedBox(height: Insets.sm),
          child,
        ],
      ),
    );
  }
}

/// Language and country behave the same way: one choice, or none.
class _SingleChoice extends StatelessWidget {
  const _SingleChoice({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<(String, String)> options;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Insets.xs,
      runSpacing: Insets.xs,
      children: [
        FilterChipTile(
          label: 'Any',
          selected: selected == null,
          onTap: () => onSelect(null),
        ),
        for (final (code, label) in options)
          FilterChipTile(
            label: label,
            selected: selected == code,
            // Tapping the current choice clears it.
            onTap: () => onSelect(selected == code ? null : code),
          ),
      ],
    );
  }
}

/// Familiar industry names, each just a language and country pair.
class _Industries extends StatelessWidget {
  const _Industries({required this.draft});

  final ValueNotifier<MediaFilter> draft;

  @override
  Widget build(BuildContext context) {
    final active = draft.value.matchingIndustry;

    return _Section(
      title: 'Industry',
      hint: 'Shorthand for a language and country pair',
      child: Wrap(
        spacing: Insets.xs,
        runSpacing: Insets.xs,
        children: [
          for (final entry in FilterOptions.industries.entries)
            FilterChipTile(
              label: entry.key,
              selected: active == entry.key,
              onTap: () {
                final isActive = active == entry.key;
                draft.value = draft.value.copyWith(
                  language: () => isActive ? null : entry.value.language,
                  country: () => isActive ? null : entry.value.country,
                );
              },
            ),
        ],
      ),
    );
  }
}

class _Decades extends StatelessWidget {
  const _Decades({required this.draft});

  final ValueNotifier<MediaFilter> draft;

  @override
  Widget build(BuildContext context) {
    final thisDecade = (DateTime.now().year ~/ 10) * 10;
    final decades = [
      for (var d = thisDecade; d >= 1950; d -= 10) d,
    ];

    return _Section(
      title: 'Released',
      child: Wrap(
        spacing: Insets.xs,
        runSpacing: Insets.xs,
        children: [
          FilterChipTile(
            label: 'Any',
            selected: draft.value.yearFrom == null,
            onTap: () => draft.value = draft.value.copyWith(
              yearFrom: () => null,
              yearTo: () => null,
            ),
          ),
          for (final decade in decades)
            FilterChipTile(
              label: '${decade}s',
              selected: draft.value.yearFrom == decade,
              onTap: () {
                final isActive = draft.value.yearFrom == decade;
                draft.value = draft.value.copyWith(
                  yearFrom: () => isActive ? null : decade,
                  yearTo: () => isActive ? null : decade + 9,
                );
              },
            ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.onApply, required this.changed});

  final VoidCallback onApply;
  final bool changed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.soot,
        border: Border(top: BorderSide(color: AppColors.ash)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(Insets.md),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onApply,
              child: Text(changed ? 'Show results' : 'Done'),
            ),
          ),
        ),
      ),
    );
  }
}
