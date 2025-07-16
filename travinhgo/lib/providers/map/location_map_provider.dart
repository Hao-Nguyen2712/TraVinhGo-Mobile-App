import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:here_sdk/core.dart';
import 'dart:developer' as developer;

import 'base_map_provider.dart';
import 'marker_map_provider.dart';

/// LocationMapProvider handles all user location related functionality
class LocationMapProvider {
  // Reference to other providers
  final BaseMapProvider baseMapProvider;
  final MarkerMapProvider markerMapProvider;

  // Callback for when position is updated
  Function? onPositionUpdated;

  // User's current position
  Position? currentPosition;
  String? locationErrorMessage;

  // Constants
  static const double userLocationZoomDistance = 1000.0;

  // Constructor
  LocationMapProvider(this.baseMapProvider, this.markerMapProvider);

  /// Checks and requests location permission
  Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      locationErrorMessage = 'Location services are disabled';
      return false;
    }

    // Check and request permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        locationErrorMessage = 'Location permission denied';
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      locationErrorMessage = 'Location permission permanently denied';
      return false;
    }

    return true;
  }

  /// Gets the current user position
  Future<void> getCurrentPosition() async {
    try {
      // Check location permissions first
      final hasPermission = await handleLocationPermission();
      if (!hasPermission) {
        developer.log('Location permission not granted',
            name: 'LocationMapProvider');
        return;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        locationErrorMessage = 'Location services are disabled';
        developer.log('Location services are disabled',
            name: 'LocationMapProvider');
        return;
      }

      // First try to get last known position for faster response
      Position? position = await Geolocator.getLastKnownPosition();

      // If no last known position, get current position with timeout
      position ??= await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy
              .medium, // Use medium accuracy for faster response
          timeLimit: Duration(seconds: 30),
          forceAndroidLocationManager:
              true // More reliable on some Android devices
          );

      currentPosition = position;

      // Add a marker at the current position and move camera
      if (baseMapProvider.mapController != null && currentPosition != null) {
        // Clear any existing location marker
        markerMapProvider
            .clearMarkers([MarkerMapProvider.MARKER_TYPE_LOCATION]);

        // Add a new marker at the current position
        await markerMapProvider.addMarker(
            GeoCoordinates(
                currentPosition!.latitude, currentPosition!.longitude),
            MarkerMapProvider.MARKER_TYPE_LOCATION);

        // Move camera to the current position
        moveToCurrentPosition();

        developer.log(
            'Current position found: ${currentPosition!.latitude}, ${currentPosition!.longitude}',
            name: 'LocationMapProvider');
      }
    } catch (e) {
      locationErrorMessage =
          "Could not determine your location. Please check your device settings.";
      developer.log("Error getting current position: ${e.toString()}",
          name: 'LocationMapProvider');
    }

    // Notify listeners that the position has been updated
    if (onPositionUpdated != null) {
      onPositionUpdated!();
    }
  }

  /// Moves the map camera to the current position
  void moveToCurrentPosition() {
    if (currentPosition == null) return;

    baseMapProvider.moveCamera(
        GeoCoordinates(currentPosition!.latitude, currentPosition!.longitude),
        userLocationZoomDistance);
  }
}
