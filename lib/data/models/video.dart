import 'package:equatable/equatable.dart';

class Video extends Equatable {
  const Video({
    required this.key,
    required this.name,
    required this.site,
    required this.type,
    required this.official,
  });

  factory Video.fromJson(Map<String, dynamic> json) => Video(
    key: json['key'] as String? ?? '',
    name: json['name'] as String? ?? '',
    site: json['site'] as String? ?? '',
    type: json['type'] as String? ?? '',
    official: json['official'] as bool? ?? false,
  );

  final String key;
  final String name;
  final String site;
  final String type;
  final bool official;

  bool get isYouTube => site.toLowerCase() == 'youtube' && key.isNotEmpty;

  /// `youtube-nocookie.com` keeps the trailer from setting tracking cookies —
  /// Freeplix runs no analytics, and the player should match.
  String get embedUrl =>
      'https://www.youtube-nocookie.com/embed/$key?autoplay=0&rel=0&modestbranding=1&playsinline=1';

  String get watchUrl => 'https://www.youtube.com/watch?v=$key';

  @override
  List<Object?> get props => [key];
}
