enum MediaType {
  movie('movie', 'Movie'),
  tv('tv', 'Series'),
  person('person', 'Person');

  const MediaType(this.wire, this.label);

  final String wire;
  final String label;

  static MediaType fromWire(String? value) => switch (value) {
    'tv' => MediaType.tv,
    'person' => MediaType.person,
    _ => MediaType.movie,
  };
}
