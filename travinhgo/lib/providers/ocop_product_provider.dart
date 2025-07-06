import 'package:flutter/foundation.dart';
import '../models/ocop/ocop_product.dart';
import '../services/ocop_product_service.dart';
import 'dart:developer' as developer;

class OcopProductProvider with ChangeNotifier {
  final OcopProductService _ocopService = OcopProductService();

  List<OcopProduct> _ocopProducts = [];
  bool _isLoaded = false;
  bool _isLoading = false;
  String? _errorMessage;

  List<OcopProduct> get ocopProducts => _ocopProducts;
  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchOcopProducts() async {
    try {
      _isLoading = true;
      notifyListeners();

      developer.log('data_ocop: Starting to fetch OCOP products',
          name: 'ocop_provider');
      final products = await _ocopService.getOcopProduct();
      developer.log('data_ocop: Retrieved ${products.length} OCOP products',
          name: 'ocop_provider');

      _ocopProducts = products;
      _isLoaded = true;
      _errorMessage = null;

      notifyListeners();
      developer.log('data_ocop: OCOP products loaded successfully',
          name: 'ocop_provider');
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      _ocopProducts = [];
      _isLoaded = false;
      developer.log('data_ocop: Error fetching OCOP products: $e',
          name: 'ocop_provider');
      notifyListeners();
    } finally {
      _isLoading = false;
    }
  }

  OcopProduct? getProductById(String id) {
    try {
      developer.log('data_ocop: Getting product with ID: $id',
          name: 'ocop_provider');
      return _ocopProducts.firstWhere((product) => product.id == id);
    } catch (e) {
      developer.log('data_ocop: Product with ID $id not found',
          name: 'ocop_provider');
      return null;
    }
  }
}
