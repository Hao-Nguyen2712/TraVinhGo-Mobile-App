import 'package:flutter/material.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/search.dart';
import 'dart:developer' as developer;

import 'base_map_provider.dart';
import 'marker_map_provider.dart';

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

/// CategoryMapProvider handles all category filtering and POI display functionality
class CategoryMapProvider {
  // Reference to other providers
  final BaseMapProvider baseMapProvider;
  final MarkerMapProvider markerMapProvider;

  // Category state variables
  int selectedCategoryIndex = 0;
  bool isCategoryActive = true;
  bool isCategorySearching = false; // Flag to track category search progress

  // Search engine
  SearchEngine? _searchEngine;

  // Search radius visualization
  MapPolygon? searchRadiusCircle;

  // Store Place objects by their coordinates (as string key)
  final Map<String, Place> _placeObjects = {};

  // Constants
  static const double traVinhLat = 9.9349;
  static const double traVinhLon = 106.3452;
  static const double searchRadiusInMeters = 10000; // 10km radius for searching

  // Get mapController from baseMapProvider
  HereMapController? get mapController => baseMapProvider.mapController;

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

  // Categories for filter buttons - populated from availableCategories Vietnamese names
  List<String> get categories =>
      availableCategories.map((cat) => cat.vietnameseName).toList();

  // Constructor
  CategoryMapProvider(this.baseMapProvider, this.markerMapProvider) {
    initializeSearchEngine();
  }

  /// Initialize the search engine for category searches
  void initializeSearchEngine() {
    try {
      _searchEngine = SearchEngine();
      developer.log('Category search engine initialized',
          name: 'CategoryMapProvider');
    } catch (e) {
      developer.log('Failed to initialize category search engine: $e',
          name: 'CategoryMapProvider');
    }
  }

  /// Get category icon by index
  String getCategoryIcon(int index) {
    if (index < 0 || index >= availableCategories.length) {
      return "assets/images/navigations/map.png"; // Default icon
    }
    return availableCategories[index].iconAsset;
  }

  /// Updates the selected category index and performs category search
  void updateSelectedCategory(int index) {
    // Check if the user is clicking the already selected category
    if (selectedCategoryIndex == index && isCategoryActive) {
      // Toggle off the category - turning off the filter
      isCategoryActive = false;

      // Clear any existing category search markers
      markerMapProvider.clearMarkers([MarkerMapProvider.MARKER_TYPE_CATEGORY]);

      // Remove search radius circle if it exists
      removeSearchRadiusCircle();
      return;
    }

    // Either selecting a new category or re-enabling a previously toggled off category
    isCategoryActive = true;

    // Update the category index
    selectedCategoryIndex = index;

    // Clear any existing category search markers
    markerMapProvider.clearMarkers([MarkerMapProvider.MARKER_TYPE_CATEGORY]);

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
      developer.log('Search engine is null', name: 'CategoryMapProvider');
      return;
    }

    try {
      // Only set loading state if not part of "All" categories search
      if (!isFromAllCategories) {
        isCategorySearching = true;
      }

      // Create a list with the selected category
      List<PlaceCategory> categoryList = [];
      categoryList.add(PlaceCategory(categoryType.categoryId));

      // Create a search area centered at Tra Vinh
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
          name: 'CategoryMapProvider');

      // Execute the search
      _searchEngine!.searchByCategory(categoryQuery, searchOptions,
          (SearchError? searchError, List<Place>? places) async {
        if (searchError != null) {
          developer.log('Category search error: $searchError',
              name: 'CategoryMapProvider');
          if (!isFromAllCategories) {
            isCategorySearching = false;
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
              name: 'CategoryMapProvider');

          _searchEngine!.searchByCategory(categoryQuery, englishOptions,
              (SearchError? secondError, List<Place>? englishPlaces) {
            if (!isFromAllCategories) {
              isCategorySearching = false;
            }

            if (secondError != null) {
              developer.log('English category search error: $secondError',
                  name: 'CategoryMapProvider');
              return;
            }

            if (englishPlaces != null && englishPlaces.isNotEmpty) {
              _handleCategorySearchResults(englishPlaces, categoryType);
            } else {
              developer.log('No places found for category',
                  name: 'CategoryMapProvider');
            }
          });
        } else {
          // Process Vietnamese results
          if (!isFromAllCategories) {
            isCategorySearching = false;
          }
          _handleCategorySearchResults(places, categoryType);
        }
      });
    } catch (e) {
      if (!isFromAllCategories) {
        isCategorySearching = false;
        developer.log('Error in searchLocationsByCategory: $e',
            name: 'CategoryMapProvider');
      }
    }
  }

  /// Handle the results from category search
  void _handleCategorySearchResults(
      List<Place> places, CategoryType categoryType) async {
    developer.log(
        'Found ${places.length} places for category: ${categoryType.name}',
        name: 'CategoryMapProvider');

    // Filter places using the Point-in-Polygon algorithm
    for (Place place in places) {
      if (place.geoCoordinates != null) {
        // Create rich metadata for POI display
        Metadata metadata = Metadata();
        metadata.setString("place_name", place.title ?? "Unknown Place");
        metadata.setString("place_category", categoryType.vietnameseName);

        // Store address information
        if (place.address != null) {
          if (place.address!.addressText != null) {
            metadata.setString("place_address", place.address!.addressText!);
          }

          // Store additional address details if available
          if (place.address!.city != null) {
            metadata.setString("place_city", place.address!.city!);
          }
          if (place.address!.state != null) {
            metadata.setString("place_state", place.address!.state!);
          }
        }

        // Store coordinates
        metadata.setDouble("place_lat", place.geoCoordinates!.latitude);
        metadata.setDouble("place_lon", place.geoCoordinates!.longitude);

        // Store category ID for filtering
        metadata.setString("place_category_id", categoryType.categoryId);

        // Store a reference to identify this is a HERE SDK Place
        metadata.setString("is_here_place", "true");

        // Generate a unique key for this place based on its coordinates
        String placeKey =
            "${place.geoCoordinates!.latitude},${place.geoCoordinates!.longitude}";

        // Store the Place object for later retrieval
        _placeObjects[placeKey] = place;

        // Add phone information if available - using proper HERE SDK API
        try {
          if (place.details != null && place.details!.contacts != null) {
            // Extract phone number using proper HERE SDK structure
            String? phoneNumber = _extractPhoneNumber(place);
            if (phoneNumber != null && phoneNumber.isNotEmpty) {
              metadata.setString("place_phone", phoneNumber);
            }
          }
        } catch (e) {
          developer.log('Failed to extract phone number: $e',
              name: 'CategoryMapProvider');
        }

        // Add marker with metadata
        markerMapProvider.addMarkerWithMetadata(place.geoCoordinates!,
            MarkerMapProvider.MARKER_TYPE_CATEGORY, metadata,
            customAsset: categoryType.markerAsset);
      }
    }
  }

  /// Helper method to extract phone number from Place object
  String? _extractPhoneNumber(Place place) {
    try {
      if (place.details == null || place.details!.contacts == null) {
        return null;
      }

      // Different versions of the HERE SDK might have different structures
      // Try to access phone information using available properties
      var contacts = place.details!.contacts;

      // Try to get phone from the place details without assuming specific structure
      if (contacts.toString().contains('phone')) {
        // If there's phone data in the contacts, try to extract it from the debug string
        String contactsStr = contacts.toString();
        RegExp phonePattern = RegExp(r'phone[:\s]+([0-9+\-() ]+)');
        Match? match = phonePattern.firstMatch(contactsStr);
        if (match != null && match.group(1) != null) {
          return match.group(1)!.trim();
        }
      }

      return null;
    } catch (e) {
      developer.log('Error extracting phone number: $e',
          name: 'CategoryMapProvider');
      return null;
    }
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
          name: 'CategoryMapProvider');
    } catch (e) {
      developer.log('Failed to add search radius circle: $e',
          name: 'CategoryMapProvider');
    }
  }

  /// Removes the search radius circle from the map
  void removeSearchRadiusCircle() {
    if (mapController == null || searchRadiusCircle == null) return;

    try {
      mapController!.mapScene.removeMapPolygon(searchRadiusCircle!);
      searchRadiusCircle = null;

      developer.log('Removed search radius circle',
          name: 'CategoryMapProvider');
    } catch (e) {
      developer.log('Failed to remove search radius circle: $e',
          name: 'CategoryMapProvider');
    }
  }

  /// Gets the HERE Place object by coordinates if available
  Place? getPlaceByCoordinates(GeoCoordinates coordinates) {
    String key = "${coordinates.latitude},${coordinates.longitude}";
    return _placeObjects[key];
  }

  /// Clears the stored Place objects
  void clearPlaceObjects() {
    _placeObjects.clear();
  }

  /// Cleanup category resources
  void cleanupCategoryResources() {
    removeSearchRadiusCircle();
    clearPlaceObjects();
    markerMapProvider.clearMarkers([MarkerMapProvider.MARKER_TYPE_CATEGORY]);
    developer.log('Category resources cleaned up', name: 'CategoryMapProvider');
  }
}
