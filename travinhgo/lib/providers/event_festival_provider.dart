import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/event_festival/event_and_festival.dart';
import '../services/event_festival_service.dart';

class EventFestivalProvider with ChangeNotifier {
  List<EventAndFestival> _eventFestivals = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  String _searchQuery = '';
  int _currentPage = 1;
  final int _limit = 10;
  Timer? _debounce;
  final _eventFestivalBox = Hive.box<EventAndFestival>('eventFestivals');

  List<EventAndFestival> get eventFestivals => _eventFestivals;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  Future<void> fetchEventFestivals({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
      _eventFestivals = [];
      _hasMore = true;
      _isLoading = true;
      notifyListeners();
    } else {
      if (_isLoadingMore || !_hasMore) return;
      _isLoadingMore = true;
      notifyListeners();
    }

    var connectivityResult = await (Connectivity().checkConnectivity());
    bool isConnected = connectivityResult != ConnectivityResult.none;

    try {
      if (isConnected) {
        if (_searchQuery.isNotEmpty) {
          final newItems =
              await EventFestivalService().searchEventFestivals(_searchQuery);
          if (isRefresh) {
            _eventFestivals.clear();
          }
          _eventFestivals.addAll(newItems);
          _hasMore = false;
        } else {
          final newItems = await EventFestivalService()
              .getEventFestivalsPaging(_currentPage, _limit);
          if (isRefresh) {
            await _eventFestivalBox.clear();
          }
          for (var item in newItems) {
            _eventFestivalBox.put(item.id, item);
          }
          if (newItems.length < _limit) {
            _hasMore = false;
          }
          _eventFestivals.addAll(newItems);
          _currentPage++;
        }
      } else {
        if (_currentPage == 1) {
          _eventFestivals = _eventFestivalBox.values.toList();
          _hasMore = false;
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      if (_currentPage == 1) {
        _eventFestivals = _eventFestivalBox.values.toList();
        _hasMore = false;
      }
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void applySearchQuery(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (query != _searchQuery) {
        _searchQuery = query;
        fetchEventFestivals(isRefresh: true);
      }
    });
  }
}
