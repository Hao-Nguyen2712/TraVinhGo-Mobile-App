import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:here_sdk/core.dart';

class GeoBoundaryTravinh {
  /// Loads coordinates from GeoJSON file and extracts boundary
  ///
  /// This method handles MultiPolygon GeoJSON data and extracts
  /// the outer boundary of each polygon
  Future<List<GeoCoordinates>> loadCoordinates(String path) async {
    final jsonStr = await rootBundle.loadString(path);
    final jsonData = jsonDecode(jsonStr);

    List<GeoCoordinates> allCoordinates = [];
    final geometryType = jsonData['geometry']['type'];

    if (geometryType == 'MultiPolygon') {
      // Handle MultiPolygon format (array of polygons)
      final List<dynamic> polygons =
          jsonData['geometry']['coordinates'] as List;

      // Process each polygon in the MultiPolygon
      for (var polygon in polygons) {
        // Each polygon has one or more rings (first is outer, rest are holes)
        final List<dynamic> rings = polygon as List;

        // We only need the outer ring (boundary) of each polygon
        if (rings.isNotEmpty) {
          final List<dynamic> outerRing = rings.first;

          // Convert coordinates to GeoCoordinates
          final ringCoordinates = outerRing
              .map<GeoCoordinates>(
                (point) => GeoCoordinates(point[1], point[0]), // [lat, lng]
              )
              .toList();

          allCoordinates.addAll(ringCoordinates);
        }
      }
    } else {
      // Handle simple Polygon format (fallback)
      final List<dynamic> coordinates =
          (jsonData['geometry']['coordinates'] as List).first;

      allCoordinates = coordinates
          .map<GeoCoordinates>(
            (point) => GeoCoordinates(point[1], point[0]), // [lat, lng]
          )
          .toList();
    }

    return allCoordinates;
  }
}
