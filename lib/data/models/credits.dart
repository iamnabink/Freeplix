import 'package:equatable/equatable.dart';
import 'package:freeplix/data/models/image_size.dart';

class CastMember extends Equatable {
  const CastMember({
    required this.id,
    required this.name,
    required this.character,
    this.profilePath,
  });

  factory CastMember.fromJson(Map<String, dynamic> json) => CastMember(
    id: json['id'] as int,
    name: json['name'] as String? ?? '',
    character: json['character'] as String? ?? '',
    profilePath: json['profile_path'] as String?,
  );

  final int id;
  final String name;
  final String character;
  final String? profilePath;

  String? get profile => tmdbImage(profilePath, PosterSize.w185.path);

  @override
  List<Object?> get props => [id, character];
}

class CrewMember extends Equatable {
  const CrewMember({
    required this.id,
    required this.name,
    required this.job,
  });

  factory CrewMember.fromJson(Map<String, dynamic> json) => CrewMember(
    id: json['id'] as int,
    name: json['name'] as String? ?? '',
    job: json['job'] as String? ?? '',
  );

  final int id;
  final String name;
  final String job;

  @override
  List<Object?> get props => [id, job];
}
