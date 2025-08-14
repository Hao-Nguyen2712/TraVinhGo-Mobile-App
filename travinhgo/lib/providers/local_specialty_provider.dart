import 'package:flutter/material.dart';
import 'package:travinhgo/models/local_specialties/local_specialties.dart';
import 'package:travinhgo/services/local_specialtie_service.dart';

class LocalSpecialtyProvider with ChangeNotifier {
  final LocalSpecialtieService _localSpecialtieService =
      LocalSpecialtieService();

  List<LocalSpecialties> _localSpecialties = [];
  final Set<String> _loadedSpecialtyIds = <String>{}; // Chống trùng lặp
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
    // Khi refresh, reset lại trạng thái phân trang và bật cờ loading
    if (isRefresh) {
      _pageNumber = 1;
      _hasMore = true;
      _isLoading = true;
      _localSpecialties.clear(); // Xóa danh sách cũ
      _loadedSpecialtyIds.clear(); // Xóa ID đã tải
    } else {
      // Ngăn việc tải thêm nếu đang tải hoặc đã hết dữ liệu
      if (_isLoadingMore || !_hasMore) return;
      _isLoadingMore = true;
    }
    notifyListeners();

    try {
      final List<LocalSpecialties> newItems;

      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        newItems =
            await _localSpecialtieService.searchLocalSpecialties(_searchQuery!);
        _hasMore = newItems.length == _pageSize;
      } else {
        newItems = await _localSpecialtieService.getLocalSpecialtiesPaging(
          pageNumber: _pageNumber,
          pageSize: _pageSize,
        );
        if (newItems.length < _pageSize) {
          _hasMore = false;
        }
      }

      // Lọc ra các mục chưa được thêm vào danh sách
      final uniqueNewItems =
          newItems.where((item) => _loadedSpecialtyIds.add(item.id)).toList();

      if (isRefresh) {
        _localSpecialties = uniqueNewItems;
      } else {
        _localSpecialties.addAll(uniqueNewItems);
      }

      // Chỉ tăng số trang nếu không phải là tìm kiếm và đã tải thành công
      if ((_searchQuery == null || _searchQuery!.isEmpty) &&
          uniqueNewItems.isNotEmpty) {
        _pageNumber++;
      }

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
