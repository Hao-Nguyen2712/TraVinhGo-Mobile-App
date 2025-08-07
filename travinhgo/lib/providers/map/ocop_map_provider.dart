import 'package:flutter/material.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';
import 'dart:developer' as developer;

import '../ocop_product_provider.dart';
import '../../services/ocop_product_service.dart';
import 'base_map_provider.dart';
import 'marker_map_provider.dart';
import '../../models/ocop/ocop_product.dart';

/// OcopMapProvider handles displaying OCOP products on the map
class OcopMapProvider {
  // Reference to other providers
  final BaseMapProvider baseMapProvider;
  final MarkerMapProvider markerMapProvider;
  final OcopProductProvider ocopProductProvider;
  final OcopProductService _ocopService = OcopProductService();

  // Marker type for OCOP products
  static const String MARKER_TYPE_OCOP = "ocop_product";

  // Flag to track if OCOP products are displayed
  bool isOcopDisplayed = false;

  // Get mapController from baseMapProvider
  HereMapController? get mapController => baseMapProvider.mapController;

  // Constructor
  OcopMapProvider(
    this.baseMapProvider,
    this.markerMapProvider,
    this.ocopProductProvider,
  );

  /// Displays OCOP products as markers on the map
  Future<void> displayOcopProducts() async {
    if (mapController == null) return;

    try {
      // Clear existing OCOP markers if any
      clearOcopMarkers();

      // Get OCOP products from the global provider
      final ocopProducts = await _ocopService.getAllOcopProductForMap();

      if (ocopProducts.isEmpty) {
        developer.log('data_ocop: No OCOP products available to display',
            name: 'OcopMapProvider');
        return;
      }

      developer.log(
          'data_ocop: Preparing to display ${ocopProducts.length} OCOP products on map',
          name: 'OcopMapProvider');
      int displayedCount = 0;

      // Add each OCOP product as a marker
      for (final product in ocopProducts) {
        // For each product, we need to check all selling locations
        for (final sellLocation in product.sellocations) {
          if (sellLocation.location == null ||
              sellLocation.location!.coordinates == null ||
              sellLocation.location!.coordinates!.length < 2) {
            continue; // Skip if no valid coordinates
          }

          // Extract latitude and longitude from the coordinates
          final double longitude = sellLocation
              .location!.coordinates![0]; // GeoJSON format has longitude first
          final double latitude =
              sellLocation.location!.coordinates![1]; // Latitude second

          // Create coordinates from product location
          final coordinates = GeoCoordinates(latitude, longitude);

          // Create metadata for the marker
          Metadata metadata = Metadata();
          metadata.setString(
              "place_name", sellLocation.locationName ?? "OCOP Location");
          metadata.setString("product_name",
              product.productName); // Store product name separately
          metadata.setString("place_category", "OCOP Product");
          metadata.setString("product_id", product.id);
          metadata.setString("product_price", product.productPrice ?? "");
          metadata.setString("product_rating", product.ocopPoint.toString());
          metadata.setString(
              "product_description", product.productDescription ?? "");
          metadata.setString("is_ocop_product", "true");
          metadata.setString("location_name", sellLocation.locationName ?? "");

          // Add product images if available
          if (product.productImage.isNotEmpty) {
            metadata.setString(
                "product_images", product.productImage.join(','));
          }

          // Add location info
          if (sellLocation.locationAddress != null) {
            metadata.setString("place_address", sellLocation.locationAddress!);
          }

          // Store coordinates directly in metadata
          metadata.setDouble("place_lat", latitude);
          metadata.setDouble("place_lon", longitude);

          // Add marker with metadata and display location name
          markerMapProvider.addMarkerWithMetadata(
              coordinates, MarkerMapProvider.MARKER_TYPE_CATEGORY, metadata,
              customAsset: "assets/images/map/ocop.png");

          developer.log(
              'data_ocop: Added OCOP marker for ${product.productName} at $latitude, $longitude',
              name: 'OcopMapProvider');
          displayedCount++;
        }
      }

      isOcopDisplayed = true;
      developer.log(
          'data_ocop: Displayed $displayedCount OCOP product locations on the map',
          name: 'OcopMapProvider');
    } catch (e) {
      developer.log('data_ocop: Error displaying OCOP products: $e',
          name: 'OcopMapProvider');
    }
  }

  /// Clears all OCOP product markers from the map
  void clearOcopMarkers() {
    if (mapController == null) return;

    try {
      // Count for logging
      int removedCount = 0;

      // Clear markers of type OCOP
      for (var marker in markerMapProvider.categoryMarkers
          .where((m) => m.metadata?.getString("is_ocop_product") == "true")) {
        mapController!.mapScene.removeMapMarker(marker);
        removedCount++;
      }

      // Find and remove markers from the category markers list
      markerMapProvider.categoryMarkers.removeWhere(
          (m) => m.metadata?.getString("is_ocop_product") == "true");

      isOcopDisplayed = false;
      developer.log(
          'data_ocop: Cleared $removedCount OCOP product markers from map',
          name: 'OcopMapProvider');
    } catch (e) {
      developer.log('data_ocop: Error clearing OCOP markers: $e',
          name: 'OcopMapProvider');
    }
  }

  /// Toggle OCOP product display on the map
  Future<void> toggleOcopProductDisplay() async {
    if (isOcopDisplayed) {
      clearOcopMarkers();
    } else {
      await displayOcopProducts();
    }
  }
}
