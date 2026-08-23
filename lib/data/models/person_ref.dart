import 'package:equatable/equatable.dart';
import 'package:freeplix/data/models/image_size.dart';

/// Just enough of a person to filter by them and label the chip.
class PersonRef extends Equatable {
  const PersonRef({
    required this.id,
    required this.name,
    this.profilePath,
    this.knownFor = '',
    this.popularity = 0,
  });

  factory PersonRef.fromJson(Map<String, dynamic> json) => PersonRef(
    id: json['id'] as int,
    name: json['name'] as String? ?? '',
    profilePath: json['profile_path'] as String?,
    knownFor: json['known_for_department'] as String? ?? '',
    popularity: (json['popularity'] as num?)?.toDouble() ?? 0,
  );

  final int id;
  final String name;
  final String? profilePath;
  final String knownFor;
  final double popularity;

  String? get profile => tmdbImage(profilePath, PosterSize.w185.path);

  @override
  List<Object?> get props => [id];
}
