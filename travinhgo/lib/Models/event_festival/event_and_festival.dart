import 'package:hive/hive.dart';
import 'package:travinhgo/models/location.dart';

part 'event_and_festival.g.dart';

@HiveType(typeId: 14)
class EventAndFestival {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String nameEvent;
  @HiveField(2)
  final String? description;
  @HiveField(3)
  final DateTime startDate;
  @HiveField(4)
  final DateTime endDate;
  @HiveField(5)
  final String category;
  @HiveField(6)
  final List<String> images;
  @HiveField(7)
  final EventLocation location;
  @HiveField(8)
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

@HiveType(typeId: 15)
class EventLocation {
  @HiveField(0)
  final String? name;
  @HiveField(1)
  final String? address;
  @HiveField(2)
  final Location location;
  @HiveField(3)
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
