import 'package:hive/hive.dart';

part 'top_favorite_destination.g.dart';

@HiveType(typeId: 16)
class TopFavoriteDestination {
  @HiveField(0)
  final String? id;
  @HiveField(1)
  final String? name;
  @HiveField(2)
  final String? image;
  @HiveField(3)
  final double? averageRating;
  @HiveField(4)
  final String? description;
  @HiveField(5)
  final double? latitude;
  @HiveField(6)
  final double? longitude;

  TopFavoriteDestination(this.id, this.name, this.image, this.averageRating,
      this.description, this.latitude, this.longitude);

  factory TopFavoriteDestination.fromJson(Map<String, dynamic> json) {
    return TopFavoriteDestination(
      json['id'] as String?,
      json['name'] as String?,
      json['image'] as String?,
      (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      json['description'] as String?,
      (json['latitude'] as num?)?.toDouble(),
      (json['longitude'] as num?)?.toDouble(),
    );
  }
}
