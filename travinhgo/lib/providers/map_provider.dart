import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/core.engine.dart';
import 'package:here_sdk/gestures.dart';
import 'package:geolocator/geolocator.dart';
import 'package:travinhgo/models/maps/geo_boundary_travinh.dart';
import 'package:travinhgo/utils/env_config.dart';
import 'dart:developer' as developer;

import '../Models/Maps/top_favorite_destination.dart';
import '../services/map_service.dart';

/// MapProvider class that handles map-related business logic and state management
/// following MVVM architecture
class MapProvider extends ChangeNotifier {
  // Constants
  static const double initialZoomDistance = 9000.0;
  static const double userLocationZoomDistance = 1000.0;

  // Marker size constants
  static const double markerMinSize = 40.0; // Increased default marker size
  static const double markerMaxSize = 80.0;
  static const double minZoomLevel = 5.0;
  static const double maxZoomLevel = 20.0;

  // Marker types
  static const String MARKER_TYPE_LOCATION = "location";
  static const String MARKER_TYPE_DESTINATION = "destination";
  static const String MARKER_TYPE_CUSTOM = "custom";

  // Tra Vinh province coordinates
  static const double traVinhLat = 9.9349;
  static const double traVinhLon = 106.3452;

  // HERE SDK credentials
  final String _accessKeyId = EnvConfig.getString('Here_Access_KeyId');
  final String _accessKeySecret = EnvConfig.getString('Here_Access_KeySecret');

  // Geo boundary model
  final GeoBoundaryTravinh _boundaryModel = GeoBoundaryTravinh();
  final String geoJsonPath = 'assets/geo/travinh.json';

  // POI data storage
  String? lastPoiName;
  String? lastPoiCategory;
  GeoCoordinates? lastPoiCoordinates;
  final double poiPickingRadius = 20; // Radius in pixels for POI picking
  bool showPoiPopup = false; // Flag to control POI popup visibility

  // State variables
  String? errorMessage;
  bool isLoading = true;
  Position? currentPosition;
  int selectedCategoryIndex = 0;
  int currentDestinationIndex = 0;
  bool destinationsLoaded = false;
  double currentZoomLevel = 14.0; // Default zoom level

  MapPolygon? traVinhPolygon;

  // HERE SDK related variables
  HereMapController? mapController;
  final List<MapMarker> destinationMarkers = [];
  final List<MapMarker> customMarkers = [];
  MapMarker? currentLocationMarker;
  MapMarker? currentCustomMarker;

  // Top favorite destinations
  List<TopFavoriteDestination> topDestinations = [];
  final MapService _mapService = MapService();

  // Categories for filter buttons
  final List<String> categories = ['Pagoda', 'Market', 'Museum', 'Temple'];

  // Global key for scaffold to show SnackBar
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Sets up tap and double tap listeners for the map
  void setupGestureListeners() {
    // Setup tap listener
    mapController?.gestures.tapListener = TapListener((Point2D touchPoint) {
      var geoCoordinates = mapController?.viewToGeoCoordinates(touchPoint);
      if (geoCoordinates != null) {
        developer.log('Tap at: $geoCoordinates', name: 'MapProvider');

        // First check for POIs at the tapped location
        _pickMapPOIs(touchPoint, geoCoordinates);
      }
    });

    // Track camera changes
    if (mapController != null) {
      mapController!.camera.addListener(MapCameraListener((cameraState) {
        // Get the current distance to target and estimate zoom level
        double distanceToTargetInMeters = cameraState.distanceToTargetInMeters;
        double newZoomLevel =
            _estimateZoomLevelFromDistance(distanceToTargetInMeters);

        if ((newZoomLevel - currentZoomLevel).abs() > 0.5) {
          currentZoomLevel = newZoomLevel;

          // Update marker sizes if needed
          if (currentCustomMarker != null && customMarkers.isNotEmpty) {
            _updateMarkerSize();
          }
        }
      }));
    }
  }

  /// Picks embedded POIs (Carto POIs) from the map at the tapped position
  void _pickMapPOIs(Point2D touchPoint, GeoCoordinates geoCoordinates) {
    if (mapController == null) return;

    try {
      // Create a small rectangle around the touch point for picking
      final size = Size2D(40, 40); // 20 pixels radius in each direction
      final origin = Point2D(touchPoint.x - 20, touchPoint.y - 20);
      final Rectangle2D pickArea = Rectangle2D(origin, size);

      // Use the pick API to find POIs near the touch point
      mapController!.pick(null, pickArea, (MapPickResult? pickMapResult) {
        if (pickMapResult == null) {
          developer.log("No pick result returned", name: 'MapProvider');
          // No POI found, add a custom marker at the tapped location
          addMarker(geoCoordinates, MARKER_TYPE_CUSTOM);
          return;
        }

        // Check for POIs in the content result
        final contentResult = pickMapResult.mapContent;
        if (contentResult != null && contentResult.pickedPlaces.isNotEmpty) {
          final pickedPlace = contentResult.pickedPlaces.first;

          // Store POI information
          lastPoiName = pickedPlace.name;
          lastPoiCategory = pickedPlace.placeCategoryId;
          lastPoiCoordinates = pickedPlace.coordinates;

          developer.log(
              "POI found: ${pickedPlace.name}, Category: ${pickedPlace.placeCategoryId}",
              name: 'MapProvider');

          // Show POI popup
          showPoiPopup = true;

          // Notify listeners so UI can be updated with POI info
          notifyListeners();
        } else {
          // No POI found, add a custom marker at the tapped location
          addMarker(geoCoordinates, MARKER_TYPE_CUSTOM);

          // Clear previous POI data
          lastPoiName = null;
          lastPoiCategory = null;
          lastPoiCoordinates = null;
          showPoiPopup = false;

          notifyListeners();
        }
      });
    } catch (e) {
      developer.log("Error picking map POIs: $e", name: 'MapProvider');
      // In case of error, still add the marker
      addMarker(geoCoordinates, MARKER_TYPE_CUSTOM);
    }
  }

  /// Closes the POI popup
  void closePoiPopup() {
    showPoiPopup = false;
    notifyListeners();
  }

  /// Checks if a tap occurred on a marker and handles the tap
  void _checkTapOnMarker(Point2D touchPoint) {
    if (mapController == null) return;

    // Convert screen point to geo coordinates
    GeoCoordinates? tappedGeoCoordinates =
        mapController?.viewToGeoCoordinates(touchPoint);
    if (tappedGeoCoordinates == null) return;

    // Check for custom markers
    if (currentCustomMarker != null) {
      _checkMarkerTap(tappedGeoCoordinates, currentCustomMarker!);
    }

    // Check for destination markers
    for (MapMarker marker in destinationMarkers) {
      if (_checkMarkerTap(tappedGeoCoordinates, marker)) {
        break;
      }
    }
  }

  /// Check if a tap is on a specific marker and handle it if it is
  bool _checkMarkerTap(GeoCoordinates tapCoordinates, MapMarker marker) {
    double distance = _calculateDistance(
        tapCoordinates.latitude,
        tapCoordinates.longitude,
        marker.coordinates.latitude,
        marker.coordinates.longitude);

    // If tap is within 50 meters of the marker, consider it a tap on the marker
    if (distance < 50) {
      GeoCoordinates coords = marker.coordinates;
      developer.log('Marker tapped at: ${coords.latitude}, ${coords.longitude}',
          name: 'MapProvider');
      return true;
    }
    return false;
  }

  /// Calculate distance between two geo points in meters
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// Convert degrees to radians
  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  /// Estimate zoom level from camera distance
  double _estimateZoomLevelFromDistance(double distanceInMeters) {
    // Convert distance to zoom level (approximate)
    // Lower distance means higher zoom level
    double zoomLevel = 24 - (math.log(distanceInMeters) / math.ln2);
    return zoomLevel.clamp(minZoomLevel, maxZoomLevel);
  }

  /// Updates the marker size based on current zoom level
  void _updateMarkerSize() async {
    if (mapController == null || currentCustomMarker == null) return;

    // Calculate new marker size based on zoom level
    int markerSize = _calculateMarkerSize();

    try {
      // Remove the current marker
      mapController!.mapScene.removeMapMarker(currentCustomMarker!);

      // Create a new marker with updated size
      MapImage markerImage =
          await _getMarkerImage(MARKER_TYPE_CUSTOM, markerSize);

      // Create a new marker with the same coordinates but new size
      MapMarker newMarker =
          MapMarker(currentCustomMarker!.coordinates, markerImage);
      newMarker.drawOrder = 1000;

      // Add the new marker and update reference
      mapController!.mapScene.addMapMarker(newMarker);

      // Update markers list
      if (customMarkers.isNotEmpty) {
        customMarkers.clear();
      }
      customMarkers.add(newMarker);
      currentCustomMarker = newMarker;

      notifyListeners();
    } catch (e) {
      developer.log('Failed to update marker size: $e', name: 'MapProvider');
    }
  }

  /// Calculate the appropriate marker size based on zoom level
  int _calculateMarkerSize() {
    double zoomFactor =
        (currentZoomLevel - minZoomLevel) / (maxZoomLevel - minZoomLevel);
    return (markerMinSize + zoomFactor * (markerMaxSize - markerMinSize))
        .round();
  }

  /// Get a marker image with the specified size
  Future<MapImage> _getMarkerImage(String markerType, [int? customSize]) async {
    String assetPath;
    int size = customSize ?? _calculateMarkerSize();

    // Determine asset path based on marker type
    switch (markerType) {
      case MARKER_TYPE_LOCATION:
        assetPath = 'assets/images/markers/gps_icon.png';
        break;
      case MARKER_TYPE_DESTINATION:
      case MARKER_TYPE_CUSTOM:
      default:
        assetPath = 'assets/images/markers/marker.png';
        break;
    }

    try {
      // Create marker image directly - no caching needed as HERE SDK handles this
      return MapImage.withFilePathAndWidthAndHeight(assetPath, size, size);
    } catch (e) {
      developer.log('Failed to create marker image: $e', name: 'MapProvider');

      // Fallback to a default size if the specified size fails
      try {
        return MapImage.withFilePathAndWidthAndHeight(assetPath, 80, 80);
      } catch (finalError) {
        developer.log('CRITICAL: Even default marker failed: $finalError',
            name: 'MapProvider');
        throw Exception('Could not create any marker image');
      }
    }
  }

  /// Adds a marker to the map of a specific type
  Future<void> addMarker(GeoCoordinates coordinates, String markerType) async {
    if (mapController == null) return;

    try {
      // Handle marker type-specific logic
      if (markerType == MARKER_TYPE_CUSTOM) {
        // Clear any existing custom markers
        clearMarkers([MARKER_TYPE_CUSTOM]);
      }

      // Get marker image
      MapImage markerImage = await _getMarkerImage(markerType);

      // Create new marker
      MapMarker mapMarker = MapMarker(coordinates, markerImage);
      mapMarker.drawOrder = 1000; // Ensure marker is on top

      // Add marker to map
      mapController?.mapScene.addMapMarker(mapMarker);

      // Store marker reference based on type
      switch (markerType) {
        case MARKER_TYPE_LOCATION:
          if (currentLocationMarker != null) {
            mapController?.mapScene.removeMapMarker(currentLocationMarker!);
          }
          currentLocationMarker = mapMarker;
          break;
        case MARKER_TYPE_CUSTOM:
          customMarkers.add(mapMarker);
          currentCustomMarker = mapMarker;
          break;
        case MARKER_TYPE_DESTINATION:
          destinationMarkers.add(mapMarker);
          break;
      }

      // Log the coordinates where marker was placed
      developer.log(
          '$markerType marker added at: ${coordinates.latitude}, ${coordinates.longitude}',
          name: 'MapProvider');

      // Notify listeners to update UI if needed
      notifyListeners();
    } catch (e) {
      developer.log('Failed to add marker: $e', name: 'MapProvider');
    }
  }

  /// Removes markers of specified types
  void clearMarkers(List<String> markerTypes) {
    if (mapController == null) return;

    for (String type in markerTypes) {
      switch (type) {
        case MARKER_TYPE_CUSTOM:
          for (var marker in customMarkers) {
            mapController!.mapScene.removeMapMarker(marker);
          }
          customMarkers.clear();
          currentCustomMarker = null;
          break;
        case MARKER_TYPE_DESTINATION:
          for (var marker in destinationMarkers) {
            mapController!.mapScene.removeMapMarker(marker);
          }
          destinationMarkers.clear();
          break;
        case MARKER_TYPE_LOCATION:
          if (currentLocationMarker != null) {
            mapController!.mapScene.removeMapMarker(currentLocationMarker!);
            currentLocationMarker = null;
          }
          break;
      }
    }
    notifyListeners();
  }

  /// Initializes the HERE SDK
  Future<void> initializeHERESDK() async {
    try {
      // Initialize the SDK context
      SdkContext.init(IsolateOrigin.main);

      // Set credentials for the HERE SDK
      AuthenticationMode authenticationMode =
          AuthenticationMode.withKeySecret(_accessKeyId, _accessKeySecret);
      SDKOptions sdkOptions =
          SDKOptions.withAuthenticationMode(authenticationMode);

      // Initialize the SDK engine
      await SDKNativeEngine.makeSharedInstance(sdkOptions);

      isLoading = false;
      notifyListeners();
    } catch (e) {
      developer.log('Error initializing HERE SDK: $e', name: 'MapProvider');
      errorMessage = 'Failed to initialize HERE SDK: ${e.toString()}';
      isLoading = false;
      notifyListeners();
    }
  }

  /// Disposes HERE SDK resources
  Future<void> disposeHERESDK() async {
    // Free HERE SDK resources before the application shuts down
    await SDKNativeEngine.sharedInstance?.dispose();
    SdkContext.release();
  }

  /// Loads top favorite destinations from the service
  Future<void> loadTopDestinations() async {
    try {
      isLoading = true;
      notifyListeners();

      final destinations = await _mapService.getTopFavoriteDestinations();

      topDestinations = destinations;
      destinationsLoaded = true;
      isLoading = false;

      // Add markers for destinations if map is ready
      if (mapController != null) {
        addDestinationMarkers();
      }

      notifyListeners();
    } catch (e) {
      developer.log('Error loading top destinations: $e', name: 'MapProvider');
      isLoading = false;
      destinationsLoaded = false; // Mark as not loaded on error
      topDestinations = []; // Reset to empty list on error
      notifyListeners();
    }
  }

  /// Refreshes the map to show Tra Vinh province
  void refreshMap() {
    if (mapController == null) return;
    // Move to Tra Vinh province
    moveCamera(GeoCoordinates(traVinhLat, traVinhLon), initialZoomDistance);
  }

  /// Checks and requests location permission
  Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check and request permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Gets the current user position
  Future<void> getCurrentPosition() async {
    // check the location permission
    final hasPermission = await handleLocationPermission();
    if (!hasPermission) {
      return;
    }

    try {
      isLoading = true;
      notifyListeners();

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15));

      currentPosition = position;
      isLoading = false;

      // If we have the map controller, add a marker at the current position
      if (mapController != null && currentPosition != null) {
        addMarker(
            GeoCoordinates(
                currentPosition!.latitude, currentPosition!.longitude),
            MARKER_TYPE_LOCATION);
      }

      notifyListeners();
    } catch (e) {
      isLoading = false;
      developer.log("Error getting current position: ${e.toString()}",
          name: 'MapProvider');
      notifyListeners();
    }
  }

  /// Moves the camera to a specified location with a given zoom distance
  void moveCamera(GeoCoordinates coordinates, [double? distanceInMeters]) {
    if (mapController == null) return;

    MapMeasure mapMeasureZoom = MapMeasure(MapMeasureKind.distanceInMeters,
        distanceInMeters ?? userLocationZoomDistance);

    mapController!.camera.lookAtPointWithMeasure(coordinates, mapMeasureZoom);
  }

  /// Moves the map camera to the current position
  void moveToCurrentPosition() {
    if (currentPosition == null) return;
    moveCamera(
        GeoCoordinates(currentPosition!.latitude, currentPosition!.longitude),
        userLocationZoomDistance);
  }

  /// Moves the camera to a specific destination
  void moveToDestination(String id) {
    if (mapController == null) return;

    // Get coordinates for the destination
    final coordinates = _mapService.getDestinationCoordinates()[id];
    if (coordinates == null) return;

    // Create a GeoCoordinates object and move camera
    moveCamera(GeoCoordinates(coordinates[0], coordinates[1]), 1500);
  }

  /// Adds markers for all destinations on the map
  void addDestinationMarkers() {
    if (mapController == null || topDestinations.isEmpty) return;

    // Clear existing destination markers
    clearMarkers([MARKER_TYPE_DESTINATION]);

    // Get coordinates for all destinations
    final coordinatesMap = _mapService.getDestinationCoordinates();

    // Add a marker for each destination
    for (var destination in topDestinations) {
      try {
        final coordinates = coordinatesMap[destination.id];
        if (coordinates == null) continue;

        addMarker(GeoCoordinates(coordinates[0], coordinates[1]),
            MARKER_TYPE_DESTINATION);
      } catch (e) {
        developer.log(
            'Failed to add marker for destination ${destination.id}: ${e.toString()}',
            name: 'MapProvider');
      }
    }
  }

  /// Initializes the map scene
  void initMapScene(HereMapController controller) {
    mapController = controller;

    // Load the map scene
    mapController!.mapScene.loadSceneForMapScheme(MapScheme.normalDay,
        (MapError? error) {
      if (error != null) {
        developer.log('Map scene not loaded. MapError: ${error.toString()}',
            name: 'MapProvider');
        errorMessage = 'Failed to load map scene: ${error.toString()}';
        notifyListeners();
      } else {
        // First show Tra Vinh province
        refreshMap();

        // Setup gesture listeners for tap and double tap
        setupGestureListeners();

        // Add destination markers if data is already loaded
        if (destinationsLoaded) {
          addDestinationMarkers();
        }
      }
    });
  }

  /// Updates the selected category index
  void updateSelectedCategory(int index) {
    selectedCategoryIndex = index;
    notifyListeners();
    // Here you would filter POIs based on the selected category
    // This will be implemented in a future update
  }

  /// Updates the current destination index and moves to that destination
  void updateCurrentDestination(int index) {
    currentDestinationIndex = index;

    // Move to the destination on the map
    if (topDestinations.isNotEmpty && topDestinations[index].id != null) {
      moveToDestination(topDestinations[index].id!);
    }

    notifyListeners();
  }

  // helper function to load file as Uint8List
  Future<Uint8List> _loadFileAsUint8List(String assetPathToFile) async {
    // The path refers to the assets directory as specified in pubspec.yaml.
    ByteData fileData = await rootBundle.load(assetPathToFile);
    return Uint8List.view(fileData.buffer);
  }

  /// Checks if a point is inside the Tra Vinh province boundary
  Future<bool> isPointInTraVinhBoundary(GeoCoordinates point) async {
    if (_boundaryModel == null) return true;

    try {
      // Load the boundary coordinates from the GeoJSON file
      final boundaryCoordinates =
          await _boundaryModel.loadCoordinates(geoJsonPath);

      if (boundaryCoordinates.isEmpty) return true;

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

      return isInside;
    } catch (e) {
      developer.log('Error checking boundary: $e', name: 'MapProvider');
      // If we can't check boundary for any reason, allow the marker
      return true;
    }
  }
}
