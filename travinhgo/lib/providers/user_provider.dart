import 'package:flutter/material.dart';
import '../models/user/user_profile.dart';
import '../services/user_service.dart';
import 'dart:io';

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
  Future<bool> updateUserProfile(Map<String, dynamic> profileData,
      {File? imageFile}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedProfile = await _userService.updateUserProfile(profileData,
          imageFile: imageFile);

      if (updatedProfile != null) {
        // Update the user profile directly with the returned data
        _userProfile = updatedProfile;
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
