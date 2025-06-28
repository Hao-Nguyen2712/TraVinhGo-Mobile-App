import 'package:flutter/material.dart';
import '../models/user/user_profile.dart';
import '../services/user_service.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService = UserService();

  UserProfileResponse? _userProfile;
  bool _isLoading = false;
  String? _error;

  UserProfileResponse? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error ?? _userService.lastError;

  // Fetch user profile
  Future<bool> fetchUserProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final profile = await _userService.getUserProfile();

      if (profile != null) {
        _userProfile = profile;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = _userService.lastError;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error fetching profile: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(Map<String, dynamic> profileData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _userService.updateUserProfile(profileData);

      if (success) {
        // Refresh the user profile after update
        await fetchUserProfile();
        return true;
      } else {
        _error = _userService.lastError;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error updating profile: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear user profile data
  void clearUserProfile() {
    _userProfile = null;
    _error = null;
    notifyListeners();
  }
}
