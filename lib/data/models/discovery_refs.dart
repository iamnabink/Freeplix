import 'package:equatable/equatable.dart';
import 'package:freeplix/data/models/image_size.dart';

/// A TMDB keyword — the tag that makes browsing feel like "a time-travel
/// heist" rather than "Action".
class KeywordRef extends Equatable {
  const KeywordRef({required this.id, required this.name});

  factory KeywordRef.fromJson(Map<String, dynamic> json) => KeywordRef(
    id: json['id'] as int,
    name: json['name'] as String? ?? '',
  );

  final int id;
  final String name;

  @override
  List<Object?> get props => [id];
}

/// A production company.
class CompanyRef extends Equatable {
  const CompanyRef({required this.id, required this.name, this.logoPath});

  factory CompanyRef.fromJson(Map<String, dynamic> json) => CompanyRef(
    id: json['id'] as int,
    name: json['name'] as String? ?? '',
    logoPath: json['logo_path'] as String?,
  );

  final int id;
  final String name;
  final String? logoPath;

  String? get logo => tmdbImage(logoPath, PosterSize.w185.path);

  @override
  List<Object?> get props => [id];
}

/// A streaming service, as reported by TMDB for a given region.
class WatchProviderRef extends Equatable {
  const WatchProviderRef({
    required this.id,
    required this.name,
    this.logoPath,
    this.priority = 0,
  });

  factory WatchProviderRef.fromJson(Map<String, dynamic> json) =>
      WatchProviderRef(
        id: json['provider_id'] as int,
        name: json['provider_name'] as String? ?? '',
        logoPath: json['logo_path'] as String?,
        priority: json['display_priority'] as int? ?? 0,
      );

  final int id;
  final String name;
  final String? logoPath;
  final int priority;

  String? get logo => tmdbImage(logoPath, PosterSize.w185.path);

  @override
  List<Object?> get props => [id];
}

/// One-tap starting points. Every id here was looked up against TMDB rather
/// than guessed, because a wrong id fails silently as an empty result.
class DiscoveryPreset extends Equatable {
  const DiscoveryPreset({
    required this.label,
    this.keyword,
    this.company,
  });

  final String label;
  final KeywordRef? keyword;
  final CompanyRef? company;

  @override
  List<Object?> get props => [label];
}

abstract final class Presets {
  static const moods = [
    DiscoveryPreset(
      label: 'Time travel',
      keyword: KeywordRef(id: 4379, name: 'time travel'),
    ),
    DiscoveryPreset(
      label: 'Heist',
      keyword: KeywordRef(id: 10051, name: 'heist'),
    ),
    DiscoveryPreset(
      label: 'Based on a true story',
      keyword: KeywordRef(id: 9672, name: 'based on true story'),
    ),
    DiscoveryPreset(
      label: 'Post-apocalyptic',
      keyword: KeywordRef(id: 4458, name: 'post-apocalyptic future'),
    ),
    DiscoveryPreset(
      label: 'Revenge',
      keyword: KeywordRef(id: 9748, name: 'revenge'),
    ),
    DiscoveryPreset(
      label: 'Dystopia',
      keyword: KeywordRef(id: 4565, name: 'dystopia'),
    ),
    DiscoveryPreset(
      label: 'Coming of age',
      keyword: KeywordRef(id: 10683, name: 'coming of age'),
    ),
  ];

  static const studios = [
    DiscoveryPreset(
      label: 'Studio Ghibli',
      company: CompanyRef(id: 10342, name: 'Studio Ghibli'),
    ),
    DiscoveryPreset(
      label: 'A24',
      company: CompanyRef(id: 293354, name: 'A24'),
    ),
    DiscoveryPreset(
      label: 'Pixar',
      company: CompanyRef(id: 3, name: 'Pixar'),
    ),
    DiscoveryPreset(
      label: 'Marvel Studios',
      company: CompanyRef(id: 420, name: 'Marvel Studios'),
    ),
    DiscoveryPreset(
      label: 'Blumhouse',
      company: CompanyRef(id: 3172, name: 'Blumhouse Productions'),
    ),
    DiscoveryPreset(
      label: 'Yash Raj Films',
      company: CompanyRef(id: 1569, name: 'Yash Raj Films'),
    ),
    DiscoveryPreset(
      label: 'Dharma Productions',
      company: CompanyRef(id: 19146, name: 'Dharma Productions'),
    ),
  ];
}
