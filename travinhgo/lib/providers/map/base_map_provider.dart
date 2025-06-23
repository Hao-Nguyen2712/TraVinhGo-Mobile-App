import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/core.engine.dart';
import 'package:here_sdk/core.errors.dart';
import '../../utils/env_config.dart';
import 'dart:developer' as developer;

/// BaseMapProvider handles core map functionality including initialization,
/// map scene management, and cleanups
class BaseMapProvider {
  // Core map properties
  HereMapController? mapController;
  String? errorMessage;
  bool isLoading = true;

  // Global key for scaffold to show SnackBar
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // Current zoom level tracking
  double currentZoomLevel = 14.0; // Default zoom level

  /// Initializes the HERE SDK
  Future<void> initializeHERESDK() async {
    try {
      isLoading = true;

      // Initialize SDK context
      SdkContext.init(IsolateOrigin.main);

      // Get API credentials from environment config
      final accessKeyId = EnvConfig.hereApiKey;
      final accessKeySecret = EnvConfig.hereApiSecret;

      if (accessKeyId.isEmpty || accessKeySecret.isEmpty) {
        errorMessage = "HERE API credentials are missing";
        isLoading = false;
        return;
      }

      // Set up authentication
      AuthenticationMode authenticationMode =
          AuthenticationMode.withKeySecret(accessKeyId, accessKeySecret);
      SDKOptions sdkOptions =
          SDKOptions.withAuthenticationMode(authenticationMode);

      // Initialize HERE SDK
      await SDKNativeEngine.makeSharedInstance(sdkOptions);
      isLoading = false;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
    }
  }

  /// Initializes the map scene
  void initMapScene(HereMapController controller,
      [VoidCallback? onSceneLoaded]) {
    mapController = controller;

    // Load map scene
    mapController!.mapScene.loadSceneForMapScheme(MapScheme.normalDay,
        (MapError? error) {
      if (error != null) {
        errorMessage = "Map scene loading failed: ${error.toString()}";
        isLoading = false;
        return;
      }

      // Scene loaded successfully
      isLoading = false;
      if (onSceneLoaded != null) {
        onSceneLoaded();
      }
    });
  }

  /// Moves the camera to a specified location with a given zoom distance
  void moveCamera(GeoCoordinates coordinates, [double? distanceInMeters]) {
    if (mapController == null) return;

    // Default distance if not provided
    final distance = distanceInMeters ?? 1000.0;

    // Create map measure for zoom level
    MapMeasure mapMeasure =
        MapMeasure(MapMeasureKind.distanceInMeters, distance);

    // Move camera
    mapController!.camera.lookAtPointWithMeasure(coordinates, mapMeasure);
  }

  /// Sets up camera change listener to track zoom level changes
  void _setupCameraChangeListener() {
    if (mapController == null) return;

    mapController!.camera.addListener(MapCameraListener((cameraState) {
      // Get the current distance to target and estimate zoom level
      double distanceToTargetInMeters = cameraState.distanceToTargetInMeters;
      double newZoomLevel =
          _estimateZoomLevelFromDistance(distanceToTargetInMeters);

      if ((newZoomLevel - currentZoomLevel).abs() > 0.5) {
        currentZoomLevel = newZoomLevel;
        onZoomLevelChanged?.call(currentZoomLevel);
      }
    }));
  }

  /// Callback for when zoom level changes
  Function(double)? onZoomLevelChanged;

  /// Estimate zoom level from camera distance
  double _estimateZoomLevelFromDistance(double distanceInMeters) {
    // Convert distance to zoom level (approximate)
    // Lower distance means higher zoom level
    const double minZoomLevel = 5.0;
    const double maxZoomLevel = 20.0;
    double zoomLevel = 24 - (math.log(distanceInMeters) / math.ln2);
    return zoomLevel.clamp(minZoomLevel, maxZoomLevel);
  }

  /// Cleans up map resources
  void cleanupMapResources() {
    // Map controller is managed by Flutter, no need to dispose it manually
    // Just reset our reference
    mapController = null;
  }

  /// Completely disposes HERE SDK resources
  Future<void> disposeHERESDK() async {
    try {
      await SDKNativeEngine.sharedInstance?.dispose();
    } catch (e) {
      print("Error disposing HERE SDK: $e");
    }
  }

  /// Refreshes the map by reloading map resources
  void refreshMap() {
    // Implementation will depend on what needs to be refreshed
    developer.log('Map refresh requested', name: 'BaseMapProvider');
  }
}
