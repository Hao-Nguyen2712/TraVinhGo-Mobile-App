import 'package:hive/hive.dart';
import 'package:travinhgo/models/location.dart';

part 'destination.g.dart';

@HiveType(typeId: 0)
class Destination extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  double avarageRating;
  @HiveField(3)
  final String? description;
  @HiveField(4)
  final String? address;
  @HiveField(5)
  final Location location;
  @HiveField(6)
  final List<String> images;
  @HiveField(7)
  final HistoryStory? historyStory;
  @HiveField(8)
  final DateTime? updateAt;
  @HiveField(9)
  final String destinationTypeId;
  @HiveField(10)
  final OpeningHours? openingHours;
  @HiveField(11)
  final String? capacity;
  @HiveField(12)
  final Contact? contact;
  @HiveField(13)
  final String tagId;
  @HiveField(14)
  final String? ticket;
  @HiveField(15)
  int? favoriteCount;
  @HiveField(16)
  final bool status;

  Destination(
      {required this.id,
      required this.name,
      required this.avarageRating,
      this.description,
      this.address,
      required this.location,
      required this.images,
      this.historyStory,
      this.updateAt,
      required this.destinationTypeId,
      this.openingHours,
      this.capacity,
      this.contact,
      required this.tagId,
      this.ticket,
      this.favoriteCount,
      required this.status});

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['id'],
      name: json['name'],
      avarageRating: (json['avarageRating'] as num).toDouble(),
      description: json['description'],
      address: json['address'],
      location: Location.fromJson(json['location']),
      images: List<String>.from(json['images']),
      historyStory: json['historyStory'] != null
          ? HistoryStory.fromJson(json['historyStory'])
          : null,
      updateAt:
          json['updateAt'] != null ? DateTime.parse(json['updateAt']) : null,
      destinationTypeId: json['destinationTypeId'],
      openingHours: json['openingHours'] != null
          ? OpeningHours.fromJson(json['openingHours'])
          : null,
      capacity: json['capacity'],
      contact:
          json['contact'] != null ? Contact.fromJson(json['contact']) : null,
      tagId: json['tagId'],
      ticket: json['ticket'],
      favoriteCount: json['favoriteCount'],
      status: json['status'],
    );
  }
}

@HiveType(typeId: 2)
class HistoryStory {
  @HiveField(0)
  final String? content;
  @HiveField(1)
  final List<String>? images;

  HistoryStory({this.content, this.images});

  factory HistoryStory.fromJson(Map<String, dynamic> json) {
    return HistoryStory(
      content: json['content'],
      images: json['images'] != null ? List<String>.from(json['images']) : [],
    );
  }
}

@HiveType(typeId: 3)
class OpeningHours {
  @HiveField(0)
  final String? openTime;
  @HiveField(1)
  final String? closeTime;

  OpeningHours({this.openTime, this.closeTime});

  factory OpeningHours.fromJson(Map<String, dynamic> json) {
    return OpeningHours(
      openTime: json['openTime'],
      closeTime: json['closeTime'],
    );
  }
}

@HiveType(typeId: 4)
class Contact {
  @HiveField(0)
  final String? phone;
  @HiveField(1)
  final String? email;
  @HiveField(2)
  final String? website;

  Contact({this.phone, this.email, this.website});

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      phone: json['phone'],
      email: json['email'],
      website: json['website'],
    );
  }
}
