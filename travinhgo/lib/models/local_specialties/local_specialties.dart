import 'package:hive/hive.dart';
import 'package:travinhgo/models/location.dart';

part 'local_specialties.g.dart';

@HiveType(typeId: 0)
class LocalSpecialties {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String foodName;
  @HiveField(2)
  final String? description;
  @HiveField(3)
  final List<String> images;
  @HiveField(4)
  final List<LocalSpecialtyLocation> locations;
  @HiveField(5)
  final String tagId;

  LocalSpecialties(
      {required this.id,
      required this.foodName,
      this.description,
      required this.images,
      required this.locations,
      required this.tagId});

  factory LocalSpecialties.fromJson(Map<String, dynamic> json) {
    return LocalSpecialties(
      id: json['id'] ?? '',
      foodName: json['foodName'] ?? '',
      description: json['description'],
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      locations: json['locations'] == null
          ? []
          : (json['locations'] as List)
              .map((e) => LocalSpecialtyLocation.fromJson(e))
              .toList(),
      tagId: json['tagId'] ?? '',
    );
  }
}

@HiveType(typeId: 2)
class LocalSpecialtyLocation {
  @HiveField(0)
  final String locationId;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String address;
  @HiveField(3)
  final String markerId;
  @HiveField(4)
  final Location location;

  LocalSpecialtyLocation(
      {required this.locationId,
      required this.name,
      required this.address,
      required this.markerId,
      required this.location});

  factory LocalSpecialtyLocation.fromJson(Map<String, dynamic> json) {
    return LocalSpecialtyLocation(
        locationId: json['locationId'],
        name: json['name'],
        address: json['address'],
        markerId: json['markerId'],
        location: Location.fromJson(json['location']));
  }
}
