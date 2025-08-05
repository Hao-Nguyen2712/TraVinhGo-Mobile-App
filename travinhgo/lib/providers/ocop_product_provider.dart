import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:travinhgo/models/ocop/ocop_product.dart';
import 'package:travinhgo/services/ocop_product_service.dart';
import 'dart:developer' as developer;
import 'package:diacritic/diacritic.dart';

class OcopProductProvider with ChangeNotifier {
  final OcopProductService _ocopService = OcopProductService();

  final String _cacheBoxName = 'ocopProducts';

  // --- State Variables ---
  List<OcopProduct> _allOcopProducts = []; // Master list for paginated items

  // Pagination State
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMore = true;
  bool _isLoading = false; // For initial load (list)
  bool _isLoadingMore = false; // For subsequent loads (list)
  String? _errorMessage;

  // Filter/Search State
  String? _currentSearchQuery;

  // --- Getters ---
  List<OcopProduct> get ocopProducts {
    List<OcopProduct> filtered = List.from(_allOcopProducts);

    // Apply search query
    if (_currentSearchQuery != null && _currentSearchQuery!.isNotEmpty) {
      final a = _currentSearchQuery!.toLowerCase();
      final formattedQuery = removeDiacritics(a);
      filtered = filtered
          .where((d) => removeDiacritics(d.productName.toLowerCase())
              .contains(formattedQuery))
          .toList();
    }

    return filtered;
  }

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;

  // --- Filter Management ---
  void applySearchQuery(String? searchQuery) {
    _currentSearchQuery = searchQuery;
    notifyListeners();
  }

  // --- Main Data Fetching Method ---
  Future<void> loadInitialOcopProducts() async {
    // 1. Load from cache first to display something immediately
    final cachedProducts = _loadFromCache();
    if (cachedProducts.isNotEmpty) {
      _allOcopProducts = cachedProducts;
      _isLoading = false;
      notifyListeners();
    }

    // 2. Then, fetch from the network to get the latest data
    await fetchOcopProducts(isRefresh: true);
  }

  Future<void> fetchOcopProducts({
    bool isRefresh = false,
  }) async {
    if (_isLoading || (_isLoadingMore && !isRefresh)) return;

    if (isRefresh) {
      _currentPage = 1;
      _hasMore = true;
      _isLoading = true;
      _errorMessage = null;
      // Don't clear the list here if we want to avoid flicker.
      // The new data will replace the old.
      notifyListeners();
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
      // Always call API to get the latest data
      final newOcopProducts = await _ocopService.getOcopProduct(
        pageIndex: _currentPage,
        pageSize: _pageSize,
        searchQuery: _currentSearchQuery,
      );

      if (isRefresh) {
        await _clearCache();
        _allOcopProducts.clear(); // Clear list before adding new fresh data
      }

      if (newOcopProducts.isEmpty || newOcopProducts.length < _pageSize) {
        _hasMore = false;
      }

      _allOcopProducts.addAll(newOcopProducts);
      _currentPage++;

      // Save new data to cache (only save the first page on refresh)
      if (isRefresh && newOcopProducts.isNotEmpty) {
        await _saveToCache(newOcopProducts);
      }

      developer.log(
          'Fetched page $_currentPage. Has more: $_hasMore. Total items: ${_allOcopProducts.length}',
          name: 'OcopProductProvider');
    } catch (e) {
      _errorMessage = "Failed to load ocop product data: ${e.toString()}";
      developer.log(_errorMessage!, name: 'OcopProductProvider');
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  OcopProduct? getProductById(String id) {
    try {
      developer.log('data_ocop: Getting product with ID: $id',
          name: 'ocop_provider');
      return _allOcopProducts.firstWhere((product) => product.id == id);
    } catch (e) {
      developer.log('data_ocop: Product with ID $id not found',
          name: 'ocop_provider');
      return null;
    }
  }

  // --- Cache Helper Methods ---
  Future<void> _saveToCache(List<OcopProduct> ocopProducts) async {
    developer.log('Saving ${ocopProducts.length} OCOP products to cache.',
        name: 'OcopProductProvider');
    final box = Hive.box<OcopProduct>(_cacheBoxName);
    // Use a map with id as key to avoid duplicates
    final Map<String, OcopProduct> ocopProductMap = {
      for (var d in ocopProducts) d.id: d
    };
    await box.putAll(ocopProductMap);
  }

  List<OcopProduct> _loadFromCache() {
    developer.log('Loading OCOP products from cache.',
        name: 'OcopProductProvider');
    final box = Hive.box<OcopProduct>(_cacheBoxName);
    final products = box.values.toList();
    developer.log('Loaded ${products.length} products from cache.',
        name: 'OcopProductProvider');
    return products;
  }

  Future<void> _clearCache() async {
    developer.log('Clearing OCOP product cache.', name: 'OcopProductProvider');
    final box = Hive.box<OcopProduct>(_cacheBoxName);
    await box.clear();
  }
}
