import 'package:travinhgo/models/marker/marker.dart';

class DestinationType {
  final String id;
  final String name;
  final String markerId;
  Marker? marker;

  DestinationType(
      {required this.id, required this.name, required this.markerId, this.marker});

  factory DestinationType.fromJson(Map<String, dynamic> json) {
    return DestinationType(id: json['id'], name: json['name'], markerId: json['markerId']);
  }
}
