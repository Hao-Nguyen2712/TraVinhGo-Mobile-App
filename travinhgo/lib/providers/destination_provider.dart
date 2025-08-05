import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:travinhgo/models/destination/destination.dart';
import 'package:travinhgo/models/destination_types/destination_type.dart';
import 'package:travinhgo/models/marker/marker.dart';
import 'package:travinhgo/services/destination_service.dart';
import 'package:travinhgo/services/destination_type_service.dart';
import 'package:travinhgo/services/marker_service.dart';
import 'dart:developer' as developer;
import 'package:diacritic/diacritic.dart';

class DestinationProvider with ChangeNotifier {
  final DestinationService _destinationService = DestinationService();
  final DestinationTypeService _destinationTypeService =
      DestinationTypeService();
  final MarkerService _markerService = MarkerService();

  final String _cacheBoxName = 'destinations';

  // --- State Variables ---
  List<Destination> _allDestinations = []; // Master list for paginated items
  List<Destination> _mapDestinations = []; // Complete list for the map
  List<DestinationType> _destinationTypes = [];
  List<Marker> _markers = [];

  // Pagination State
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMore = true;
  bool _isLoading = false; // For initial load (list)
  bool _isLoadingMore = false; // For subsequent loads (list)
  bool _isMapDataLoading = false; // For map data loading
  String? _errorMessage;

  // Filter/Search State
  String? _currentSearchQuery;
  String? _currentTypeId;

  // --- Getters ---
  List<Destination> get destinations {
    List<Destination> filtered = List.from(_allDestinations);

    // Apply search query
    if (_currentSearchQuery != null && _currentSearchQuery!.isNotEmpty) {
      final a = _currentSearchQuery!.toLowerCase();
      final formattedQuery = removeDiacritics(a);
      filtered = filtered
          .where((d) =>
              removeDiacritics(d.name.toLowerCase()).contains(formattedQuery))
          .toList();
    }

    // Apply type filter
    if (_currentTypeId != null) {
      filtered =
          filtered.where((d) => d.destinationTypeId == _currentTypeId).toList();
    }

    return filtered;
  }

  List<Destination> get allDestinationsForMap => _mapDestinations;
  List<Destination> get allDestinations => _allDestinations;
  List<DestinationType> get destinationTypes => _destinationTypes;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isMapDataLoading => _isMapDataLoading;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;

  // --- Filter Management ---
  void applySearchQuery(String? searchQuery) {
    _currentSearchQuery = searchQuery;
    notifyListeners();
  }

  Future<void> applyCategoryFilter(String? typeId) async {
    _currentTypeId = typeId;
    notifyListeners();
    await fetchDestinations(isRefresh: true);
  }

  // --- Main Data Fetching Method ---
  Future<void> fetchDestinations({
    bool isRefresh = false,
  }) async {
    if (_isLoading || (_isLoadingMore && !isRefresh)) return;

    if (isRefresh) {
      _currentPage = 1;
      _hasMore = true;
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // 1. Load from cache first
      final cachedDestinations = _loadFromCache();
      if (cachedDestinations.isNotEmpty) {
        _allDestinations = cachedDestinations;
        // Temporarily turn off loading to show cached data immediately
        _isLoading = false;
        notifyListeners();
      }
    } else {
      _isLoadingMore = true;
      notifyListeners();
    }

    if (!_hasMore && !isRefresh) {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
      return;
    }

    try {
      // 2. Always call API to get the latest data
      final newDestinations = await _destinationService.getDestination(
        pageIndex: _currentPage,
        pageSize: _pageSize,
        searchQuery: _currentSearchQuery,
        typeId: _currentTypeId,
      );

      if (isRefresh) {
        _allDestinations =
            []; // Clear old data (from cache) to replace with new data from network
        await _clearCache(); // Clear old cache
      }

      if (newDestinations.isEmpty || newDestinations.length < _pageSize) {
        _hasMore = false;
      }

      _allDestinations.addAll(newDestinations);
      _currentPage++;

      // 3. Save new data to cache (only save the first page on refresh)
      if (isRefresh && newDestinations.isNotEmpty) {
        await _saveToCache(newDestinations);
      }

      developer.log(
          'Fetched page $_currentPage. Has more: $_hasMore. Total items: ${_allDestinations.length}',
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

  // --- Helper method to fetch all destinations for the map ---
  Future<void> fetchAllDestinationsForMap() async {
    if (_mapDestinations.isNotEmpty || _isMapDataLoading) {
      return; // Avoid refetching if already loaded or loading
    }
    _isMapDataLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _mapDestinations = await _destinationService.getAllDestinations();
      developer.log(
          'Fetched all ${_mapDestinations.length} destinations for map view.',
          name: 'DestinationProvider');
    } catch (e) {
      _errorMessage = "Failed to load map destination data: ${e.toString()}";
      developer.log(_errorMessage!, name: 'DestinationProvider');
    } finally {
      _isMapDataLoading = false;
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

  // --- Cache Helper Methods ---
  Future<void> _saveToCache(List<Destination> destinations) async {
    final box = Hive.box<Destination>(_cacheBoxName);
    // Use a map with id as key to avoid duplicates
    final Map<String, Destination> destinationMap = {
      for (var d in destinations) d.id: d
    };
    await box.putAll(destinationMap);
  }

  List<Destination> _loadFromCache() {
    final box = Hive.box<Destination>(_cacheBoxName);
    return box.values.toList();
  }

  Future<void> _clearCache() async {
    final box = Hive.box<Destination>(_cacheBoxName);
    await box.clear();
  }
}
