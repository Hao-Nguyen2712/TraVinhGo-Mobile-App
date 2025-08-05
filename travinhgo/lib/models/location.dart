import 'package:hive/hive.dart';

part 'location.g.dart';

@HiveType(typeId: 1)
class Location {
  @HiveField(0)
  final String? type;
  @HiveField(1)
  final List<double>? coordinates;

  Location({this.type, this.coordinates});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      type: json['type'],
      coordinates:
          List<double>.from(json['coordinates'].map((e) => e.toDouble())),
    );
  }
}
