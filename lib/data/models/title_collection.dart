import 'package:equatable/equatable.dart';

/// A franchise a movie belongs to (TMDB `belongs_to_collection`), e.g.
/// "The Lord of the Rings Collection". Just enough to label and open it.
class TitleCollection extends Equatable {
  const TitleCollection({
    required this.id,
    required this.name,
    this.posterPath,
    this.backdropPath,
  });

  factory TitleCollection.fromJson(Map<String, dynamic> json) {
    return TitleCollection(
      id: json['id'] as int,
      name: (json['name'] as String? ?? '').trim(),
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
    );
  }

  final int id;
  final String name;
  final String? posterPath;
  final String? backdropPath;

  @override
  List<Object?> get props => [id, name, posterPath, backdropPath];
}
