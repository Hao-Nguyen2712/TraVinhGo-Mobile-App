import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/core.engine.dart';
import 'package:here_sdk/gestures.dart';
import 'package:here_sdk/search.dart';
import 'package:geolocator/geolocator.dart';
import 'package:travinhgo/models/maps/geo_boundary_travinh.dart';
import 'package:travinhgo/utils/env_config.dart';
import 'dart:developer' as developer;
import 'dart:ui' show Color;

import '../Models/Maps/top_favorite_destination.dart';
import '../services/map_service.dart';

/// CategoryType defines types of POIs that can be displayed on the map
/// with their corresponding user-friendly names and PlaceCategory IDs
class CategoryType {
  final String name; // User-friendly name for UI display
  final String vietnameseName; // Vietnamese translation of the category name
  final String categoryId; // PlaceCategory ID for HERE SDK
  final String markerAsset; // Path to the marker asset
  final String iconAsset; // Path to the icon asset for category buttons

  const CategoryType({
    required this.name,
    required this.vietnameseName,
    required this.categoryId,
    required this.markerAsset,
    required this.iconAsset,
  });
}

/// MapProvider class that handles map-related business logic and state management
/// following MVVM architecture
class MapProvider extends ChangeNotifier {
  // Constants
  static const double initialZoomDistance = 9000.0;
  static const double userLocationZoomDistance = 1000.0;

  // Marker size constants
  static const double markerMinSize = 40.0; // Increased default marker size
  static const double markerMaxSize = 120.0;
  static const double minZoomLevel = 5.0;
  static const double maxZoomLevel = 20.0;

  // Marker types
  static const String MARKER_TYPE_LOCATION = "location";
  static const String MARKER_TYPE_DESTINATION = "destination";
  static const String MARKER_TYPE_CUSTOM = "custom";
  static const String MARKER_TYPE_CATEGORY =
      "category"; // New marker type for category results

  // Tra Vinh province coordinates
  static const double traVinhLat = 9.9349;
  static const double traVinhLon = 106.3452;
  static const double searchRadiusInMeters = 10000; // 10km radius for searching

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
  bool isCategorySearching = false; // Flag to track category search progress

  // Tra Vinh province boundary
  MapPolyline? traVinhBoundary;

  // HERE SDK related variables
  HereMapController? mapController;
  final List<MapMarker> destinationMarkers = [];
  final List<MapMarker> customMarkers = [];
  final List<MapMarker> categoryMarkers =
      []; // To store markers from category search
  MapMarker? currentLocationMarker;
  MapMarker? currentCustomMarker;

  // Map polygon for showing search radius
  MapPolygon? searchRadiusCircle;

  // Top favorite destinations
  List<TopFavoriteDestination> topDestinations = [];
  final MapService _mapService = MapService();

  // Available category types with mapping between display name, PlaceCategory ID, and marker asset
  final List<CategoryType> availableCategories = [
    CategoryType(
      name: "All",
      vietnameseName: "Tất cả",
      categoryId: "", // Empty for "All" category
      markerAsset: "assets/images/markers/marker.png",
      iconAsset: "assets/images/navigations/map.png",
    ),
    CategoryType(
      name: "Hotels",
      vietnameseName: "Khách sạn",
      categoryId: PlaceCategory.accommodationHotelMotel,
      markerAsset: "assets/images/markers/hotel.png",
      iconAsset: "assets/images/markers/hotel.png",
    ),
    CategoryType(
      name: "Restaurants",
      vietnameseName: "Nhà hàng",
      categoryId: PlaceCategory.eatAndDrinkRestaurant,
      markerAsset: "assets/images/markers/restaurant.png",
      iconAsset: "assets/images/markers/restaurant.png",
    ),
    CategoryType(
      name: "Cafes",
      vietnameseName: "Quán cà phê",
      categoryId: PlaceCategory.eatAndDrinkCoffeeTea,
      markerAsset: "assets/images/markers/coffee-shop.png",
      iconAsset: "assets/images/markers/coffee-shop.png",
    ),
    CategoryType(
      name: "Fuel",
      vietnameseName: "Trạm xăng",
      categoryId: PlaceCategory.businessAndServicesFuelingStation,
      markerAsset: "assets/images/markers/gas-station.png",
      iconAsset: "assets/images/markers/gas-station.png",
    ),
    CategoryType(
      name: "ATMs",
      vietnameseName: "ATM",
      categoryId: PlaceCategory.businessAndServicesAtm,
      markerAsset: "assets/images/markers/atm.png",
      iconAsset: "assets/images/markers/atm.png",
    ),
    CategoryType(
      name: "Banks",
      vietnameseName: "Ngân hàng",
      categoryId: PlaceCategory.businessAndServicesBanking,
      markerAsset: "assets/images/markers/bank.png",
      iconAsset: "assets/images/markers/bank.png",
    ),
    CategoryType(
      name: "Schools",
      vietnameseName: "Trường học",
      categoryId: PlaceCategory.facilitiesEducation,
      markerAsset: "assets/images/markers/education.png",
      iconAsset: "assets/images/markers/education.png",
    ),
    CategoryType(
      name: "Hospitals",
      vietnameseName: "Bệnh viện",
      categoryId: PlaceCategory.facilitiesHospitalHealthcare,
      markerAsset: "assets/images/markers/hospital.png",
      iconAsset: "assets/images/markers/hospital.png",
    ),
    CategoryType(
      name: "Police",
      vietnameseName: "Đồn công an",
      categoryId: PlaceCategory.businessAndServicesPoliceFireEmergency,
      markerAsset: "assets/images/markers/police-station.png",
      iconAsset: "assets/images/markers/police-station.png",
    ),
    CategoryType(
      name: "Bus Stops",
      vietnameseName: "Trạm Xe Buýt",
      categoryId: PlaceCategory.transportPublic,
      markerAsset: "assets/images/markers/bus.png",
      iconAsset: "assets/images/markers/bus.png",
    ),
    CategoryType(
      name: "Stores",
      vietnameseName: "Cửa hàng",
      categoryId: PlaceCategory.shoppingConvenienceStore,
      markerAsset: "assets/images/markers/supermarket.png",
      iconAsset: "assets/images/markers/supermarket.png",
    ),
  ];

  // Categories for filter buttons - now populated from availableCategories Vietnamese names
  List<String> get categories =>
      availableCategories.map((cat) => cat.vietnameseName).toList();

  // Get category icon by index
  String getCategoryIcon(int index) {
    if (index < 0 || index >= availableCategories.length) {
      return "assets/images/navigations/map.png"; // Default icon
    }
    return availableCategories[index].iconAsset;
  }

  // Global key for scaffold to show SnackBar
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // Search engine and results
  SearchEngine? _searchEngine;
  List<Suggestion> _searchSuggestions = [];
  bool isSearching = false;

  // Getters
  List<Suggestion> get searchSuggestions => _searchSuggestions;

  // GeoBox for Tra Vinh Province
  GeoBox get traVinhGeoBox => GeoBox(
      GeoCoordinates(9.80, 106.10), // Southwest corner
      GeoCoordinates(10.10, 106.60) // Northeast corner
      );

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
  Future<MapImage> _getMarkerImage(String markerType,
      [int? customSize, String? customAsset]) async {
    String assetPath;
    int size = customSize ?? _calculateMarkerSize();

    // Determine asset path based on marker type or custom asset
    if (customAsset != null) {
      assetPath = customAsset;
    } else {
      switch (markerType) {
        case MARKER_TYPE_LOCATION:
          // Use a more visible location marker
          assetPath = 'assets/images/navigations/circle.png';
          // Override size for location marker to make it more visible
          size = 48;
          break;
        case MARKER_TYPE_DESTINATION:
        case MARKER_TYPE_CUSTOM:
        case MARKER_TYPE_CATEGORY:
        default:
          assetPath = 'assets/images/markers/marker.png';
          break;
      }
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
  Future<void> addMarker(GeoCoordinates coordinates, String markerType,
      {String? customAsset}) async {
    if (mapController == null) return;

    try {
      // Handle marker type-specific logic
      if (markerType == MARKER_TYPE_CUSTOM) {
        // Clear any existing custom markers
        clearMarkers([MARKER_TYPE_CUSTOM]);
      }

      // Get marker image
      MapImage markerImage =
          await _getMarkerImage(markerType, null, customAsset);

      // Create new marker
      MapMarker mapMarker = MapMarker(coordinates, markerImage);
      mapMarker.drawOrder = 1000; // Ensure marker is on top

      // Add marker to map
      mapController?.mapScene.addMapMarker(mapMarker);

      // Store marker reference based on type
      switch (markerType) {
        case MARKER_TYPE_LOCATION:
          if (currentLocationMarker != null) {
            mapController!.mapScene.removeMapMarker(currentLocationMarker!);
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
        case MARKER_TYPE_CATEGORY:
          categoryMarkers.add(mapMarker);
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
        case MARKER_TYPE_CATEGORY:
          for (var marker in categoryMarkers) {
            mapController!.mapScene.removeMapMarker(marker);
          }
          categoryMarkers.clear();
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

      // Initialize the search engine
      _searchEngine = SearchEngine();

      isLoading = false;
      notifyListeners();
    } catch (e) {
      developer.log('Error initializing HERE SDK: $e', name: 'MapProvider');
      errorMessage = 'Failed to initialize HERE SDK: ${e.toString()}';
      isLoading = false;
      notifyListeners();
    }
  }

  /// Completely cleans up all map resources to ensure no persistence between app sessions
  void cleanupMapResources() {
    try {
      if (mapController == null) return;

      // Remove all markers and clear collections
      clearMarkers([
        MARKER_TYPE_LOCATION,
        MARKER_TYPE_DESTINATION,
        MARKER_TYPE_CUSTOM,
        MARKER_TYPE_CATEGORY // Add category markers to cleanup
      ]);

      // Remove search radius circle if it exists
      removeSearchRadiusCircle();

      // Remove Tra Vinh boundary polyline if it exists
      if (traVinhBoundary != null) {
        mapController!.mapScene.removeMapPolyline(traVinhBoundary!);
        traVinhBoundary = null;
      }

      // Reset all marker references to null
      currentLocationMarker = null;
      currentCustomMarker = null;
      destinationMarkers.clear();
      customMarkers.clear();
      categoryMarkers.clear(); // Clear category markers

      // Clear search suggestions
      _searchSuggestions = [];

      developer.log('All map resources have been cleaned up',
          name: 'MapProvider');
    } catch (e) {
      developer.log('Error cleaning up map resources: $e', name: 'MapProvider');
    }
  }

  /// Disposes HERE SDK resources
  Future<void> disposeHERESDK() async {
    // Clean up all map resources first
    cleanupMapResources();

    // Clear all markers before disposing
    if (mapController != null) {
      clearMarkers(
          [MARKER_TYPE_LOCATION, MARKER_TYPE_DESTINATION, MARKER_TYPE_CUSTOM]);
    }

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
      //   if (mapController != null) {
      //     addDestinationMarkers();
      //   }

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
    try {
      isLoading = true;
      notifyListeners();

      // Check location permissions first
      final hasPermission = await handleLocationPermission();
      if (!hasPermission) {
        errorMessage = 'Location permission not granted';
        isLoading = false;
        notifyListeners();
        return;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        errorMessage = 'Location services are disabled';
        isLoading = false;
        notifyListeners();
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
      isLoading = false;

      // If we have the map controller, add a marker at the current position
      if (mapController != null && currentPosition != null) {
        // Clear any existing location marker
        if (currentLocationMarker != null) {
          mapController!.mapScene.removeMapMarker(currentLocationMarker!);
          currentLocationMarker = null;
        }

        // Add a new marker at the current position
        addMarker(
            GeoCoordinates(
                currentPosition!.latitude, currentPosition!.longitude),
            MARKER_TYPE_LOCATION);

        // Move camera to the current position
        moveCamera(
            GeoCoordinates(
                currentPosition!.latitude, currentPosition!.longitude),
            userLocationZoomDistance);

        developer.log(
            'Current position found: ${currentPosition!.latitude}, ${currentPosition!.longitude}',
            name: 'MapProvider');
      }

      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage =
          "Could not determine your location. Please check your device settings.";
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

    // Create a GeoCoordinates object and move camera with more zoom (smaller distance value)
    // Use 500 meters for detailed view instead of 1500
    moveCamera(GeoCoordinates(coordinates[0], coordinates[1]), 500.0);
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
    // Set global language preferences before initializing the map scene
    // These are static properties on HereMapController
    HereMapController.primaryLanguage =
        LanguageCode.viVn; // Vietnamese as primary
    HereMapController.secondaryLanguage =
        LanguageCode.enUs; // English as secondary

    developer.log(
        'Setting map languages: Primary=Vietnamese, Secondary=English',
        name: 'MapProvider');

    mapController = controller;

    // First, clean up any existing resources
    cleanupMapResources();

    // Load the map scene with the normal day scheme
    MapScheme mapScheme = MapScheme.normalNight;

    mapController!.mapScene.enableFeatures({
      MapFeatures.buildingFootprints: MapFeatureModes.buildingFootprintsAll
    });
    mapController!.mapScene.loadSceneForMapScheme(mapScheme, (MapError? error) {
      if (error != null) {
        developer.log('Map scene not loaded. MapError: ${error.toString()}',
            name: 'MapProvider');
        errorMessage = 'Failed to load map scene: ${error.toString()}';
        notifyListeners();
      } else {
        // Clear any existing markers that might be cached from previous sessions
        clearMarkers([
          MARKER_TYPE_LOCATION,
          MARKER_TYPE_DESTINATION,
          MARKER_TYPE_CUSTOM
        ]);

        // Reset marker tracking variables
        currentLocationMarker = null;
        currentCustomMarker = null;

        // First show Tra Vinh province
        refreshMap();

        // Display Tra Vinh province boundary
        displayTraVinhBoundary();

        // Setup gesture listeners for tap and double tap
        setupGestureListeners();

        // Load the "All" category by default
        updateSelectedCategory(0);
      }
    });
  }

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
            name: 'MapProvider');
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
          name: 'MapProvider');
    } catch (e) {
      developer.log('Error displaying Tra Vinh boundary: $e',
          name: 'MapProvider');
    }
  }

  /// Updates the selected category index and performs category search
  void updateSelectedCategory(int index) {
    // Update the category index
    selectedCategoryIndex = index;

    // Clear any existing category search markers
    clearMarkers([MARKER_TYPE_CATEGORY]);

    // Remove search radius circle if it exists
    removeSearchRadiusCircle();

    // If "All" category is selected (index 0), search for all categories
    if (index == 0) {
      searchAllCategories();
    } else {
      // Get the selected category
      final selectedCategory = availableCategories[index];

      // Show the search radius circle for specific categories
      addSearchRadiusCircle();

      // Perform a search for places of this category
      searchLocationsByCategory(selectedCategory);
    }

    notifyListeners();
  }

  /// Search for locations of all available categories
  void searchAllCategories() {
    // Skip the first category which is "All"
    for (int i = 1; i < availableCategories.length; i++) {
      searchLocationsByCategory(availableCategories[i],
          isFromAllCategories: true);
    }
  }

  /// Search for locations based on a category
  Future<void> searchLocationsByCategory(CategoryType categoryType,
      {bool isFromAllCategories = false}) async {
    if (_searchEngine == null) {
      developer.log('Search engine is null', name: 'MapProvider');
      return;
    }

    try {
      // Only set loading state if not part of "All" categories search
      if (!isFromAllCategories) {
        isCategorySearching = true;
        notifyListeners();
      }

      // Create a list with the selected category
      List<PlaceCategory> categoryList = [];
      categoryList.add(PlaceCategory(categoryType.categoryId));

      // Create a search area centered at Tra Vinh
      // Using withCenter method which is known to work with the HERE SDK
      var queryArea =
          CategoryQueryArea.withCenter(GeoCoordinates(traVinhLat, traVinhLon));

      CategoryQuery categoryQuery =
          CategoryQuery.withCategoriesInArea(categoryList, queryArea);

      // Configure search options for Vietnamese language and 30 max results
      SearchOptions searchOptions = SearchOptions();
      searchOptions.languageCode = LanguageCode.viVn;
      searchOptions.maxItems = 30;

      developer.log(
          'Searching for category: ${categoryType.name} with ID: ${categoryType.categoryId}',
          name: 'MapProvider');

      // Execute the search
      _searchEngine!.searchByCategory(categoryQuery, searchOptions,
          (SearchError? searchError, List<Place>? places) async {
        if (searchError != null) {
          developer.log('Category search error: $searchError',
              name: 'MapProvider');
          if (!isFromAllCategories) {
            isCategorySearching = false;
            notifyListeners();
          }
          return;
        }

        // If places is null or empty, try with English language
        if (places == null || places.isEmpty) {
          SearchOptions englishOptions = SearchOptions();
          englishOptions.languageCode = LanguageCode.enUs;
          englishOptions.maxItems = 30;

          developer.log(
              'No Vietnamese results, trying English search for category',
              name: 'MapProvider');

          _searchEngine!.searchByCategory(categoryQuery, englishOptions,
              (SearchError? secondError, List<Place>? englishPlaces) {
            if (!isFromAllCategories) {
              isCategorySearching = false;
            }

            if (secondError != null) {
              developer.log('English category search error: $secondError',
                  name: 'MapProvider');
              if (!isFromAllCategories) {
                notifyListeners();
              }
              return;
            }

            if (englishPlaces != null && englishPlaces.isNotEmpty) {
              _handleCategorySearchResults(englishPlaces, categoryType);
            } else {
              developer.log('No places found for category',
                  name: 'MapProvider');
            }
            if (!isFromAllCategories) {
              notifyListeners();
            }
          });
        } else {
          // Process Vietnamese results
          if (!isFromAllCategories) {
            isCategorySearching = false;
          }
          _handleCategorySearchResults(places, categoryType);
          if (!isFromAllCategories) {
            notifyListeners();
          }
        }
      });
    } catch (e) {
      if (!isFromAllCategories) {
        isCategorySearching = false;
        developer.log('Error in searchLocationsByCategory: $e',
            name: 'MapProvider');
        notifyListeners();
      }
    }
  }

  /// Handle the results from category search
  void _handleCategorySearchResults(
      List<Place> places, CategoryType categoryType) {
    developer.log(
        'Found ${places.length} places for category: ${categoryType.name}',
        name: 'MapProvider');

    // Add a marker for each place found
    for (Place place in places) {
      if (place.geoCoordinates != null) {
        // Store place information in marker metadata for later retrieval on tap
        Metadata metadata = Metadata();
        metadata.setString("place_name", place.title ?? "Unknown Place");
        metadata.setString("place_category", categoryType.vietnameseName);
        if (place.address != null && place.address!.addressText != null) {
          metadata.setString("place_address", place.address!.addressText!);
        }
        metadata.setString("place_category_id", categoryType.categoryId);

        addMarkerWithMetadata(
            place.geoCoordinates!, MARKER_TYPE_CATEGORY, metadata,
            customAsset: categoryType.markerAsset);
      }
    }
  }

  /// Adds a marker to the map with associated metadata
  Future<void> addMarkerWithMetadata(
      GeoCoordinates coordinates, String markerType, Metadata metadata,
      {String? customAsset}) async {
    if (mapController == null) return;

    try {
      // Get marker image
      MapImage markerImage =
          await _getMarkerImage(markerType, null, customAsset);

      // Create new marker
      MapMarker mapMarker = MapMarker(coordinates, markerImage);
      mapMarker.drawOrder = 1000; // Ensure marker is on top
      mapMarker.metadata = metadata; // Set metadata

      // Add marker to map
      mapController?.mapScene.addMapMarker(mapMarker);

      // Store marker reference based on type
      if (markerType == MARKER_TYPE_CATEGORY) {
        categoryMarkers.add(mapMarker);
      }

      // Log the coordinates where marker was placed
      developer.log(
          '$markerType marker added at: ${coordinates.latitude}, ${coordinates.longitude}',
          name: 'MapProvider');
    } catch (e) {
      developer.log('Failed to add marker with metadata: $e',
          name: 'MapProvider');
    }
  }

  /// Returns a Place object from a MapMarker using stored metadata
  Map<String, String>? getPlaceInfoFromMarker(MapMarker marker) {
    if (marker.metadata == null) return null;

    Map<String, String> placeInfo = {};

    try {
      String? name = marker.metadata?.getString("place_name");
      String? category = marker.metadata?.getString("place_category");
      String? address = marker.metadata?.getString("place_address");

      if (name != null) placeInfo['name'] = name;
      if (category != null) placeInfo['category'] = category;
      if (address != null) placeInfo['address'] = address;

      // Add coordinates
      placeInfo['latitude'] = marker.coordinates.latitude.toString();
      placeInfo['longitude'] = marker.coordinates.longitude.toString();

      return placeInfo;
    } catch (e) {
      developer.log('Error getting place info from marker: $e',
          name: 'MapProvider');
      return null;
    }
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

  /// Searches for locations based on query text
  Future<void> searchLocations(String query) async {
    if (_searchEngine == null || query.isEmpty) {
      _searchSuggestions = [];
      notifyListeners();
      return;
    }

    try {
      isSearching = true;
      notifyListeners();

      // Configure search options for Vietnamese language and 30 max results
      SearchOptions searchOptions = SearchOptions();
      searchOptions.languageCode =
          LanguageCode.viVn; // Primary language: Vietnamese
      searchOptions.maxItems = 30;

      // Create a text query area limited to Tra Vinh province
      TextQueryArea queryArea = TextQueryArea.withBox(traVinhGeoBox);

      developer.log('Searching in Vietnamese with query: $query',
          name: 'MapProvider');

      // Call the search engine to get suggestions
      _searchEngine!
          .suggestByText(TextQuery.withArea(query, queryArea), searchOptions,
              (SearchError? searchError, List<Suggestion>? suggestions) {
        if (searchError != null ||
            (suggestions != null && suggestions.isEmpty)) {
          // If no results or error, try with English language
          SearchOptions englishOptions = SearchOptions();
          englishOptions.languageCode =
              LanguageCode.enUs; // Fallback language: English
          englishOptions.maxItems = 30;

          developer.log('No Vietnamese results, trying English search',
              name: 'MapProvider');

          _searchEngine!.suggestByText(
              TextQuery.withArea(query, queryArea), englishOptions,
              (SearchError? secondSearchError,
                  List<Suggestion>? englishSuggestions) {
            isSearching = false;

            if (secondSearchError != null) {
              developer.log('Search error with English: $secondSearchError',
                  name: 'MapProvider');
              _searchSuggestions = [];
            } else if (englishSuggestions != null) {
              _searchSuggestions = englishSuggestions;
              developer.log(
                  'Found ${englishSuggestions.length} English suggestions',
                  name: 'MapProvider');
            } else {
              _searchSuggestions = [];
            }

            notifyListeners();
          });
        } else {
          isSearching = false;

          if (suggestions != null) {
            _searchSuggestions = suggestions;
            developer.log('Found ${suggestions.length} Vietnamese suggestions',
                name: 'MapProvider');
          } else {
            _searchSuggestions = [];
          }

          notifyListeners();
        }
      });
    } catch (e) {
      developer.log('Error searching locations: $e', name: 'MapProvider');
      isSearching = false;
      _searchSuggestions = [];
      notifyListeners();
    }
  }

  /// Handle selection of search suggestion
  void selectSearchSuggestion(Suggestion suggestion) {
    if (_searchEngine == null) return;

    try {
      // Extract information from suggestion
      final title = suggestion.title ?? "";

      // Log the selection
      developer.log('Selected location: $title', name: 'MapProvider');

      // Search for the place by title first in Vietnamese
      SearchOptions viOptions = SearchOptions();
      viOptions.languageCode = LanguageCode.viVn;
      viOptions.maxItems = 1;

      // First, clear existing custom markers
      clearMarkers([MARKER_TYPE_CUSTOM]);

      // Search in Tra Vinh area with Vietnamese language
      _searchEngine!.searchByText(
          TextQuery.withArea(title, TextQueryArea.withBox(traVinhGeoBox)),
          viOptions, (SearchError? searchError, List<Place>? places) {
        if (searchError != null || (places == null || places.isEmpty)) {
          // If no results in Vietnamese, try with English
          SearchOptions enOptions = SearchOptions();
          enOptions.languageCode = LanguageCode.enUs;
          enOptions.maxItems = 1;

          developer.log(
              'No Vietnamese results, trying English search for: $title',
              name: 'MapProvider');

          _searchEngine!.searchByText(
              TextQuery.withArea(title, TextQueryArea.withBox(traVinhGeoBox)),
              enOptions, (SearchError? enSearchError, List<Place>? enPlaces) {
            if (enSearchError != null) {
              developer.log('Error searching place in English: $enSearchError',
                  name: 'MapProvider');
              return;
            }

            if (enPlaces != null &&
                enPlaces.isNotEmpty &&
                enPlaces.first.geoCoordinates != null) {
              // Move camera to the found place
              moveCamera(enPlaces.first.geoCoordinates!, 1000);

              // Add a marker at the location
              addMarker(enPlaces.first.geoCoordinates!, MARKER_TYPE_CUSTOM);

              developer.log(
                  'Found place at ${enPlaces.first.geoCoordinates!.latitude}, ${enPlaces.first.geoCoordinates!.longitude}',
                  name: 'MapProvider');
            }
          });
        } else if (places.isNotEmpty && places.first.geoCoordinates != null) {
          // Results found in Vietnamese
          // Move camera to the found place
          moveCamera(places.first.geoCoordinates!, 1000);

          // Add a marker at the location
          addMarker(places.first.geoCoordinates!, MARKER_TYPE_CUSTOM);

          developer.log(
              'Found place at ${places.first.geoCoordinates!.latitude}, ${places.first.geoCoordinates!.longitude}',
              name: 'MapProvider');
        }
      });

      // Clear suggestions after selecting
      _searchSuggestions = [];
      notifyListeners();
    } catch (e) {
      developer.log('Error in selectSearchSuggestion: $e', name: 'MapProvider');
    }
  }

  /// Clears current search suggestions
  void clearSearchResults() {
    _searchSuggestions = [];
    notifyListeners();
  }

  /// Adds a circle showing the search radius around Tra Vinh center
  void addSearchRadiusCircle() {
    if (mapController == null) return;

    try {
      // Remove any existing search radius circle
      removeSearchRadiusCircle();

      // Create a GeoCircle with the specified radius
      GeoCircle circle = GeoCircle(
          GeoCoordinates(traVinhLat, traVinhLon), searchRadiusInMeters);

      // Convert the GeoCircle to a GeoPolygon
      GeoPolygon circlePolygon = GeoPolygon.withGeoCircle(circle);

      // Create a MapPolygon with semi-transparent blue fill and outline
      searchRadiusCircle = MapPolygon.withOutlineColorAndOutlineWidthInPixels(
          circlePolygon,
          Color.fromARGB(40, 0, 122, 255), // Semi-transparent blue fill
          Color.fromARGB(180, 0, 122, 255), // More opaque blue outline
          2.0 // 2 pixel outline width
          );

      // Add the circle to the map
      mapController!.mapScene.addMapPolygon(searchRadiusCircle!);

      developer.log(
          'Added search radius circle with ${searchRadiusInMeters / 1000}km radius',
          name: 'MapProvider');
    } catch (e) {
      developer.log('Failed to add search radius circle: $e',
          name: 'MapProvider');
    }
  }

  /// Removes the search radius circle from the map
  void removeSearchRadiusCircle() {
    if (mapController == null || searchRadiusCircle == null) return;

    try {
      mapController!.mapScene.removeMapPolygon(searchRadiusCircle!);
      searchRadiusCircle = null;

      developer.log('Removed search radius circle', name: 'MapProvider');
    } catch (e) {
      developer.log('Failed to remove search radius circle: $e',
          name: 'MapProvider');
    }
  }
}
