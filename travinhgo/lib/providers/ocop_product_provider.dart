import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:travinhgo/models/ocop/ocop_product.dart';
import 'package:travinhgo/services/ocop_product_service.dart';
import 'dart:developer' as developer;

class OcopProductProvider with ChangeNotifier {
  final OcopProductService _ocopService = OcopProductService();
  final String _cacheBoxName = 'ocopProducts';

  // --- State ---
  List<OcopProduct> _ocopProducts = [];
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMore = true;
  bool _isLoading = false; // For initial load and refresh
  bool _isLoadingMore = false; // For loading more items
  String? _errorMessage;
  String? _currentSearchQuery;
  bool _isSearchActive = false;

  // --- Getters ---
  List<OcopProduct> get ocopProducts => _ocopProducts;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;

  // --- Search Management ---
  void applySearchQuery(String? searchQuery) {
    _currentSearchQuery = searchQuery;
    if (searchQuery != null && searchQuery.isNotEmpty) {
      _isSearchActive = true;
      searchOcopProducts(searchQuery);
    } else {
      _isSearchActive = false;
      refreshProducts(); // Reset to the full list
    }
  }

  Future<void> searchOcopProducts(String query) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final searchResult = await _ocopService.searchOcopProducts(query);
      _ocopProducts = searchResult;
      _hasMore = false; // Search results are not paginated
    } catch (e) {
      _errorMessage = "Failed to search for OCOP products: ${e.toString()}";
      developer.log(_errorMessage!, name: 'OcopProductProvider');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Data Fetching Logic ---

  /// Loads initial products. Uses cache for instant UI, then fetches fresh data.
  /// Call this from `initState`.
  Future<void> loadInitialProducts() async {
    _isLoading = true;
    // Don't notify yet, let cache load first

    final cachedProducts = _loadFromCache();
    if (cachedProducts.isNotEmpty) {
      _ocopProducts = cachedProducts;
      _isLoading = false; // Show cached data immediately
      notifyListeners();
    }

    // Fetch fresh data from the network
    await refreshProducts();
  }

  /// Fetches the first page of products, replacing the current list.
  /// Use for pull-to-refresh.
  Future<void> refreshProducts() async {
    if (_isSearchActive) {
      _isSearchActive = false;
      _currentSearchQuery = null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newProducts = await _ocopService.getOcopProduct(
        pageIndex: 1,
        pageSize: _pageSize,
      );

      _ocopProducts = newProducts;
      _currentPage = 1;
      _hasMore = newProducts.length >= _pageSize;

      // Update cache with the fresh first page
      await _clearCache();
      if (newProducts.isNotEmpty) {
        await _saveToCache(newProducts);
      }
    } catch (e) {
      _errorMessage = "Failed to load OCOP products: ${e.toString()}";
      developer.log(_errorMessage!, name: 'OcopProductProvider');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches the next page of products and appends them to the list.
  /// Use for infinite scrolling.
  Future<void> loadMoreProducts() async {
    if (_isLoading || _isLoadingMore || !_hasMore || _isSearchActive) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final newProducts = await _ocopService.getOcopProduct(
        pageIndex: nextPage,
        pageSize: _pageSize,
      );

      if (newProducts.isEmpty) {
        _hasMore = false;
      } else {
        _ocopProducts.addAll(newProducts);
        _currentPage = nextPage;
        _hasMore = newProducts.length >= _pageSize;
      }
    } catch (e) {
      // Optionally handle error, e.g., show a toast
      developer.log("Failed to load more OCOP products: ${e.toString()}",
          name: 'OcopProductProvider');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  OcopProduct? getProductById(String id) {
    try {
      return _ocopProducts.firstWhere((product) => product.id == id);
    } catch (e) {
      developer.log('Product with ID $id not found in provider',
          name: 'OcopProductProvider');
      return null;
    }
  }

  // --- Cache Helper Methods ---
  Future<void> _saveToCache(List<OcopProduct> products) async {
    final box = Hive.box<OcopProduct>(_cacheBoxName);
    final Map<String, OcopProduct> productMap = {
      for (var p in products) p.id: p
    };
    await box.putAll(productMap);
  }

  List<OcopProduct> _loadFromCache() {
    final box = Hive.box<OcopProduct>(_cacheBoxName);
    return box.values.toList();
  }

  Future<void> _clearCache() async {
    final box = Hive.box<OcopProduct>(_cacheBoxName);
    await box.clear();
  }
}
