import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';
import 'dart:developer' as developer;

import 'package:travinhgo/models/maps/geo_boundary_travinh.dart';
import 'base_map_provider.dart';

/// BoundaryMapProvider handles the visualization and boundary checking for Tra Vinh province
class BoundaryMapProvider {
  // Reference to the base map provider
  final BaseMapProvider baseMapProvider;

  // Geo boundary model
  final GeoBoundaryTravinh _boundaryModel = GeoBoundaryTravinh();
  final String geoJsonPath = 'assets/geo/travinh.json';

  // Tra Vinh boundary polyline
  MapPolyline? traVinhBoundary;

  // Get mapController from baseMapProvider
  HereMapController? get mapController => baseMapProvider.mapController;

  // Tra Vinh province coordinates for reference
  static const double traVinhLat = 9.9349;
  static const double traVinhLon = 106.3452;

  // Constructor
  BoundaryMapProvider(this.baseMapProvider);

  /// Displays the Tra Vinh province boundary on the map
  Future<void> displayTraVinhBoundary() async {
    if (mapController == null) return;

    try {
      // Remove existing boundary if any
      if (traVinhBoundary != null) {
        mapController!.mapScene.removeMapPolyline(traVinhBoundary!);
        traVinhBoundary = null;
      }

      // Load boundary coordinates from GeoJSON
      final boundaryCoordinates =
          await _boundaryModel.loadCoordinates(geoJsonPath);

      if (boundaryCoordinates.isEmpty) {
        developer.log('No boundary coordinates found in GeoJSON',
            name: 'BoundaryMapProvider');
        return;
      }

      // Create a GeoPolyline from the coordinates
      GeoPolyline geoPolyline = GeoPolyline(boundaryCoordinates);

      // Create a map measure dependent render size for line width (5 pixels)
      MapMeasureDependentRenderSize lineWidth =
          MapMeasureDependentRenderSize.withSingleSize(
              RenderSizeUnit.pixels, 5.0);

      // Create a solid line representation for the polyline
      MapPolylineSolidRepresentation solidRep = MapPolylineSolidRepresentation(
          lineWidth,
          Color.fromARGB(255, 255, 0, 0), // Red color
          LineCap.round // Round cap for better appearance
          );

      // Create a MapPolyline with the solid representation
      traVinhBoundary = MapPolyline.withRepresentation(geoPolyline, solidRep);

      // Add the polyline to the map
      mapController!.mapScene.addMapPolyline(traVinhBoundary!);

      developer.log('Tra Vinh province boundary displayed as polyline',
          name: 'BoundaryMapProvider');
    } catch (e) {
      developer.log('Error displaying Tra Vinh boundary: $e',
          name: 'BoundaryMapProvider');
    }
  }

  /// Checks if a point is inside the Tra Vinh province boundary
  Future<bool> isPointInTraVinhBoundary(GeoCoordinates point) async {
    try {
      // Load the boundary coordinates from the GeoJSON file
      final boundaryCoordinates =
          await _boundaryModel.loadCoordinates(geoJsonPath);

      if (boundaryCoordinates.isEmpty) {
        developer.log(
            'No boundary coordinates found, allowing point: ${point.latitude}, ${point.longitude}',
            name: 'BoundaryMapProvider');
        return true;
      }

      // Ray-casting algorithm to determine if point is inside polygon
      bool isInside = false;
      int i, j = boundaryCoordinates.length - 1;

      for (i = 0; i < boundaryCoordinates.length; i++) {
        // Check if the point is within the boundary using ray-casting algorithm
        if (((boundaryCoordinates[i].latitude > point.latitude) !=
                (boundaryCoordinates[j].latitude > point.latitude)) &&
            (point.longitude <
                boundaryCoordinates[i].longitude +
                    (boundaryCoordinates[j].longitude -
                            boundaryCoordinates[i].longitude) *
                        (point.latitude - boundaryCoordinates[i].latitude) /
                        (boundaryCoordinates[j].latitude -
                            boundaryCoordinates[i].latitude))) {
          isInside = !isInside;
        }
        j = i;
      }

      // Log the result for debugging
      if (!isInside) {
        developer.log(
            'Point outside boundary: ${point.latitude}, ${point.longitude}',
            name: 'BoundaryMapProvider');
      }

      return isInside;
    } catch (e) {
      developer.log('Error checking boundary: $e', name: 'BoundaryMapProvider');
      // If we can't check boundary for any reason, allow the marker
      return true;
    }
  }

  /// Cleans up boundary resources
  void cleanupBoundaryResources() {
    if (mapController == null) return;

    try {
      // Remove Tra Vinh boundary polyline if it exists
      if (traVinhBoundary != null) {
        mapController!.mapScene.removeMapPolyline(traVinhBoundary!);
        traVinhBoundary = null;
      }

      developer.log('Boundary resources cleaned up',
          name: 'BoundaryMapProvider');
    } catch (e) {
      developer.log('Error cleaning up boundary resources: $e',
          name: 'BoundaryMapProvider');
    }
  }

  /// Moves to Tra Vinh center
  void moveToTraVinhCenter() {
    baseMapProvider.moveCamera(GeoCoordinates(traVinhLat, traVinhLon), 9000.0);
  }
}
