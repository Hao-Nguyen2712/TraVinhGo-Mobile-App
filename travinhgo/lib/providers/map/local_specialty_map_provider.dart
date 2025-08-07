import 'package:flutter/material.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';
import 'dart:developer' as developer;

import '../../services/local_specialtie_service.dart';
import 'base_map_provider.dart';
import 'marker_map_provider.dart';
import '../../models/local_specialties/local_specialties.dart';

/// LocalSpecialtyMapProvider handles displaying local specialties on the map
class LocalSpecialtyMapProvider {
  // Reference to other providers
  final BaseMapProvider baseMapProvider;
  final MarkerMapProvider markerMapProvider;
  final LocalSpecialtieService _localSpecialtyService =
      LocalSpecialtieService();

  // Flag to track if local specialties are displayed
  bool isLocalSpecialtyDisplayed = false;

  // Get mapController from baseMapProvider
  HereMapController? get mapController => baseMapProvider.mapController;

  // Constructor
  LocalSpecialtyMapProvider(
    this.baseMapProvider,
    this.markerMapProvider,
  );

  /// Displays local specialties as markers on the map
  Future<void> displayLocalSpecialties() async {
    if (mapController == null) return;

    try {
      // Clear existing markers if any
      clearLocalSpecialtyMarkers();

      // Get local specialties from the service
      final localSpecialties =
          await _localSpecialtyService.getAllLocalSpecialtyForMap();

      developer.log(
          'data_local_specialty: Fetched ${localSpecialties.length} specialties from API',
          name: 'LocalSpecialtyMapProvider');

      if (localSpecialties.isEmpty) {
        developer.log(
            'data_local_specialty: No local specialties available to display',
            name: 'LocalSpecialtyMapProvider');
        return;
      }

      developer.log(
          'data_local_specialty: Preparing to display ${localSpecialties.length} local specialties on map',
          name: 'LocalSpecialtyMapProvider');
      int displayedCount = 0;

      // Add each local specialty as a marker
      for (final specialty in localSpecialties) {
        for (final location in specialty.locations) {
          if (location.location.coordinates == null ||
              location.location.coordinates!.length < 2) {
            continue; // Skip if no valid coordinates
          }

          // Extract latitude and longitude from the coordinates
          final double longitude =
              location.location.coordinates![0]; // GeoJSON format
          final double latitude = location.location.coordinates![1];

          // Create coordinates from location
          final coordinates = GeoCoordinates(latitude, longitude);

          // Create metadata for the marker
          Metadata metadata = Metadata();
          metadata.setString("place_name", location.name);
          metadata.setString("place_category", "Đặc sản địa phương");
          metadata.setString("specialty_id", specialty.id);
          metadata.setString("food_name", specialty.foodName);
          metadata.setString("is_local_specialty", "true");
          metadata.setString("place_address", location.address);

          if (specialty.images.isNotEmpty) {
            metadata.setString("place_images", specialty.images.join(','));
          }

          // Store coordinates directly in metadata
          metadata.setDouble("place_lat", latitude);
          metadata.setDouble("place_lon", longitude);

          // Add marker with metadata
          markerMapProvider.addMarkerWithMetadata(
              coordinates, MarkerMapProvider.MARKER_TYPE_CATEGORY, metadata,
              customAsset: "assets/images/map/local_specialties.png");

          developer.log(
              'data_local_specialty: Added local specialty marker for ${specialty.foodName} at $latitude, $longitude',
              name: 'LocalSpecialtyMapProvider');
          displayedCount++;
        }
      }

      isLocalSpecialtyDisplayed = true;
      developer.log(
          'data_local_specialty: Total of $displayedCount local specialty markers have been added to the map',
          name: 'LocalSpecialtyMapProvider');
    } catch (e) {
      developer.log(
          'data_local_specialty: Error displaying local specialties: $e',
          name: 'LocalSpecialtyMapProvider');
    }
  }

  /// Clears all local specialty markers from the map
  void clearLocalSpecialtyMarkers() {
    if (mapController == null) return;

    try {
      int removedCount = 0;

      // Clear markers of type local specialty
      for (var marker in markerMapProvider.categoryMarkers.where(
          (m) => m.metadata?.getString("is_local_specialty") == "true")) {
        mapController!.mapScene.removeMapMarker(marker);
        removedCount++;
      }

      // Find and remove markers from the category markers list
      markerMapProvider.categoryMarkers.removeWhere(
          (m) => m.metadata?.getString("is_local_specialty") == "true");

      isLocalSpecialtyDisplayed = false;
      developer.log(
          'data_local_specialty: Cleared $removedCount local specialty markers from map',
          name: 'LocalSpecialtyMapProvider');
    } catch (e) {
      developer.log(
          'data_local_specialty: Error clearing local specialty markers: $e',
          name: 'LocalSpecialtyMapProvider');
    }
  }

  /// Toggle local specialty display on the map
  Future<void> toggleLocalSpecialtyDisplay() async {
    if (isLocalSpecialtyDisplayed) {
      clearLocalSpecialtyMarkers();
    } else {
      await displayLocalSpecialties();
    }
  }
}
