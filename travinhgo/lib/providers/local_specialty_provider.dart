import 'package:flutter/material.dart';
import 'package:travinhgo/models/local_specialties/local_specialties.dart';
import 'package:travinhgo/services/local_specialtie_service.dart';

class LocalSpecialtyProvider with ChangeNotifier {
  final LocalSpecialtieService _localSpecialtieService =
      LocalSpecialtieService();

  List<LocalSpecialties> _localSpecialties = [];
  String? _errorMessage;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _pageNumber = 1;
  final int _pageSize = 10;
  String? _searchQuery;

  List<LocalSpecialties> get localSpecialties => _localSpecialties;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  void applySearchQuery(String? query) {
    _searchQuery = query;
    fetchLocalSpecialties(isRefresh: true);
  }

  Future<void> fetchLocalSpecialties({bool isRefresh = false}) async {
    if (isRefresh) {
      _pageNumber = 1;
      _localSpecialties = [];
      _hasMore = true;
      _isLoading = true;
    } else {
      if (_isLoadingMore || !_hasMore) return;
      _isLoadingMore = true;
    }
    notifyListeners();

    try {
      List<LocalSpecialties> newItems;
      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        newItems =
            await _localSpecialtieService.searchLocalSpecialties(_searchQuery!);
        _hasMore = false;
      } else {
        newItems = await _localSpecialtieService.getLocalSpecialtiesPaging(
          pageNumber: _pageNumber,
          pageSize: _pageSize,
        );
        if (newItems.length < _pageSize) {
          _hasMore = false;
        }
        _pageNumber++;
      }

      if (isRefresh) {
        _localSpecialties.clear();
      }
      _localSpecialties.addAll(newItems);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi khi tải dữ liệu. Vui lòng thử lại.';
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }
}
