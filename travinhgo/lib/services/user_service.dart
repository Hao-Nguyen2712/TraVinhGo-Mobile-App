import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user/user_profile.dart';
import '../utils/env_config.dart';
import 'package:http_parser/http_parser.dart' show MediaType;

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
        debugPrint('Response received: ${response.data}');

        // Direct initialization from the response data
        // This handles both nested data and direct object formats
        if (response.data != null) {
          Map<String, dynamic> userData;

          if (response.data is Map<String, dynamic>) {
            // If response.data is already a map
            if (response.data.containsKey('data')) {
              final data = response.data['data'];

              // Handle string data (JSON string)
              if (data is String) {
                userData = jsonDecode(data);
              }
              // Handle direct object/map data
              else if (data is Map<String, dynamic>) {
                userData = data;
              }
              // Direct data in response
              else {
                userData = response.data;
              }
            } else {
              // If 'data' key is not present, use response.data directly
              userData = response.data;
            }
          } else {
            // If response.data is not a map, convert to string then parse
            userData = jsonDecode(response.data.toString());
          }

          debugPrint('User data for profile: $userData');

          // Create profile object with the normalized data
          final profile = UserProfileResponse.fromJson(userData);
          debugPrint(
              'Created profile object: email=${profile.email}, avatar=${profile.avatar}');

          if (profile.email.isNotEmpty || profile.avatar.isNotEmpty) {
            debugPrint('Valid profile data found');
          } else {
            debugPrint(
                'Profile data may be incomplete: ${profile.email}, ${profile.avatar}');
          }

          return profile;
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
  Future<UserProfileResponse?> updateUserProfile(
      Map<String, dynamic> profileData,
      {File? imageFile}) async {
    try {
      // Get session ID from secure storage
      final sessionId = await _secureStorage.read(key: 'session_id');

      if (sessionId == null) {
        _lastError = 'No session ID found. Please login again.';
        return null;
      }

      // Create form data for multipart request
      final formData = FormData();

      // Add profile data fields
      if (profileData['fullname'] != null) {
        formData.fields.add(MapEntry('FullName', profileData['fullname']));
      }
      if (profileData['phone'] != null) {
        formData.fields.add(MapEntry('PhoneNumber', profileData['phone']));
      }
      if (profileData['email'] != null) {
        formData.fields.add(MapEntry('Email', profileData['email']));
      }
      if (profileData['address'] != null) {
        formData.fields.add(MapEntry('Address', profileData['address']));
      }
      if (profileData['gender'] != null) {
        formData.fields.add(MapEntry('Gender', profileData['gender']));
      }
      if (profileData['dateOfBirth'] != null) {
        formData.fields
            .add(MapEntry('DateOfBirth', profileData['dateOfBirth']));
      }

      // Add image file if provided
      if (imageFile != null) {
        final fileName = imageFile.path.split('/').last;
        formData.files.add(
          MapEntry(
            'imageFile',
            await MultipartFile.fromFile(
              imageFile.path,
              filename: fileName,
              contentType:
                  MediaType('image', 'jpeg'), // Adjust content type as needed
            ),
          ),
        );
      }

      debugPrint('Sending profile update with data: ${formData.fields}');
      if (imageFile != null) {
        debugPrint('Including image file: ${imageFile.path}');
      }

      final response = await dio.put(
        '$_baseUrl/Users/update-user-profile',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            'sessionId': sessionId,
          },
        ),
      );

      if (response.statusCode == 200) {
        debugPrint('Profile updated successfully: ${response.data}');

        // Parse the response data to get the updated profile
        if (response.data != null) {
          Map<String, dynamic> userData;

          if (response.data is Map<String, dynamic>) {
            // If response.data is already a map
            if (response.data.containsKey('data')) {
              final data = response.data['data'];

              // Handle string data (JSON string)
              if (data is String) {
                userData = jsonDecode(data);
              }
              // Handle direct object/map data
              else if (data is Map<String, dynamic>) {
                userData = data;
              }
              // Direct data in response
              else {
                userData = response.data;
              }
            } else {
              // If 'data' key is not present, use response.data directly
              userData = response.data;
            }
          } else {
            // If response.data is not a map, convert to string then parse
            userData = jsonDecode(response.data.toString());
          }

          debugPrint('Parsed updated user data: $userData');

          // Create profile object with the normalized data
          final profile = UserProfileResponse.fromJson(userData);
          debugPrint(
              'Created updated profile object: email=${profile.email}, avatar=${profile.avatar}');

          return profile;
        }

        _lastError = 'Failed to parse profile data from response';
        return null;
      } else {
        _lastError =
            'Failed to update profile. Status code: ${response.statusCode}';
        debugPrint(_lastError);
        return null;
      }
    } on DioException catch (e) {
      _lastError = _getDioErrorMessage(e);
      debugPrint('DioException during updateUserProfile: $e');
      return null;
    } catch (e) {
      _lastError = 'Error updating profile: ${e.toString()}';
      debugPrint('Error during updateUserProfile: $e');
      return null;
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
