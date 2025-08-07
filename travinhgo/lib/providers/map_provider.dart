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

import '../models/maps/top_favorite_destination.dart';
import '../services/map_service.dart';
import 'ocop_product_provider.dart';

import 'package:travinhgo/models/destination/destination.dart';
import 'package:travinhgo/models/marker/marker_type.dart';
import 'package:travinhgo/providers/destination_provider.dart';

import 'map/base_map_provider.dart';
import 'map/marker_map_provider.dart';
import 'map/navigation_map_provider.dart';
import 'map/location_map_provider.dart';
import 'map/search_map_provider.dart';
import 'map/category_map_provider.dart';
import 'map/boundary_map_provider.dart';
import 'map/ocop_map_provider.dart';
import 'map/local_specialty_map_provider.dart';

// Re-export the TransportMode enum for backward compatibility
export 'map/navigation_map_provider.dart' show TransportMode;

/// DestinationMapProvider handles the display of tourist destinations on the map
class DestinationMapProvider {
  final BaseMapProvider _baseMapProvider;
  final MarkerMapProvider _markerMapProvider;
  final DestinationProvider destinationProvider;

  bool _areDestinationsDisplayed = false;
  int _successfulMarkersCount = 0;
  List<Destination> _allDestinations = [];
  String? _activeFilter;

  // Constants
  static const String MARKER_TYPE_TOURIST_DESTINATION = "tourist_destination";

  DestinationMapProvider(
      this._baseMapProvider, this._markerMapProvider, this.destinationProvider);

  /// Displays all tourist destinations on the map
  /// Returns true if destination data was fetched for the first time.
  Future<bool> displayDestinationMarkers(String? filterTypeId) async {
    bool dataWasFetched = false;
    // Check if map controller is initialized
    if (_baseMapProvider.mapController == null) {
      developer.log(
          'Map controller is not initialized yet. Cannot display destination markers.',
          name: 'DestinationMapProvider');
      return dataWasFetched;
    }

    // If no filter change and markers are already displayed, do nothing
    if (filterTypeId == _activeFilter && _areDestinationsDisplayed) {
      developer.log(
          'Destinations for filter "$_activeFilter" are already displayed.',
          name: 'DestinationMapProvider');
      return dataWasFetched;
    }

    _activeFilter = filterTypeId;

    try {
      // Fetch data only if it hasn't been loaded yet
      if (destinationProvider.allDestinationsForMap.isEmpty) {
        developer.log(
            'No map destinations loaded. Fetching all destinations for map...',
            name: 'DestinationMapProvider');
        await destinationProvider.fetchAllDestinationsForMap();
        _allDestinations = destinationProvider.allDestinationsForMap;
        dataWasFetched = true;
      } else {
        // If data is already loaded, just use it
        _allDestinations = destinationProvider.allDestinationsForMap;
      }

      if (_allDestinations.isEmpty) {
        developer.log('No tourist destinations to display after fetching.',
            name: 'DestinationMapProvider');
        return dataWasFetched;
      }

      // Filter destinations based on the type ID
      final destinationsToDisplay = _activeFilter == null
          ? _allDestinations
          : _allDestinations
              .where((d) => d.destinationTypeId == _activeFilter)
              .toList();

      developer.log(
          'Starting to process ${destinationsToDisplay.length} destinations for filter: $_activeFilter',
          name: 'DestinationMapProvider');

      _successfulMarkersCount = 0;

      // Clear any existing destination markers first
      _markerMapProvider.clearMarkers([MARKER_TYPE_TOURIST_DESTINATION]);

      for (final destination in destinationsToDisplay) {
        developer.log('Processing destination: ${destination.name}',
            name: 'DestinationMapProvider');
        _addDestinationMarker(destination);
      }

      _areDestinationsDisplayed = true;
      developer.log(
          'Successfully displayed $_successfulMarkersCount out of ${destinationsToDisplay.length} tourist destinations for filter: $_activeFilter',
          name: 'DestinationMapProvider');
    } catch (e) {
      developer.log('Error displaying destination markers: $e',
          name: 'DestinationMapProvider');
    }
    return dataWasFetched;
  }

  void _addDestinationMarker(Destination destination) {
    try {
      if (destination.location.coordinates == null ||
          destination.location.coordinates!.length < 2) {
        developer.log(
            'Skipping destination ${destination.name}: No coordinates',
            name: 'DestinationMapProvider');
        return;
      }

      // Enhanced debugging - log raw coordinates
      developer.log(
          'Raw coordinates for ${destination.name}: ${destination.location.coordinates}',
          name: 'DestinationMapProvider');

      // Extract coordinates - API provides [longitude, latitude]
      final double longitude = destination.location.coordinates![0];
      final double latitude = destination.location.coordinates![1];

      // Check for invalid coordinate values
      if (longitude < -180 ||
          longitude > 180 ||
          latitude < -90 ||
          latitude > 90) {
        developer.log(
            'WARNING: Invalid coordinate values for ${destination.name}: [lon=${longitude}, lat=${latitude}]',
            name: 'DestinationMapProvider');
        return; // Skip this destination as coordinates are invalid
      }

      // Check if coordinates are within Vietnam's general boundaries
      bool isInVietnam = longitude >= 102 &&
          longitude <= 110 &&
          latitude >= 8 &&
          latitude <= 24;

      if (!isInVietnam) {
        developer.log(
            'WARNING: Coordinates for ${destination.name} appear to be outside Vietnam: [lon=${longitude}, lat=${latitude}]',
            name: 'DestinationMapProvider');
        // Continue anyway as the check might not be perfect
      }

      // Create GeoCoordinates with correct order (latitude, longitude)
      final coordinates = GeoCoordinates(latitude, longitude);

      developer.log(
          'Converted coordinates for ${destination.name}: lat=${coordinates.latitude}, lon=${coordinates.longitude}',
          name: 'DestinationMapProvider');

      // Get the destination type
      final destinationType = destinationProvider
          .getDestinationTypeById(destination.destinationTypeId);

      if (destinationType == null) {
        developer.log(
            'Destination type not found for ${destination.name} (typeId: ${destination.destinationTypeId})',
            name: 'DestinationMapProvider');
      } else {
        developer.log(
            'Found destination type: ${destinationType.name} for ${destination.name}',
            name: 'DestinationMapProvider');
      }

      // Determine the marker type using our enhanced methods
      final markerType = MarkerType.fromMarkerId(destination.destinationTypeId);

      // Get the asset path for this marker type
      final markerAsset = markerType.getAccessPath();

      developer.log(
          'Adding marker for ${destination.name} at lat: ${coordinates.latitude}, lon: ${coordinates.longitude} with asset: $markerAsset',
          name: 'DestinationMapProvider');

      // Create metadata
      final metadata = Metadata();
      metadata.setString("place_name", destination.name);
      metadata.setString(
          "place_category", destinationType?.name ?? "Destination");
      metadata.setString("destination_id", destination.id);

      // Add more detailed metadata for richer information when tapped
      if (destination.address != null) {
        metadata.setString("place_address", destination.address!);
      }

      // Add rating information
      metadata.setString(
          "place_rating", (destination.avarageRating).toString());

      // Add description if available
      if (destination.description != null) {
        metadata.setString("place_description", destination.description!);
      }

      // Add contact information if available
      if (destination.contact != null) {
        if (destination.contact!.phone != null) {
          metadata.setString("place_phone", destination.contact!.phone!);
        }
        if (destination.contact!.email != null) {
          metadata.setString("place_email", destination.contact!.email!);
        }
        if (destination.contact!.website != null) {
          metadata.setString("place_website", destination.contact!.website!);
        }
      }

      // Add opening hours if available
      if (destination.openingHours != null) {
        String openingInfo = "";
        if (destination.openingHours!.openTime != null) {
          openingInfo += "Open: ${destination.openingHours!.openTime}";
        }
        if (destination.openingHours!.closeTime != null) {
          openingInfo += openingInfo.isNotEmpty ? ", " : "";
          openingInfo += "Close: ${destination.openingHours!.closeTime}";
        }
        if (openingInfo.isNotEmpty) {
          metadata.setString("place_opening_hours", openingInfo);
        }
      }

      // Add image URLs if available
      if (destination.images.isNotEmpty) {
        metadata.setString("place_images", destination.images.join(','));
      }

      // Store coordinates directly in metadata
      metadata.setString("place_lat", coordinates.latitude.toString());
      metadata.setString("place_lon", coordinates.longitude.toString());

      _markerMapProvider.addMarkerWithMetadata(
        coordinates,
        MARKER_TYPE_TOURIST_DESTINATION,
        metadata,
        customAsset: markerAsset,
      );

      _successfulMarkersCount++;
    } catch (e) {
      developer.log(
          'Error adding marker for destination ${destination.name}: $e',
          name: 'DestinationMapProvider');
    }
  }

  void filterDestinationMarkers(String? destinationTypeId) {
    displayDestinationMarkers(destinationTypeId);
  }

  /// Clears all destination markers from the map
  void clearDestinationMarkers() {
    _markerMapProvider.clearMarkers([MARKER_TYPE_TOURIST_DESTINATION]);
    _areDestinationsDisplayed = false;
    _successfulMarkersCount = 0;
    developer.log('Cleared all tourist destination markers.',
        name: 'DestinationMapProvider');
  }
}

/// Main MapProvider that coordinates all the specialized sub-providers
class MapProvider extends ChangeNotifier {
  // Sub-providers
  final BaseMapProvider _baseMapProvider;
  late MarkerMapProvider _markerMapProvider;
  late NavigationMapProvider _navigationMapProvider;
  late LocationMapProvider _locationMapProvider;
  late SearchMapProvider _searchMapProvider;
  late CategoryMapProvider _categoryMapProvider;
  late BoundaryMapProvider _boundaryMapProvider;
  late OcopMapProvider _ocopMapProvider;
  late LocalSpecialtyMapProvider _localSpecialtyMapProvider;
  late DestinationProvider _destinationProvider;
  late DestinationMapProvider _destinationMapProvider;
  bool _destinationCategoriesLoaded = false;

  // POI data storage
  String? lastPoiName;
  String? lastPoiCategory;
  GeoCoordinates? lastPoiCoordinates;
  Metadata? lastPoiMetadata; // Added to store full metadata for OCOP products
  bool showPoiPopup = false; // Flag to control POI popup visibility
  MapMarker? currentCustomMarker; // Reference to the current custom marker
  MapMarker? centerMarker; // Reference to the Tra Vinh center marker
  bool isCenterMarkerVisible =
      false; // Flag to track if center marker is visible

  // Constructor
  MapProvider() : _baseMapProvider = BaseMapProvider() {
    // Initialize sub-providers in the right order
    _markerMapProvider = MarkerMapProvider(_baseMapProvider);
    _navigationMapProvider =
        NavigationMapProvider(_baseMapProvider, _markerMapProvider);
    _locationMapProvider =
        LocationMapProvider(_baseMapProvider, _markerMapProvider);
    _locationMapProvider.onPositionUpdated = () => notifyListeners();
    _searchMapProvider =
        SearchMapProvider(_baseMapProvider, _markerMapProvider);
    _boundaryMapProvider = BoundaryMapProvider(_baseMapProvider);
    _destinationProvider = DestinationProvider();
    _destinationMapProvider = DestinationMapProvider(
        _baseMapProvider, _markerMapProvider, _destinationProvider);
    _localSpecialtyMapProvider =
        LocalSpecialtyMapProvider(_baseMapProvider, _markerMapProvider);
    _categoryMapProvider = CategoryMapProvider(
        _baseMapProvider, _markerMapProvider,
        boundaryProvider: _boundaryMapProvider);

    // Register callback to update UI when route calculation is completed
    _navigationMapProvider.onRouteCalculated = () => notifyListeners();

    // Register callback for OCOP category selection
    _categoryMapProvider.onOcopCategorySelected = () {
      if (_ocopMapProvider != null) {
        developer.log(
            'data_ocop: OCOP category selected via filter, displaying products',
            name: 'MapProvider');
        // Always display products when the category is selected.
        // The deselection logic is handled within CategoryMapProvider.
        displayOcopProducts();
      }
    };
  }

  // Add getter for OCOP map provider
  OcopMapProvider get ocopMapProvider => _ocopMapProvider;

  // Method to initialize the OCOP map provider (called after splash screen)
  void initializeOcopProvider(OcopProductProvider ocopProductProvider) {
    _ocopMapProvider = OcopMapProvider(
        _baseMapProvider, _markerMapProvider, ocopProductProvider);
    developer.log('data_ocop: OcopMapProvider initialized',
        name: 'MapProvider');
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
  String? get destinationAddress => _navigationMapProvider.destinationAddress;
  int? get routeLengthInMeters => _navigationMapProvider.routeLengthInMeters;
  int? get routeDurationInSeconds =>
      _navigationMapProvider.routeDurationInSeconds;
  TransportMode get selectedTransportMode =>
      _navigationMapProvider.selectedTransportMode;
  Map<TransportMode, int> get routeDurations =>
      _navigationMapProvider.routeDurations;
  String? get departureAddress => _navigationMapProvider.departureAddress;

  // Properties from OcopMapProvider
  bool get isOcopDisplayed => _ocopMapProvider.isOcopDisplayed;

  // Properties from LocalSpecialtyMapProvider
  bool get isLocalSpecialtyDisplayed =>
      _localSpecialtyMapProvider.isLocalSpecialtyDisplayed;

  // Other state variables
  int currentDestinationIndex = 0;
  bool destinationsLoaded = false;
  List<TopFavoriteDestination> topDestinations = [];
  final MapService _mapService = MapService();

  /// Updates the map theme based on the provided theme mode.
  void updateMapTheme(ThemeMode themeMode, Brightness platformBrightness) {
    if (mapController == null) {
      return;
    }
    bool isDarkMode = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            platformBrightness == Brightness.dark);
    _baseMapProvider.updateMapScheme(isDarkMode);
  }

  /// Initializes the map scene
  void initMapScene(HereMapController controller, bool isDarkMode) {
    _baseMapProvider.initMapScene(controller, isDarkMode, () async {
      // On successful map scene loading, just move to Tra Vinh center
      // without adding a marker
      refreshMap();
      _boundaryMapProvider.displayTraVinhBoundary();
      _setupGestureListeners();

      // Start preloading all category search data in background
      await _preloadCategories();

      // Display all markers by default
      _displayAllMarkers();

      // Display OCOP products if provider is initialized
      if (_ocopMapProvider != null) {
        developer.log(
            'data_ocop: Displaying OCOP products on map initialization',
            name: 'MapProvider');
        _ocopMapProvider.displayOcopProducts();
      }

      notifyListeners();
    });
  }

  /// Preload all category search data in the background
  Future<void> _preloadCategories() async {
    // First, build the dynamic categories including destination types
    if (!_destinationCategoriesLoaded) {
      await _categoryMapProvider.buildCategories(_destinationProvider);
      _destinationCategoriesLoaded = true;
      // Notify listeners to update the category UI
      notifyListeners();
      // Set the "All" category as selected by default right after they are built
      updateSelectedCategory(0);
    }

    try {
      developer.log('Starting to preload all category data',
          name: 'MapProvider');
      await _categoryMapProvider.preloadAllCategories();
      developer.log('Successfully preloaded all category data',
          name: 'MapProvider');
    } catch (e) {
      developer.log('Error preloading category data: $e', name: 'MapProvider');
    }
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
    // Remove center marker when tapping elsewhere on the map
    if (isCenterMarkerVisible) {
      toggleCenterMarker(); // Use the toggle method to properly handle marker removal
    }

    // In routing mode with departure input active, use the tapped location as departure
    if (isRoutingMode && isShowingDepartureInput) {
      _navigationMapProvider.addDepartureMarker(
          geoCoordinates, "Selected location");
      return;
    }

    // Create a rectangle around the touch point for picking
    Point2D originInPixels = Point2D(touchPoint.x - 25, touchPoint.y - 25);
    Size2D sizeInPixels = Size2D(50, 50);
    Rectangle2D rectangle = Rectangle2D(originInPixels, sizeInPixels);

    // Create a list of map content types to pick from
    List<MapSceneMapPickFilterContentType> contentTypesToPickFrom = [
      MapSceneMapPickFilterContentType.mapItems, // For custom markers
      MapSceneMapPickFilterContentType.mapContent // For embedded POIs
    ];

    // Create filter with the content types
    MapSceneMapPickFilter filter =
        MapSceneMapPickFilter(contentTypesToPickFrom);

    // Use the pick API to find markers and POIs at the touch point
    mapController!.pick(filter, rectangle, (MapPickResult? pickResult) {
      if (pickResult == null) {
        _handleEmptyTap(geoCoordinates);
        return;
      }

      bool handled = false;

      // First check for custom map markers
      if (pickResult.mapItems != null &&
          pickResult.mapItems!.markers.isNotEmpty) {
        handled = _handleMarkerTap(pickResult.mapItems!.markers.first);
      }

      // If no marker was handled, then check for embedded POIs
      if (!handled && pickResult.mapContent != null) {
        PickMapContentResult pickMapContentResult = pickResult.mapContent!;

        // Check for picked places (Carto POIs)
        if (pickMapContentResult.pickedPlaces.isNotEmpty) {
          _handlePickedCartoPOIs(pickMapContentResult.pickedPlaces);
          handled = true;
        }
      }

      // If nothing was picked, handle as an empty tap
      if (!handled) {
        _handleEmptyTap(geoCoordinates);
      }
    });
  }

  // Handle tap on a custom marker
  bool _handleMarkerTap(MapMarker tappedMarker) {
    // Check if this is a marker with metadata
    if (tappedMarker.metadata != null) {
      // Get place information from marker metadata for all markers
      Map<String, String>? placeInfo =
          _markerMapProvider.getPlaceInfoFromMarker(tappedMarker);

      if (placeInfo != null) {
        // Store reference to the tapped marker if it's a custom marker
        if (tappedMarker == _markerMapProvider.currentCustomMarker) {
          currentCustomMarker = tappedMarker;
        }

        // Show POI popup with the place information
        showCategoryMarkerPopup(
            placeInfo, tappedMarker.coordinates, tappedMarker.metadata);
        return true;
      }
    }
    return false;
  }

  // Handle tap on empty map area
  void _handleEmptyTap(GeoCoordinates geoCoordinates) {
    // Close any existing popup
    if (showPoiPopup) {
      closePoiPopup();
    }

    // Add custom marker at the tapped location
    addMarker(geoCoordinates, MarkerMapProvider.MARKER_TYPE_CUSTOM);
  }

  // Handle picked Carto POIs (embedded POIs)
  void _handlePickedCartoPOIs(List<PickedPlace> cartoPOIList) {
    if (cartoPOIList.isEmpty) return;

    // Get the topmost picked place
    PickedPlace topmostPickedPlace = cartoPOIList.first;

    // Extract information
    String poiName = (topmostPickedPlace.name != null &&
            topmostPickedPlace.name!.trim().isNotEmpty)
        ? topmostPickedPlace.name!
        : 'Lat: ${topmostPickedPlace.coordinates.latitude.toStringAsFixed(6)}, Lon: ${topmostPickedPlace.coordinates.longitude.toStringAsFixed(6)}';
    Map<String, String> placeInfo = {
      'name': poiName,
      'category':
          topmostPickedPlace.placeCategoryId.toString() ?? "Unnamed Category",
    };

    // Add coordinates to the place info
    placeInfo['latitude'] = topmostPickedPlace.coordinates.latitude.toString();
    placeInfo['longitude'] =
        topmostPickedPlace.coordinates.longitude.toString();

    // Try to extract more information if available
    try {
      // Log detailed information about the picked POI for debugging
      developer.log('Picked POI details: [0m${topmostPickedPlace.toString()}',
          name: 'MapProvider');

      // Try to get place categories if available
      if (topmostPickedPlace.toString().contains("categories")) {
        placeInfo['category'] = "HERE POI";
      }
    } catch (e) {
      developer.log('Error extracting additional POI details: $e',
          name: 'MapProvider');
    }

    // Log the picked POI
    developer.log(
        'Picked embedded POI: ${placeInfo['name']} at ${placeInfo['latitude']}, ${placeInfo['longitude']}',
        name: 'MapProvider');

    // Show POI popup with the place information
    showCategoryMarkerPopup(placeInfo, topmostPickedPlace.coordinates);
  }

  /// Shows a popup with information about a place from a category marker or embedded POI
  void showCategoryMarkerPopup(
      Map<String, String> placeInfo, GeoCoordinates coordinates,
      [Metadata? metadata]) {
    // Set the POI info
    lastPoiName = placeInfo['name'];
    lastPoiCategory = placeInfo['category'];
    lastPoiCoordinates = coordinates;
    lastPoiMetadata = metadata; // Store full metadata
    showPoiPopup = true;

    // Move camera to the POI location with closer zoom for better visibility
    moveCamera(coordinates, 500);

    // Log the POI being displayed
    developer.log('Showing POI popup for: ${lastPoiName} (${lastPoiCategory})',
        name: 'MapProvider');

    // Notify listeners to update the UI
    notifyListeners();
  }

  /// Closes the POI popup
  void closePoiPopup() {
    showPoiPopup = false;
    lastPoiMetadata = null; // Clear metadata when closing
    notifyListeners();
  }

  /// Toggles display of OCOP products on the map
  void toggleOcopProductDisplay() {
    _ocopMapProvider.toggleOcopProductDisplay();
    notifyListeners();
  }

  /// Toggles display of Local Specialties on the map
  void toggleLocalSpecialtyDisplay() {
    _localSpecialtyMapProvider.toggleLocalSpecialtyDisplay();
    notifyListeners();
  }

  /// Display OCOP products on the map
  void displayOcopProducts() {
    _ocopMapProvider.displayOcopProducts();
    notifyListeners();
  }

  /// Clear OCOP products from the map
  void clearOcopProducts() {
    _ocopMapProvider.clearOcopMarkers();
    notifyListeners();
  }

  /// Display Local Specialties on the map
  void displayLocalSpecialties() {
    _localSpecialtyMapProvider.displayLocalSpecialties();
    notifyListeners();
  }

  /// Clear Local Specialties from the map
  void clearLocalSpecialties() {
    _localSpecialtyMapProvider.clearLocalSpecialtyMarkers();
    notifyListeners();
  }

  /// Updates the selected category index and performs category search
  void updateSelectedCategory(int index) {
    final categoryProvider = _categoryMapProvider;

    // Toggle logic: If the same category is clicked again, toggle it off.
    if (categoryProvider.selectedCategoryIndex == index &&
        categoryProvider.isCategoryActive) {
      categoryProvider.isCategoryActive = false;
      _markerMapProvider.clearMarkers([
        MarkerMapProvider.MARKER_TYPE_CATEGORY,
        MarkerMapProvider.MARKER_TYPE_TOURIST_DESTINATION
      ]);
      _ocopMapProvider.clearOcopMarkers();
      _localSpecialtyMapProvider.clearLocalSpecialtyMarkers();
      categoryProvider.removeSearchRadiusCircle();
      // TODO: Re-enable default POIs when API is clarified
      // mapController?.mapScene.enableFeatures({MapFeatures.poi: MapFeatureModes.all});
      notifyListeners();
      return;
    }

    categoryProvider.isCategoryActive = true;
    categoryProvider.selectedCategoryIndex = index;

    // --- Start with a clean slate ---
    // Clear all custom markers from previous selections
    _markerMapProvider.clearMarkers([
      MarkerMapProvider.MARKER_TYPE_CATEGORY,
      MarkerMapProvider.MARKER_TYPE_TOURIST_DESTINATION
    ]);
    _ocopMapProvider.clearOcopMarkers();
    _localSpecialtyMapProvider.clearLocalSpecialtyMarkers();
    categoryProvider.removeSearchRadiusCircle();

    final selectedCategory = categoryProvider.availableCategories[index];

    // --- Apply the new filter ---
    if (selectedCategory.name == "All") {
      // For "All", show everything: custom markers and default HERE POIs
      // TODO: Re-enable default POIs when API is clarified
      // mapController?.mapScene.enableFeatures({MapFeatures.poi: MapFeatureModes.all});
      _displayAllMarkers();
    } else {
      // For any specific category, hide the default HERE POIs to avoid clutter
      // TODO: Disable default POIs when API is clarified
      // mapController?.mapScene.disableFeatures({MapFeatures.poi: MapFeatureModes.all});
      categoryProvider.addSearchRadiusCircle();

      if (selectedCategory.isDestinationType) {
        _destinationMapProvider
            .displayDestinationMarkers(selectedCategory.categoryId);
      } else if (selectedCategory.name == "OCOP") {
        _ocopMapProvider.displayOcopProducts();
      } else if (selectedCategory.name == "Đặc sản") {
        _localSpecialtyMapProvider.displayLocalSpecialties();
      } else {
        // It's a standard POI category
        _categoryMapProvider.displayCategoryPlaces(selectedCategory);
      }
    }
    notifyListeners();
  }

  /// Displays all markers on the map, including destinations, OCOPs, and POIs
  void _displayAllMarkers() {
    // TODO: Re-enable default POIs when API is clarified
    // mapController?.mapScene.enableFeatures({MapFeatures.poi: MapFeatureModes.all});
    _destinationMapProvider.displayDestinationMarkers(null);
    _categoryMapProvider.displayAllCategories();
    _ocopMapProvider.displayOcopProducts();
    _localSpecialtyMapProvider.displayLocalSpecialties();
  }

  /// Get category icon by index
  String getCategoryIcon(int index) {
    return _categoryMapProvider.getCategoryIcon(index);
  }

  /// Get the category icon based on selection state
  String getCategoryIconForState(int index, bool isSelected) {
    return _categoryMapProvider.getCategoryIconForState(index, isSelected);
  }

  /// Checks if a category's icon is tintable
  bool isCategoryTintable(int index) {
    return _categoryMapProvider.isCategoryTintable(index);
  }

  /// Gets the current user position
  Future<void> getCurrentPosition() async {
    await _locationMapProvider.getCurrentPosition();
  }

  /// Moves the camera to a specified location with a given zoom distance
  void moveCamera(GeoCoordinates coordinates, [double? distanceInMeters]) {
    _baseMapProvider.moveCamera(coordinates, distanceInMeters);
  }

  /// Refreshes the map to show Tra Vinh province
  void refreshMap() {
    // Move to Tra Vinh center without adding a marker
    _boundaryMapProvider.moveToTraVinhCenter();
  }

  /// Toggle the center marker visibility
  void toggleCenterMarker() {
    // Define Tra Vinh center coordinates directly
    final centerCoordinates = GeoCoordinates(
        BoundaryMapProvider.traVinhLat, BoundaryMapProvider.traVinhLon);

    // If center marker is visible, remove it
    if (isCenterMarkerVisible) {
      if (centerMarker != null) {
        _markerMapProvider.removeMarker(centerMarker!);
        centerMarker = null;
      }
      isCenterMarkerVisible = false;
      developer.log('Center marker removed', name: 'MapProvider');
    } else {
      // Add center marker if not visible
      // Create a custom marker type specifically for the center marker
      _markerMapProvider.addMarker(
          centerCoordinates, MarkerMapProvider.MARKER_TYPE_CUSTOM,
          customAsset: "assets/images/markers/marker.png");

      // Get reference to the marker that was just added
      centerMarker = _markerMapProvider.currentCustomMarker;

      // Safety check to ensure marker was created
      if (centerMarker != null) {
        isCenterMarkerVisible = true;
        developer.log('Center marker added', name: 'MapProvider');
      } else {
        developer.log('Failed to create center marker', name: 'MapProvider');
      }
    }

    notifyListeners();
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
        (coordinates, name) async {
      _navigationMapProvider.addDepartureMarker(coordinates, name);
      await _navigationMapProvider.updateAddressesFromCoordinates();
      // Batch state updates and notify once to prevent race conditions
      _navigationMapProvider.hideDepartureInput();
      _searchMapProvider.clearSearchResults();
      notifyListeners();
    });
  }

  /// Sets transport mode for routing
  void setTransportMode(TransportMode mode) {
    _navigationMapProvider.setTransportMode(mode);
    notifyListeners();
  }

  /// Sets up the routing mode
  void startRouting(GeoCoordinates coordinates, String name) {
    _navigationMapProvider.startRouting(coordinates, name);

    // Update addresses using reverse geocoding
    _navigationMapProvider.updateAddressesFromCoordinates();

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

  /// Shows the departure input field
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
    // When user interacts with the slider, close any open POI popup
    if (showPoiPopup) {
      closePoiPopup();
    }

    currentDestinationIndex = index;

    if (topDestinations.isNotEmpty && index < topDestinations.length) {
      final destination = topDestinations[index];
      if (destination.latitude != null && destination.longitude != null) {
        final coordinates =
            GeoCoordinates(destination.latitude!, destination.longitude!);
        moveCamera(coordinates, 1000.0); // Zoom closer
      }
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
      // Ensure all destinations are loaded for the map first
      if (_destinationProvider.allDestinationsForMap.isEmpty) {
        await _destinationProvider.fetchAllDestinationsForMap();
      }

      // Get the full list of destinations
      final allDestinations = _destinationProvider.allDestinationsForMap;

      // Sort destinations by average rating in descending order
      allDestinations.sort(
          (a, b) => (b.avarageRating ?? 0.0).compareTo(a.avarageRating ?? 0.0));

      // Take the top 5
      final top5 = allDestinations.take(5).toList();

      // Convert Destination objects to TopFavoriteDestination objects
      topDestinations = top5.map((dest) {
        return TopFavoriteDestination(
          dest.id,
          dest.name,
          dest.images.isNotEmpty ? dest.images.first : '',
          dest.avarageRating,
          dest.description ?? '',
          dest.location.coordinates?[1], // Latitude
          dest.location.coordinates?[0], // Longitude
        );
      }).toList();

      destinationsLoaded = true;
      developer.log(
          'Loaded top 5 destinations based on rating: ${topDestinations.map((d) => d.name).join(', ')}',
          name: 'MapProvider');
    } catch (e) {
      errorMessage = "Failed to load top destinations: ${e.toString()}";
      developer.log(errorMessage!, name: 'MapProvider');
    } finally {
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
    if (_ocopMapProvider != null) {
      _ocopMapProvider.clearOcopMarkers();
    }
    _localSpecialtyMapProvider.clearLocalSpecialtyMarkers();

    // Clear POI data
    lastPoiName = null;
    lastPoiCategory = null;
    lastPoiCoordinates = null;
    lastPoiMetadata = null;
    showPoiPopup = false;
    currentCustomMarker = null;
  }

  /// Completely disposes HERE SDK resources
  Future<void> disposeHERESDK() async {
    await _baseMapProvider.disposeHERESDK();
  }

  /// Update addresses for both departure and destination points
  Future<void> updateAddresses() async {
    await _navigationMapProvider.updateAddressesFromCoordinates();
    notifyListeners();
  }
}
