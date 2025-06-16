import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:here_sdk/core.dart';

class GeoBoundaryTravinh {
  Future<List<GeoCoordinates>> loadCoordinates(String path) async {
    final jsonStr = await rootBundle.loadString(path);
    final jsonData = jsonDecode(jsonStr);

    // Lấy mảng toạ độ (Polygon -> List of points)
    final List<dynamic> coordinates =
        (jsonData['geometry']['coordinates'] as List).first;

    return coordinates
        .map<GeoCoordinates>(
          (point) => GeoCoordinates(point[1], point[0]), // [lat, lng]
        )
        .toList();
  }
}
