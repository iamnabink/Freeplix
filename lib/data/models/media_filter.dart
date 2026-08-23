import 'package:equatable/equatable.dart';
import 'package:freeplix/data/models/discovery_refs.dart';
import 'package:freeplix/data/models/media_type.dart';
import 'package:freeplix/data/models/person_ref.dart';

/// How results are ordered. TMDB names the date field differently for series.
enum SortOption {
  popular('popularity.desc', 'Most popular'),
  rated('vote_average.desc', 'Highest rated'),
  newest('primary_release_date.desc', 'Newest first'),
  oldest('primary_release_date.asc', 'Oldest first'),
  revenue('revenue.desc', 'Biggest earners');

  const SortOption(this.wire, this.label);

  final String wire;
  final String label;

  String wireFor(MediaType type) {
    if (type != MediaType.tv) return wire;
    return switch (this) {
      SortOption.newest => 'first_air_date.desc',
      SortOption.oldest => 'first_air_date.asc',
      // TMDB has no revenue ordering for series; popularity is the closest.
      SortOption.revenue => 'popularity.desc',
      _ => wire,
    };
  }

  bool availableFor(MediaType type) =>
      !(type == MediaType.tv && this == SortOption.revenue);
}

/// A spoken language TMDB can filter on, via `with_original_language`.
class LanguageOption extends Equatable {
  const LanguageOption(this.code, this.label);

  final String code;
  final String label;

  @override
  List<Object?> get props => [code];
}

/// A country of origin, via `with_origin_country`.
class CountryOption extends Equatable {
  const CountryOption(this.code, this.label);

  final String code;
  final String label;

  @override
  List<Object?> get props => [code];
}

/// Only what TMDB actually supports. Notably absent: "dubbed" — TMDB
/// describes a title's *original* language, not which dubs exist, so there is
/// no honest way to filter on it.
abstract final class FilterOptions {
  static const languages = [
    LanguageOption('en', 'English'),
    LanguageOption('hi', 'Hindi'),
    LanguageOption('ta', 'Tamil'),
    LanguageOption('te', 'Telugu'),
    LanguageOption('ml', 'Malayalam'),
    LanguageOption('kn', 'Kannada'),
    LanguageOption('bn', 'Bengali'),
    LanguageOption('mr', 'Marathi'),
    LanguageOption('pa', 'Punjabi'),
    LanguageOption('ne', 'Nepali'),
    LanguageOption('ur', 'Urdu'),
    LanguageOption('ko', 'Korean'),
    LanguageOption('ja', 'Japanese'),
    LanguageOption('zh', 'Chinese'),
    LanguageOption('es', 'Spanish'),
    LanguageOption('fr', 'French'),
    LanguageOption('de', 'German'),
    LanguageOption('it', 'Italian'),
    LanguageOption('pt', 'Portuguese'),
    LanguageOption('ru', 'Russian'),
    LanguageOption('ar', 'Arabic'),
    LanguageOption('tr', 'Turkish'),
    LanguageOption('th', 'Thai'),
  ];

  static const countries = [
    CountryOption('US', 'United States'),
    CountryOption('IN', 'India'),
    CountryOption('GB', 'United Kingdom'),
    CountryOption('KR', 'South Korea'),
    CountryOption('JP', 'Japan'),
    CountryOption('CN', 'China'),
    CountryOption('FR', 'France'),
    CountryOption('DE', 'Germany'),
    CountryOption('ES', 'Spain'),
    CountryOption('IT', 'Italy'),
    CountryOption('NP', 'Nepal'),
    CountryOption('PK', 'Pakistan'),
    CountryOption('BR', 'Brazil'),
    CountryOption('MX', 'Mexico'),
    CountryOption('CA', 'Canada'),
    CountryOption('AU', 'Australia'),
    CountryOption('TR', 'Türkiye'),
    CountryOption('TH', 'Thailand'),
  ];

  /// Shorthands people actually search by. Each is just a language and
  /// country pair TMDB understands — the label is the familiar name.
  static const industries = <String, ({String language, String country})>{
    'Bollywood': (language: 'hi', country: 'IN'),
    'Tollywood': (language: 'te', country: 'IN'),
    'Kollywood': (language: 'ta', country: 'IN'),
    'Hollywood': (language: 'en', country: 'US'),
    'K-drama': (language: 'ko', country: 'KR'),
    'Anime': (language: 'ja', country: 'JP'),
    'Nollywood': (language: 'en', country: 'NG'),
  };
}

/// The full filter state for a browse screen.
class MediaFilter extends Equatable {
  const MediaFilter({
    this.genreIds = const {},
    this.cast = const {},
    this.keywords = const {},
    this.companies = const {},
    this.provider,
    this.watchRegion = 'US',
    this.runtimeMax,
    this.language,
    this.country,
    this.minRating,
    this.yearFrom,
    this.yearTo,
    this.sort = SortOption.popular,
  });

  final Set<int> genreIds;

  /// TMDB honours `with_cast` on /discover/movie only — it silently ignores
  /// the parameter for series, so the cast filter is offered for films.
  final Set<PersonRef> cast;

  /// TMDB tags. `with_keywords` is an AND across ids.
  final Set<KeywordRef> keywords;
  final Set<CompanyRef> companies;

  /// A streaming service, meaningful only alongside [watchRegion].
  final WatchProviderRef? provider;
  final String watchRegion;

  final int? runtimeMax;
  final String? language;
  final String? country;
  final double? minRating;
  final int? yearFrom;
  final int? yearTo;
  final SortOption sort;

  /// How many filters are narrowing the results, for the badge on the button.
  int get activeCount =>
      genreIds.length +
      cast.length +
      keywords.length +
      companies.length +
      (provider == null ? 0 : 1) +
      (runtimeMax == null ? 0 : 1) +
      (language == null ? 0 : 1) +
      (country == null ? 0 : 1) +
      (minRating == null ? 0 : 1) +
      (yearFrom == null && yearTo == null ? 0 : 1);

  bool get isEmpty => activeCount == 0;

  /// The name of an industry preset this filter currently matches, if any.
  String? get matchingIndustry {
    for (final entry in FilterOptions.industries.entries) {
      if (entry.value.language == language && entry.value.country == country) {
        return entry.key;
      }
    }
    return null;
  }

  /// Translates to TMDB's `/discover` query parameters.
  Map<String, dynamic> toQuery(MediaType type) {
    final dateField = type == MediaType.tv
        ? 'first_air_date'
        : 'primary_release_date';

    return {
      'sort_by': sort.wireFor(type),
      'include_adult': false,
      // Without a vote floor, obscure entries with a single 10/10 vote
      // dominate any rating-based ordering.
      'vote_count.gte': sort == SortOption.rated ? 200 : 50,
      if (genreIds.isNotEmpty) 'with_genres': genreIds.join(','),
      if (cast.isNotEmpty && type == MediaType.movie)
        'with_cast': cast.map((p) => p.id).join(','),
      if (keywords.isNotEmpty)
        'with_keywords': keywords.map((k) => k.id).join(','),
      if (companies.isNotEmpty)
        'with_companies': companies.map((c) => c.id).join(','),
      if (provider != null) ...{
        'with_watch_providers': provider!.id,
        'watch_region': watchRegion,
      },
      if (runtimeMax != null) 'with_runtime.lte': runtimeMax,
      if (language != null) 'with_original_language': language,
      if (country != null) 'with_origin_country': country,
      if (minRating != null) 'vote_average.gte': minRating,
      if (yearFrom != null) '$dateField.gte': '$yearFrom-01-01',
      if (yearTo != null) '$dateField.lte': '$yearTo-12-31',
    };
  }

  MediaFilter copyWith({
    Set<int>? genreIds,
    Set<PersonRef>? cast,
    Set<KeywordRef>? keywords,
    Set<CompanyRef>? companies,
    WatchProviderRef? Function()? provider,
    String? watchRegion,
    int? Function()? runtimeMax,
    String? Function()? language,
    String? Function()? country,
    double? Function()? minRating,
    int? Function()? yearFrom,
    int? Function()? yearTo,
    SortOption? sort,
  }) {
    return MediaFilter(
      genreIds: genreIds ?? this.genreIds,
      cast: cast ?? this.cast,
      keywords: keywords ?? this.keywords,
      companies: companies ?? this.companies,
      provider: provider == null ? this.provider : provider(),
      watchRegion: watchRegion ?? this.watchRegion,
      runtimeMax: runtimeMax == null ? this.runtimeMax : runtimeMax(),
      language: language == null ? this.language : language(),
      country: country == null ? this.country : country(),
      minRating: minRating == null ? this.minRating : minRating(),
      yearFrom: yearFrom == null ? this.yearFrom : yearFrom(),
      yearTo: yearTo == null ? this.yearTo : yearTo(),
      sort: sort ?? this.sort,
    );
  }

  MediaFilter cleared() => MediaFilter(sort: sort, watchRegion: watchRegion);

  @override
  List<Object?> get props => [
    genreIds,
    cast,
    keywords,
    companies,
    provider,
    watchRegion,
    runtimeMax,
    language,
    country,
    minRating,
    yearFrom,
    yearTo,
    sort,
  ];
}
