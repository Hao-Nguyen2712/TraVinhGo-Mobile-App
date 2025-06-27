import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user/user_profile.dart';
import '../utils/env_config.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Dio dio = Dio();
  String? _lastError;

  factory UserService() {
    return _instance;
  }

  // Getter for last error message
  String? get lastError => _lastError;

  UserService._internal() {
    dio.options.connectTimeout = const Duration(seconds: 500);
    dio.options.receiveTimeout = const Duration(seconds: 500);
    dio.options.sendTimeout = const Duration(seconds: 500);
  }

  // Base URL from environment config
  final String _baseUrl = EnvConfig.apiBaseUrl;

  // Get user profile
  Future<UserProfileResponse?> getUserProfile() async {
    try {
      // Get session ID from secure storage
      final sessionId = await _secureStorage.read(key: 'session_id');

      if (sessionId == null) {
        _lastError = 'No session ID found. Please login again.';
        return null;
      }

      final response = await dio.get(
        '$_baseUrl/Users/user-profile',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'sessionId': sessionId,
          },
        ),
      );

      if (response.statusCode == 200) {
        // Check if the response has data
        if (response.data != null && response.data['data'] != null) {
          // Parse the data from the response
          final data = response.data['data'];

          // If data is a string (JSON string), parse it
          if (data is String) {
            final jsonData = jsonDecode(data);
            return UserProfileResponse.fromJson(jsonData);
          }
          // If data is already a Map, use it directly
          else if (data is Map<String, dynamic>) {
            return UserProfileResponse.fromJson(data);
          }
        }

        _lastError = 'Invalid response format from server';
        return null;
      } else {
        _lastError =
            'Failed to load profile. Status code: ${response.statusCode}';
        return null;
      }
    } on DioException catch (e) {
      _lastError = _getDioErrorMessage(e);
      debugPrint('DioException during getUserProfile: $e');
      return null;
    } catch (e) {
      _lastError = 'Error loading profile: ${e.toString()}';
      debugPrint('Error during getUserProfile: $e');
      return null;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      // Get session ID from secure storage
      final sessionId = await _secureStorage.read(key: 'session_id');

      if (sessionId == null) {
        _lastError = 'No session ID found. Please login again.';
        return false;
      }

      final response = await dio.put(
        '$_baseUrl/Users/update-profile',
        data: profileData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'sessionId': sessionId,
          },
        ),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        _lastError =
            'Failed to update profile. Status code: ${response.statusCode}';
        return false;
      }
    } on DioException catch (e) {
      _lastError = _getDioErrorMessage(e);
      debugPrint('DioException during updateUserProfile: $e');
      return false;
    } catch (e) {
      _lastError = 'Error updating profile: ${e.toString()}';
      debugPrint('Error during updateUserProfile: $e');
      return false;
    }
  }

  // Helper method to get error message from DioException
  String _getDioErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timed out. Please check your internet connection.';
      case DioExceptionType.sendTimeout:
        return 'Request timed out. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Server response timed out. Please try again.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          return 'Authentication failed. Please login again.';
        } else if (statusCode == 403) {
          return 'Access denied. You don\'t have permission.';
        } else if (statusCode == 404) {
          return 'Resource not found.';
        } else if (statusCode == 500) {
          return 'Server error. Please try again later.';
        } else {
          return 'Error: ${e.response?.statusMessage ?? 'Unknown error'}';
        }
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.unknown:
        return 'Network error. Please check your internet connection.';
      default:
        return 'An unexpected error occurred.';
    }
  }
}
