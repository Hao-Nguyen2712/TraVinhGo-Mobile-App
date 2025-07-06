class TopFavoriteDestination {
  final String? id;
  final String? name;
  final String? image;
  final double? averageRating;
  final String? description;

  TopFavoriteDestination(
      this.id, this.name, this.image, this.averageRating, this.description);

  factory TopFavoriteDestination.fromJson(Map<String, dynamic> json) {
    return TopFavoriteDestination(
      json['id'] as String?,
      json['name'] as String?,
      json['image'] as String?,
      (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      json['description'] as String?,
    );
  }
}
