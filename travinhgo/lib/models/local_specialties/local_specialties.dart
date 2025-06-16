import '../destination/destination.dart';

class LocalSpecialties {
  final String id;
  final String foodName;
  final String? description;
  final List<String> images;
  final List<LocalSpecialtyLocation> locations;
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
      id: json['id'],
      foodName: json['foodName'],
      description: json['description'],
      images: List<String>.from(json['images']),
      locations: (json['locations'] as List)
          .map((e) => LocalSpecialtyLocation.fromJson(e))
          .toList(),
      tagId: json['tagId'],
    );
  }
}

class LocalSpecialtyLocation {
  final String locationId;
  final String name;
  final String address;
  final String markerId;
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
