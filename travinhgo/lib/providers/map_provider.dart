import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/core.engine.dart';
import 'package:here_sdk/gestures.dart';
import 'package:here_sdk/search.dart';
import 'package:here_sdk/routing.dart' as here_sdk;
import 'package:geolocator/geolocator.dart';
import 'package:travinhgo/models/maps/geo_boundary_travinh.dart';
import 'package:travinhgo/utils/env_config.dart';
import 'dart:developer' as developer;
import 'dart:ui' show Color;

import '../Models/Maps/top_favorite_destination.dart';
import '../services/map_service.dart';

import 'map/base_map_provider.dart';
import 'map/marker_map_provider.dart';
import 'map/navigation_map_provider.dart';
import 'map/location_map_provider.dart';
import 'map/search_map_provider.dart';
import 'map/category_map_provider.dart';
import 'map/boundary_map_provider.dart';

// Re-export the TransportMode enum for backward compatibility
export 'map/navigation_map_provider.dart' show TransportMode;

/// Main MapProvider that coordinates all the specialized sub-providers
class MapProvider extends ChangeNotifier {
  // Sub-providers
  final BaseMapProvider _baseMapProvider = BaseMapProvider();
  late MarkerMapProvider _markerMapProvider;
  late NavigationMapProvider _navigationMapProvider;
  late LocationMapProvider _locationMapProvider;
  late SearchMapProvider _searchMapProvider;
  late CategoryMapProvider _categoryMapProvider;
  late BoundaryMapProvider _boundaryMapProvider;

  // POI data storage
  String? lastPoiName;
  String? lastPoiCategory;
  GeoCoordinates? lastPoiCoordinates;
  bool showPoiPopup = false; // Flag to control POI popup visibility
  MapMarker? currentCustomMarker; // Reference to the current custom marker

  // Constructor
  MapProvider() {
    // Initialize sub-providers in the right order
    _markerMapProvider = MarkerMapProvider(_baseMapProvider);
    _navigationMapProvider =
        NavigationMapProvider(_baseMapProvider, _markerMapProvider);
    _locationMapProvider =
        LocationMapProvider(_baseMapProvider, _markerMapProvider);
    _searchMapProvider =
        SearchMapProvider(_baseMapProvider, _markerMapProvider);
    _categoryMapProvider =
        CategoryMapProvider(_baseMapProvider, _markerMapProvider);
    _boundaryMapProvider = BoundaryMapProvider(_baseMapProvider);
  }

  // Forward property access to sub-providers for backward compatibility

  // Properties from BaseMapProvider
  HereMapController? get mapController => _baseMapProvider.mapController;
  String? get errorMessage => _baseMapProvider.errorMessage;
  set errorMessage(String? value) => _baseMapProvider.errorMessage = value;
  bool get isLoading => _baseMapProvider.isLoading;
  set isLoading(bool value) => _baseMapProvider.isLoading = value;
  GlobalKey<ScaffoldMessengerState> get scaffoldMessengerKey =>
      _baseMapProvider.scaffoldMessengerKey;

  // Properties from CategoryMapProvider
  List<String> get categories => _categoryMapProvider.categories;
  int get selectedCategoryIndex => _categoryMapProvider.selectedCategoryIndex;
  bool get isCategoryActive => _categoryMapProvider.isCategoryActive;
  bool get isCategorySearching => _categoryMapProvider.isCategorySearching;

  // Properties from LocationMapProvider
  Position? get currentPosition => _locationMapProvider.currentPosition;

  // Properties from SearchMapProvider
  List<Suggestion> get searchSuggestions =>
      _searchMapProvider.searchSuggestions;
  bool get isSearching => _searchMapProvider.isSearching;

  // Properties from NavigationMapProvider
  bool get isRoutingMode => _navigationMapProvider.isRoutingMode;
  bool get isShowingDepartureInput =>
      _navigationMapProvider.isShowingDepartureInput;
  bool get isCalculatingRoute => _navigationMapProvider.isCalculatingRoute;
  String? get routeErrorMessage => _navigationMapProvider.routeErrorMessage;
  GeoCoordinates? get departureCoordinates =>
      _navigationMapProvider.departureCoordinates;
  String? get departureName => _navigationMapProvider.departureName;
  GeoCoordinates? get destinationCoordinates =>
      _navigationMapProvider.destinationCoordinates;
  String? get destinationName => _navigationMapProvider.destinationName;
  int? get routeLengthInMeters => _navigationMapProvider.routeLengthInMeters;
  int? get routeDurationInSeconds =>
      _navigationMapProvider.routeDurationInSeconds;
  TransportMode get selectedTransportMode =>
      _navigationMapProvider.selectedTransportMode;
  Map<TransportMode, int> get routeDurations =>
      _navigationMapProvider.routeDurations;

  // Other state variables
  int currentDestinationIndex = 0;
  bool destinationsLoaded = false;
  List<TopFavoriteDestination> topDestinations = [];
  final MapService _mapService = MapService();

  /// Initialize the HERE SDK
  Future<void> initializeHERESDK() async {
    await _baseMapProvider.initializeHERESDK();
    notifyListeners();
  }

  /// Initializes the map scene
  void initMapScene(HereMapController controller) {
    _baseMapProvider.initMapScene(controller, () {
      // On successful map scene loading
      refreshMap();
      _boundaryMapProvider.displayTraVinhBoundary();
      _setupGestureListeners();

      // Load the "All" category by default
      updateSelectedCategory(0);

      notifyListeners();
    });
  }

  /// Sets up tap listener for the map
  void _setupGestureListeners() {
    if (mapController == null) return;

    // Setup tap listener for POI and marker detection
    mapController!.gestures.tapListener = TapListener((Point2D touchPoint) {
      var geoCoordinates = mapController?.viewToGeoCoordinates(touchPoint);
      if (geoCoordinates != null) {
        handleMapTap(touchPoint, geoCoordinates);
      }
    });
  }

  /// Handle map tap events
  void handleMapTap(Point2D touchPoint, GeoCoordinates geoCoordinates) {
    // In routing mode with departure input active, use the tapped location as departure
    if (isRoutingMode && isShowingDepartureInput) {
      _navigationMapProvider.addDepartureMarker(
          geoCoordinates, "Selected location");
      return;
    }

    // Create a small rectangle around the touch point for picking
    final size = Size2D(20, 20); // 10 pixels radius in each direction
    final origin = Point2D(touchPoint.x - 10, touchPoint.y - 10);
    final Rectangle2D pickArea = Rectangle2D(origin, size);

    // Use the pick API to find markers at the touch point
    mapController!.pick(null, pickArea, (MapPickResult? pickResult) {
      // Check if any markers were picked
      if (pickResult == null ||
          pickResult.mapItems == null ||
          pickResult.mapItems!.markers.isEmpty) {
        // No marker was tapped, close any open POI popup
        if (showPoiPopup) {
          closePoiPopup();
        }
        return;
      }

      // A marker was tapped
      MapMarker tappedMarker = pickResult.mapItems!.markers.first;

      // Check if this is a marker with metadata
      if (tappedMarker.metadata != null) {
        // Get place information from marker metadata
        Map<String, String>? placeInfo =
            _markerMapProvider.getPlaceInfoFromMarker(tappedMarker);

        if (placeInfo != null) {
          // Show POI popup with the place information
          showCategoryMarkerPopup(placeInfo, tappedMarker.coordinates);
        }
      }
    });
  }

  /// Shows a popup with information about a place from a category marker
  void showCategoryMarkerPopup(
      Map<String, String> placeInfo, GeoCoordinates coordinates) {
    // Set the POI info
    lastPoiName = placeInfo['name'];
    lastPoiCategory = placeInfo['category'];
    lastPoiCoordinates = coordinates;
    showPoiPopup = true;

    // Move camera to the POI location
    moveCamera(coordinates, 500);

    // Notify listeners
    notifyListeners();
  }

  /// Closes the POI popup
  void closePoiPopup() {
    showPoiPopup = false;
    notifyListeners();
  }

  /// Updates the selected category index and performs category search
  void updateSelectedCategory(int index) {
    _categoryMapProvider.updateSelectedCategory(index);
    notifyListeners();
  }

  /// Get category icon by index
  String getCategoryIcon(int index) {
    return _categoryMapProvider.getCategoryIcon(index);
  }

  /// Gets the current user position
  Future<void> getCurrentPosition() async {
    await _locationMapProvider.getCurrentPosition();
    notifyListeners();
  }

  /// Moves the camera to a specified location with a given zoom distance
  void moveCamera(GeoCoordinates coordinates, [double? distanceInMeters]) {
    _baseMapProvider.moveCamera(coordinates, distanceInMeters);
  }

  /// Refreshes the map to show Tra Vinh province
  void refreshMap() {
    _boundaryMapProvider.moveToTraVinhCenter();
  }

  /// Searches for locations based on query text
  Future<void> searchLocations(String query) async {
    await _searchMapProvider.searchLocations(query);
    notifyListeners();
  }

  /// Handle selection of search suggestion
  void selectSearchSuggestion(Suggestion suggestion) {
    _searchMapProvider.selectSearchSuggestion(suggestion);
    notifyListeners();
  }

  /// Clears current search suggestions
  void clearSearchResults() {
    _searchMapProvider.clearSearchResults();
    notifyListeners();
  }

  /// Searches for departure locations
  Future<void> searchDepartureLocations(String query) async {
    await _searchMapProvider.searchDepartureLocations(query);
    notifyListeners();
  }

  /// Select a departure suggestion
  void selectDepartureSuggestion(Suggestion suggestion) {
    _searchMapProvider.selectDepartureSuggestion(suggestion,
        (coordinates, name) {
      _navigationMapProvider.addDepartureMarker(coordinates, name);
      notifyListeners();
    });
  }

  /// Sets transport mode for routing
  void setTransportMode(TransportMode mode) {
    _navigationMapProvider.setTransportMode(mode);
    notifyListeners();
  }

  /// Starts routing mode
  void startRouting(GeoCoordinates coordinates, String name) {
    _navigationMapProvider.startRouting(coordinates, name);
    notifyListeners();
  }

  /// Cancels routing mode
  void cancelRouting() {
    _navigationMapProvider.cancelRouting();
    notifyListeners();
  }

  /// Adds a departure marker
  void addDepartureMarker(GeoCoordinates coordinates, String name) {
    _navigationMapProvider.addDepartureMarker(coordinates, name);
    notifyListeners();
  }

  /// Use Tra Vinh center as departure point
  void useTraVinhCenterAsDeparture() {
    _navigationMapProvider.useTraVinhCenterAsDeparture();
    notifyListeners();
  }

  /// Swap departure and destination
  void swapDepartureAndDestination() {
    _navigationMapProvider.swapDepartureAndDestination();
    notifyListeners();
  }

  /// Shows the departure input UI
  void showDepartureInput() {
    _navigationMapProvider.showDepartureInput();
    notifyListeners();
  }

  /// Hides the departure input UI
  void hideDepartureInput() {
    _navigationMapProvider.hideDepartureInput();
    notifyListeners();
  }

  /// Adds a marker of a specific type
  Future<void> addMarker(GeoCoordinates coordinates, String markerType,
      {String? customAsset}) async {
    await _markerMapProvider.addMarker(coordinates, markerType,
        customAsset: customAsset);

    // Update currentCustomMarker reference if it's a custom marker
    if (markerType == MarkerMapProvider.MARKER_TYPE_CUSTOM) {
      currentCustomMarker = _markerMapProvider.currentCustomMarker;
    }

    notifyListeners();
  }

  /// Gets place info from a marker
  Map<String, String>? getPlaceInfoFromMarker(MapMarker marker) {
    return _markerMapProvider.getPlaceInfoFromMarker(marker);
  }

  /// Clears markers of specified types
  void clearMarkers(List<String> markerTypes) {
    _markerMapProvider.clearMarkers(markerTypes);
    notifyListeners();
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

  /// Moves to a specific destination
  void moveToDestination(String id) {
    // Get coordinates for the destination
    final coordinates = _mapService.getDestinationCoordinates()[id];
    if (coordinates == null) return;

    // Create a GeoCoordinates object and move camera with more zoom
    moveCamera(GeoCoordinates(coordinates[0], coordinates[1]), 500.0);
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
      notifyListeners();
    } catch (e) {
      developer.log('Error loading top destinations: $e', name: 'MapProvider');
      isLoading = false;
      destinationsLoaded = false;
      topDestinations = [];
      notifyListeners();
    }
  }

  /// Cleans up map resources
  void cleanupMapResources() {
    _markerMapProvider.cleanupMarkerResources();
    _navigationMapProvider.cleanupNavigationResources();
    _categoryMapProvider.cleanupCategoryResources();
    _boundaryMapProvider.cleanupBoundaryResources();
    _baseMapProvider.cleanupMapResources();

    // Clear POI data
    lastPoiName = null;
    lastPoiCategory = null;
    lastPoiCoordinates = null;
    showPoiPopup = false;
    currentCustomMarker = null;
  }

  /// Completely disposes HERE SDK resources
  Future<void> disposeHERESDK() async {
    await _baseMapProvider.disposeHERESDK();
  }
}
