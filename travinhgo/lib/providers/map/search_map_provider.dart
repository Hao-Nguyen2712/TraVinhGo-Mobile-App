import 'package:here_sdk/core.dart';
import 'package:here_sdk/search.dart';
import 'dart:developer' as developer;
import 'dart:async';

import 'base_map_provider.dart';
import 'marker_map_provider.dart';

/// SearchMapProvider handles all search related functionality
class SearchMapProvider {
  // Reference to other providers
  final BaseMapProvider baseMapProvider;
  final MarkerMapProvider markerMapProvider;

  // Search engine and results
  SearchEngine? _searchEngine;
  List<Suggestion> _searchSuggestions = [];
  bool isSearching = false;

  // Getters
  List<Suggestion> get searchSuggestions => _searchSuggestions;

  // Tra Vinh province coordinates
  static const double traVinhLat = 9.9349;
  static const double traVinhLon = 106.3452;

  // Constructor
  SearchMapProvider(this.baseMapProvider, this.markerMapProvider) {
    initializeSearchEngine();
  }

  /// Initialize the search engine
  void initializeSearchEngine() {
    try {
      _searchEngine = SearchEngine();
      developer.log('Search engine initialized', name: 'SearchMapProvider');
    } catch (e) {
      developer.log('Failed to initialize search engine: $e',
          name: 'SearchMapProvider');
    }
  }

  /// GeoBox for Tra Vinh Province
  GeoBox get traVinhGeoBox => GeoBox(
      GeoCoordinates(9.80, 106.10), // Southwest corner
      GeoCoordinates(10.10, 106.60) // Northeast corner
      );

  /// Searches for locations based on query text
  Future<void> searchLocations(String query) async {
    if (_searchEngine == null || query.isEmpty) {
      _searchSuggestions = [];
      return;
    }

    try {
      isSearching = true;

      // Configure search options for Vietnamese language and 30 max results
      SearchOptions searchOptions = SearchOptions();
      searchOptions.languageCode =
          LanguageCode.viVn; // Primary language: Vietnamese
      searchOptions.maxItems = 30;

      // Create a text query area limited to Tra Vinh province
      TextQueryArea queryArea = TextQueryArea.withBox(traVinhGeoBox);

      developer.log('Searching in Vietnamese with query: $query',
          name: 'SearchMapProvider');

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
              name: 'SearchMapProvider');

          _searchEngine!.suggestByText(
              TextQuery.withArea(query, queryArea), englishOptions,
              (SearchError? secondSearchError,
                  List<Suggestion>? englishSuggestions) {
            isSearching = false;

            if (secondSearchError != null) {
              developer.log('Search error with English: $secondSearchError',
                  name: 'SearchMapProvider');
              _searchSuggestions = [];
            } else if (englishSuggestions != null) {
              _searchSuggestions = englishSuggestions;
              developer.log(
                  'Found ${englishSuggestions.length} English suggestions',
                  name: 'SearchMapProvider');
            } else {
              _searchSuggestions = [];
            }
          });
        } else {
          isSearching = false;

          if (suggestions != null) {
            _searchSuggestions = suggestions;
            developer.log('Found ${suggestions.length} Vietnamese suggestions',
                name: 'SearchMapProvider');
          } else {
            _searchSuggestions = [];
          }
        }
      });
    } catch (e) {
      developer.log('Error searching locations: $e', name: 'SearchMapProvider');
      isSearching = false;
      _searchSuggestions = [];
    }
  }

  /// Handle selection of search suggestion
  void selectSearchSuggestion(Suggestion suggestion) {
    if (_searchEngine == null) return;

    try {
      // Extract information from suggestion
      final title = suggestion.title ?? "";

      // Log the selection
      developer.log('Selected location: $title', name: 'SearchMapProvider');

      // Search for the place by title first in Vietnamese
      SearchOptions viOptions = SearchOptions();
      viOptions.languageCode = LanguageCode.viVn;
      viOptions.maxItems = 1;

      // First, clear existing custom markers
      markerMapProvider.clearMarkers([MarkerMapProvider.MARKER_TYPE_CUSTOM]);

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
              name: 'SearchMapProvider');

          _searchEngine!.searchByText(
              TextQuery.withArea(title, TextQueryArea.withBox(traVinhGeoBox)),
              enOptions, (SearchError? enSearchError, List<Place>? enPlaces) {
            if (enSearchError != null) {
              developer.log('Error searching place in English: $enSearchError',
                  name: 'SearchMapProvider');
              return;
            }

            if (enPlaces != null &&
                enPlaces.isNotEmpty &&
                enPlaces.first.geoCoordinates != null) {
              // Move camera to the found place
              baseMapProvider.moveCamera(enPlaces.first.geoCoordinates!, 1000);

              // Add a destination marker at the location
              markerMapProvider.addMarker(enPlaces.first.geoCoordinates!,
                  MarkerMapProvider.MARKER_TYPE_CUSTOM,
                  customAsset: 'assets/images/markers/destination_point.png');

              developer.log(
                  'Found place at ${enPlaces.first.geoCoordinates!.latitude}, ${enPlaces.first.geoCoordinates!.longitude}',
                  name: 'SearchMapProvider');
            }
          });
        } else if (places.isNotEmpty && places.first.geoCoordinates != null) {
          // Results found in Vietnamese
          // Move camera to the found place
          baseMapProvider.moveCamera(places.first.geoCoordinates!, 1000);

          // Add a destination marker at the location
          markerMapProvider.addMarker(places.first.geoCoordinates!,
              MarkerMapProvider.MARKER_TYPE_CUSTOM,
              customAsset: 'assets/images/markers/destination_point.png');

          developer.log(
              'Found place at ${places.first.geoCoordinates!.latitude}, ${places.first.geoCoordinates!.longitude}',
              name: 'SearchMapProvider');
        }
      });

      // Clear suggestions after selecting
      _searchSuggestions = [];
    } catch (e) {
      developer.log('Error in selectSearchSuggestion: $e',
          name: 'SearchMapProvider');
    }
  }

  /// Search for departure locations - for routing
  Future<void> searchDepartureLocations(String query) async {
    // Use the same search method but potentially with different handling
    await searchLocations(query);
  }

  /// Select departure from search suggestion
  void selectDepartureSuggestion(Suggestion suggestion,
      Function(GeoCoordinates, String) onDepartureSelected) {
    if (_searchEngine == null) return;

    try {
      // Extract information from suggestion
      final title = suggestion.title ?? "";

      // Log the selection
      developer.log('Selected departure location: $title',
          name: 'SearchMapProvider');

      // Search for the place by title first in Vietnamese
      SearchOptions viOptions = SearchOptions();
      viOptions.languageCode = LanguageCode.viVn;
      viOptions.maxItems = 1;

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
              'No Vietnamese results, trying English search for departure: $title',
              name: 'SearchMapProvider');

          _searchEngine!.searchByText(
              TextQuery.withArea(title, TextQueryArea.withBox(traVinhGeoBox)),
              enOptions, (SearchError? enSearchError, List<Place>? enPlaces) {
            if (enSearchError != null) {
              developer.log(
                  'Error searching departure place in English: $enSearchError',
                  name: 'SearchMapProvider');
              return;
            }

            if (enPlaces != null &&
                enPlaces.isNotEmpty &&
                enPlaces.first.geoCoordinates != null) {
              // Callback with the found departure point
              onDepartureSelected(enPlaces.first.geoCoordinates!, title);

              developer.log(
                  'Found departure at ${enPlaces.first.geoCoordinates!.latitude}, ${enPlaces.first.geoCoordinates!.longitude}',
                  name: 'SearchMapProvider');
            }
          });
        } else if (places.isNotEmpty && places.first.geoCoordinates != null) {
          // Results found in Vietnamese
          // Callback with the found departure point
          onDepartureSelected(places.first.geoCoordinates!, title);

          developer.log(
              'Found departure at ${places.first.geoCoordinates!.latitude}, ${places.first.geoCoordinates!.longitude}',
              name: 'SearchMapProvider');
        }
      });

      // Clear suggestions after selecting
      _searchSuggestions = [];
    } catch (e) {
      developer.log('Error in selectDepartureSuggestion: $e',
          name: 'SearchMapProvider');
    }
  }

  /// Clears current search suggestions
  void clearSearchResults() {
    _searchSuggestions = [];
  }

  /// Performs reverse geocoding to get address from coordinates
  Future<String?> getAddressFromCoordinates(GeoCoordinates coordinates) async {
    if (_searchEngine == null) {
      developer.log('Search engine not initialized', name: 'SearchMapProvider');
      return null;
    }

    try {
      developer.log(
          'Performing reverse geocoding for: ${coordinates.latitude}, ${coordinates.longitude}',
          name: 'SearchMapProvider');

      // Create completer to handle async result
      Completer<String?> completer = Completer<String?>();

      // Configure search options for Vietnamese language
      SearchOptions searchOptions = SearchOptions();
      searchOptions.languageCode = LanguageCode.viVn;
      searchOptions.maxItems = 1;

      // Perform reverse geocoding
      _searchEngine!.searchByCoordinates(coordinates, searchOptions,
          (SearchError? error, List<Place>? places) {
        if (error != null) {
          developer.log('Reverse geocoding error: $error',
              name: 'SearchMapProvider');

          // Try with English language if Vietnamese fails
          SearchOptions englishOptions = SearchOptions();
          englishOptions.languageCode = LanguageCode.enUs;
          englishOptions.maxItems = 1;

          _searchEngine!.searchByCoordinates(coordinates, englishOptions,
              (SearchError? secondError, List<Place>? englishPlaces) {
            if (secondError != null ||
                englishPlaces == null ||
                englishPlaces.isEmpty) {
              completer.complete(null);
              return;
            }

            // Format the address from the English result
            String? address = _formatAddress(englishPlaces.first);
            completer.complete(address);
          });
        } else if (places != null && places.isNotEmpty) {
          // Format the address from the Vietnamese result
          String? address = _formatAddress(places.first);
          completer.complete(address);
        } else {
          completer.complete(null);
        }
      });

      return await completer.future;
    } catch (e) {
      developer.log('Error in reverse geocoding: $e',
          name: 'SearchMapProvider');
      return null;
    }
  }

  /// Format address from a Place object
  String? _formatAddress(Place place) {
    try {
      var address = place.address;
      if (address == null) {
        return place.title;
      }

      List<String> addressComponents = [];

      // Add street name and house number
      if (address.street != null && address.street!.isNotEmpty) {
        String streetAddress = address.street!;
        if (address.houseNumOrName != null &&
            address.houseNumOrName!.isNotEmpty) {
          streetAddress = "$streetAddress ${address.houseNumOrName}";
        }
        addressComponents.add(streetAddress);
      }

      // Add district or suburb
      if (address.district != null && address.district!.isNotEmpty) {
        addressComponents.add(address.district!);
      } else if (address.subdistrict != null &&
          address.subdistrict!.isNotEmpty) {
        addressComponents.add(address.subdistrict!);
      }

      // Add city
      if (address.city != null && address.city!.isNotEmpty) {
        addressComponents.add(address.city!);
      }

      // Add state
      if (address.state != null && address.state!.isNotEmpty) {
        addressComponents.add(address.state!);
      }

      // Add country
      if (address.country != null && address.country!.isNotEmpty) {
        addressComponents.add(address.country!);
      }

      // Join all parts with commas
      String fullAddress = addressComponents.join(", ");
      return fullAddress.isNotEmpty ? fullAddress : place.title;
    } catch (e) {
      developer.log('Error formatting address: $e', name: 'SearchMapProvider');
      return place.title;
    }
  }
}
