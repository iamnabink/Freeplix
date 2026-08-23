// ignore_for_file: document_ignores

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freeplix/core/network/api_exception.dart';
import 'package:freeplix/core/theme/app_colors.dart';
import 'package:freeplix/core/theme/app_spacing.dart';
import 'package:freeplix/core/theme/app_typography.dart';
import 'package:freeplix/core/widgets/meta_bar.dart';
import 'package:freeplix/core/widgets/net_image.dart';
import 'package:freeplix/data/models/discovery_refs.dart';
import 'package:freeplix/data/models/genre.dart';
import 'package:freeplix/data/models/media_filter.dart';
import 'package:freeplix/data/models/media_type.dart';
import 'package:freeplix/data/models/person_ref.dart';
import 'package:freeplix/data/repositories/tmdb_repository.dart';
import 'package:freeplix/features/browse/widgets/filter_chip_tile.dart';

/// Opens the filter sheet and returns the filter to apply, or null if the
/// reader backed out.
Future<MediaFilter?> showFilterSheet(
  BuildContext context, {
  required MediaFilter current,
  required List<Genre> genres,
  required MediaType type,
  required TmdbRepository repository,
}) {
  return showModalBottomSheet<MediaFilter>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.ink.withValues(alpha: 0.72),
    // Sits in the lower part of the screen rather than climbing over the
    // whole page, and stays a readable column on wide displays instead of
    // stretching the full width.
    constraints: const BoxConstraints(maxWidth: 720),
    builder: (_) => FilterSheet(
      current: current,
      genres: genres,
      type: type,
      repository: repository,
    ),
  );
}

class FilterSheet extends HookWidget {
  const FilterSheet({
    required this.current,
    required this.genres,
    required this.type,
    required this.repository,
    super.key,
  });

  final MediaFilter current;
  final List<Genre> genres;
  final MediaType type;
  final TmdbRepository repository;

  @override
  Widget build(BuildContext context) {
    // Edits are held locally and only applied on confirm, so backing out of
    // the sheet leaves the results untouched.
    final draft = useState(current);
    final viewport = MediaQuery.sizeOf(context);

    return Container(
      constraints: BoxConstraints(maxHeight: viewport.height * 0.7),
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
                              onTap: () => draft.value = draft.value.copyWith(
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
                  if (type == MediaType.movie)
                    _AsyncPicker<PersonRef>(
                      title: 'Cast',
                      hint:
                          'Films featuring a performer. Pick more than one '
                          'for films they share.',
                      placeholder: 'Search for an actor',
                      icon: Icons.person_search_rounded,
                      search: repository.searchPeople,
                      labelOf: (p) => p.name,
                      avatarOf: (p) => p.profile,
                      selected: draft.value.cast,
                      onChanged: (next) =>
                          draft.value = draft.value.copyWith(cast: next),
                    ),
                  _AsyncPicker<KeywordRef>(
                    title: 'Keyword',
                    hint:
                        'What a title is about, rather than its genre — '
                        'try "heist" or "time travel".',
                    placeholder: 'Search keywords',
                    icon: Icons.local_offer_outlined,
                    search: repository.searchKeywords,
                    labelOf: (k) => k.name,
                    selected: draft.value.keywords,
                    onChanged: (next) =>
                        draft.value = draft.value.copyWith(keywords: next),
                  ),
                  _AsyncPicker<CompanyRef>(
                    title: 'Studio',
                    hint: 'Everything from one production company',
                    placeholder: 'Search studios',
                    icon: Icons.apartment_rounded,
                    search: repository.searchCompanies,
                    labelOf: (c) => c.name,
                    selected: draft.value.companies,
                    onChanged: (next) =>
                        draft.value = draft.value.copyWith(companies: next),
                  ),
                  _Providers(
                    draft: draft,
                    repository: repository,
                    type: type,
                  ),
                  if (type == MediaType.movie)
                    _Section(
                      title: 'Runtime',
                      child: Wrap(
                        spacing: Insets.xs,
                        runSpacing: Insets.xs,
                        children: [
                          FilterChipTile(
                            label: 'Any',
                            selected: draft.value.runtimeMax == null,
                            onTap: () => draft.value = draft.value.copyWith(
                              runtimeMax: () => null,
                            ),
                          ),
                          for (final limit in [90, 120, 150])
                            FilterChipTile(
                              label:
                                  'Under ${limit ~/ 60}h'
                                  '${limit % 60 == 0 ? '' : ' ${limit % 60}m'}',
                              icon: Icons.schedule_rounded,
                              selected: draft.value.runtimeMax == limit,
                              onTap: () => draft.value = draft.value.copyWith(
                                runtimeMax: () => limit,
                              ),
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
      padding: const EdgeInsets.fromLTRB(
        Insets.lg,
        Insets.xs,
        Insets.sm,
        Insets.sm,
      ),
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

/// One async search control, shared by cast, keywords and studios.
///
/// Each of those is "type a few letters, pick from what TMDB returns, keep
/// the chosen ones as chips" — so they are one widget, not three.
class _AsyncPicker<T> extends HookWidget {
  const _AsyncPicker({
    required this.title,
    required this.hint,
    required this.placeholder,
    required this.icon,
    required this.search,
    required this.labelOf,
    required this.selected,
    required this.onChanged,
    this.avatarOf,
    super.key,
  });

  final String title;
  final String hint;
  final String placeholder;
  final IconData icon;
  final Future<List<T>> Function(String query) search;
  final String Function(T item) labelOf;
  final String? Function(T item)? avatarOf;
  final Set<T> selected;
  final ValueChanged<Set<T>> onChanged;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final query = useState('');
    final results = useState<List<T>>(const []);
    final loading = useState(false);

    useEffect(() {
      final term = query.value.trim();
      if (term.length < 2) {
        results.value = const [];
        return null;
      }

      var cancelled = false;
      loading.value = true;
      final timer = Timer(const Duration(milliseconds: 350), () async {
        try {
          final found = await search(term);
          if (!cancelled) results.value = found.take(10).toList();
        } on ApiException {
          if (!cancelled) results.value = const [];
        } finally {
          if (!cancelled) loading.value = false;
        }
      });

      return () {
        cancelled = true;
        timer.cancel();
      };
    }, [query.value]);

    return _Section(
      title: title,
      hint: hint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selected.isNotEmpty) ...[
            Wrap(
              spacing: Insets.xs,
              runSpacing: Insets.xs,
              children: [
                for (final item in selected)
                  ActiveFilterChip(
                    label: labelOf(item),
                    onRemove: () => onChanged({...selected}..remove(item)),
                  ),
              ],
            ),
            const SizedBox(height: Insets.sm),
          ],
          TextField(
            controller: controller,
            onChanged: (value) => query.value = value,
            style: AppTypography.bodyStyle(
              size: 14,
              color: AppColors.emulsion,
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              isDense: true,
              prefixIcon: Icon(icon, size: 18, color: AppColors.screenDim),
              suffixIcon: loading.value
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
          ),
          if (results.value.isNotEmpty) ...[
            const SizedBox(height: Insets.sm),
            Wrap(
              spacing: Insets.xs,
              runSpacing: Insets.xs,
              children: [
                for (final item in results.value)
                  if (!selected.contains(item))
                    _ResultChip(
                      label: labelOf(item),
                      avatar: avatarOf?.call(item),
                      onTap: () {
                        onChanged({...selected, item});
                        controller.clear();
                        query.value = '';
                      },
                    ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultChip extends StatelessWidget {
  const _ResultChip({
    required this.label,
    required this.onTap,
    this.avatar,
  });

  final String label;
  final String? avatar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.only(
            left: avatar == null ? Insets.sm : 0,
            right: Insets.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.soot,
            borderRadius: BorderRadius.circular(Radii.pill),
            border: Border.all(color: AppColors.ash),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (avatar != null) ...[
                ClipOval(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: NetImage(
                      url: avatar,
                      fallbackIcon: Icons.person_outline_rounded,
                    ),
                  ),
                ),
                const SizedBox(width: Insets.xs),
              ],
              Text(
                label,
                style: AppTypography.bodyStyle(
                  size: 12.5,
                  weight: 600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Streaming services carrying titles in the chosen region.
class _Providers extends HookWidget {
  const _Providers({
    required this.draft,
    required this.repository,
    required this.type,
  });

  final ValueNotifier<MediaFilter> draft;
  final TmdbRepository repository;
  final MediaType type;

  static const _regions = [
    ('US', 'United States'),
    ('IN', 'India'),
    ('GB', 'United Kingdom'),
    ('NP', 'Nepal'),
    ('AU', 'Australia'),
    ('CA', 'Canada'),
    ('DE', 'Germany'),
    ('JP', 'Japan'),
  ];

  @override
  Widget build(BuildContext context) {
    final region = draft.value.watchRegion;
    final providers = useState<List<WatchProviderRef>>(const []);

    useEffect(() {
      var cancelled = false;
      unawaited(() async {
        try {
          final found = await repository.watchProviders(type, region);
          if (!cancelled) providers.value = found;
        } on ApiException {
          if (!cancelled) providers.value = const [];
        }
      }());
      return () => cancelled = true;
    }, [region, type]);

    return _Section(
      title: 'Streaming on',
      hint: 'Availability differs by country, so pick a region first',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Insets.xs,
            runSpacing: Insets.xs,
            children: [
              for (final (code, label) in _regions)
                FilterChipTile(
                  label: label,
                  selected: region == code,
                  onTap: () => draft.value = draft.value.copyWith(
                    watchRegion: code,
                    provider: () => null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: Insets.sm),
          if (providers.value.isEmpty)
            Text(
              'Loading services…',
              style: AppTypography.bodyStyle(size: 12.5),
            )
          else
            Wrap(
              spacing: Insets.xs,
              runSpacing: Insets.xs,
              children: [
                FilterChipTile(
                  label: 'Any',
                  selected: draft.value.provider == null,
                  onTap: () =>
                      draft.value = draft.value.copyWith(provider: () => null),
                ),
                for (final service in providers.value)
                  FilterChipTile(
                    label: service.name,
                    selected: draft.value.provider == service,
                    onTap: () => draft.value = draft.value.copyWith(
                      provider: () =>
                          draft.value.provider == service ? null : service,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
