import 'package:flutter/foundation.dart';
import 'package:travinhgo/models/destination/destination.dart';
import 'package:travinhgo/models/destination_types/destination_type.dart';
import 'package:travinhgo/models/marker/marker.dart';
import 'package:travinhgo/services/destination_service.dart';
import 'package:travinhgo/services/destination_type_service.dart';
import 'package:travinhgo/services/marker_service.dart';
import 'dart:developer' as developer;

class DestinationProvider with ChangeNotifier {
  final DestinationService _destinationService = DestinationService();
  final DestinationTypeService _destinationTypeService =
      DestinationTypeService();
  final MarkerService _markerService = MarkerService();

  // --- State Variables ---
  List<Destination> _destinations = [];
  List<DestinationType> _destinationTypes = [];
  List<Marker> _markers = [];

  // Pagination State
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMore = true;
  bool _isLoading = false; // For initial load
  bool _isLoadingMore = false; // For subsequent loads
  String? _errorMessage;

  // Filter/Search State
  String? _currentSearchQuery;
  String? _currentTypeId;

  // --- Getters ---
  List<Destination> get destinations => _destinations;
  List<DestinationType> get destinationTypes => _destinationTypes;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;

  // --- Main Data Fetching Method ---
  Future<void> fetchDestinations({
    bool isRefresh = false,
    String? searchQuery,
    String? typeId,
  }) async {
    // Prevent concurrent calls
    if (_isLoading || (_isLoadingMore && !isRefresh)) return;

    // If the search query or filter has changed, force a refresh.
    if (searchQuery != _currentSearchQuery || typeId != _currentTypeId) {
      isRefresh = true;
    }

    if (isRefresh) {
      _currentPage = 1;
      _hasMore = true;
      _destinations = [];
      _currentSearchQuery = searchQuery;
      _currentTypeId = typeId;
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    } else {
      // If not a refresh, it's a "load more" action
      _isLoadingMore = true;
      notifyListeners();
    }

    // If we've already loaded everything, don't make another API call
    if (!_hasMore && !isRefresh) {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
      return;
    }

    try {
      // Fetch data from the service with pagination and search parameters
      final newDestinations = await _destinationService.getDestination(
        pageIndex: _currentPage,
        pageSize: _pageSize,
        searchQuery: _currentSearchQuery,
        // Assuming the service will be updated to handle typeId
        // typeId: _currentTypeId,
      );

      if (newDestinations.isEmpty || newDestinations.length < _pageSize) {
        _hasMore = false;
      }

      _destinations.addAll(newDestinations);
      _currentPage++;

      developer.log(
          'Fetched page $_currentPage. Has more: $_hasMore. Total items: ${_destinations.length}',
          name: 'DestinationProvider');
    } catch (e) {
      _errorMessage = "Failed to load destination data: ${e.toString()}";
      developer.log(_errorMessage!, name: 'DestinationProvider');
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // --- Helper method to fetch types (can be called once) ---
  Future<void> fetchDestinationTypes() async {
    try {
      final results = await Future.wait([
        _destinationTypeService.getMarkers(),
        _markerService.getMarkers(),
      ]);
      _destinationTypes = results[0] as List<DestinationType>;
      _markers = results[1] as List<Marker>;

      for (var type in _destinationTypes) {
        try {
          type.marker = _markers.firstWhere((m) => m.id == type.markerId);
        } catch (e) {
          developer.log(
              'Marker not found for DestinationType ID: ${type.id}, Marker ID: ${type.markerId}',
              name: 'DestinationProvider');
        }
      }
      developer.log(
          'Fetched ${_destinationTypes.length} types and ${_markers.length} markers.',
          name: 'DestinationProvider');
    } catch (e) {
      _errorMessage = "Failed to load destination types: ${e.toString()}";
      developer.log(_errorMessage!, name: 'DestinationProvider');
    }
    notifyListeners();
  }

  DestinationType? getDestinationTypeById(String typeId) {
    try {
      return _destinationTypes.firstWhere((type) => type.id == typeId);
    } catch (e) {
      return null;
    }
  }
}
