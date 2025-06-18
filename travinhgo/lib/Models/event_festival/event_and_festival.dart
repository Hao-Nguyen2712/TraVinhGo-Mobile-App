import '../destination/destination.dart';

class EventAndFestival {
  final String id;
  final String nameEvent;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final String category;
  final List<String> images;
  final EventLocation location;
  final String tagId;

  EventAndFestival(
      {required this.id,
      required this.nameEvent,
      this.description,
      required this.startDate,
      required this.endDate,
      required this.category,
      required this.images,
      required this.location,
      required this.tagId});

  factory EventAndFestival.fromJson(Map<String, dynamic> json) {
    return EventAndFestival(
      id: json['id'],
      nameEvent: json['nameEvent'],
      description: json['description'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      category: json['category'],
      images: List<String>.from(json['images']),
      location: EventLocation.fromJson(json['location']),
      tagId: json['tagId'],
    );
  }
}

class EventLocation {
  final String? name;
  final String? address;
  final Location location;
  final String markerId;

  EventLocation(
      {this.name,
      this.address,
      required this.location,
      required this.markerId});

  factory EventLocation.fromJson(Map<String, dynamic> json) {
    return EventLocation(
      name: json['name'],
      address: json['address'],
      location: Location.fromJson(json['location']),
      markerId: json['markerId'],
    );
  }
}
