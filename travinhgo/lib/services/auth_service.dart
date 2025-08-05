import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'dart:io';
import 'package:dio/io.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:travinhgo/main.dart';
import 'package:travinhgo/screens/auth/login_screen.dart';

import '../utils/env_config.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  String? _otpToken;
  String? _lastError;
  bool _isRefreshing = false;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  factory AuthService() {
    return _instance;
  }

  // Getter for last error message
  String? get lastError => _lastError;

  AuthService._internal() {
    debugPrint(
        "AUTH_SERVICE: Initializing AuthService with base URL: $_baseUrl");

    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    dio.options.sendTimeout = const Duration(seconds: 30);

    debugPrint(
        "AUTH_SERVICE: Dio timeouts configured: connect=30s, receive=30s, send=30s");

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      debugPrint(
          "AUTH_SERVICE: HTTP client configured to accept all certificates");
      return client;
    };

    // Add interceptor to handle 401 responses
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          if (error.response?.statusCode == 401) {
            if (await refreshToken()) {
              // Retry the original request
              try {
                final response = await dio.request(
                  error.requestOptions.path,
                  options: Options(
                    method: error.requestOptions.method,
                    headers: error.requestOptions.headers,
                  ),
                  data: error.requestOptions.data,
                  queryParameters: error.requestOptions.queryParameters,
                );
                return handler.resolve(response);
              } on DioException catch (e) {
                return handler.next(e);
              }
            } else {
              await logout();
              showSessionExpiredDialog();
              debugPrint('AUTH_SERVICE: Session expired: 401 Unauthorized');
            }
          }

          // Set last error message based on error type
          _setErrorFromDioException(error);
          return handler.next(error);
        },
      ),
    );

    debugPrint("AUTH_SERVICE: Dio configuration complete");
  }

  // Helper method to set error message from DioException
  void _setErrorFromDioException(DioException error) {
    debugPrint(
        'Log_Auth_flow: AUTH_SERVICE - Processing DioException: ${error.type}');

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        _lastError =
            'Connection timed out. Please check your internet connection.';
        debugPrint('Log_Auth_flow: AUTH_SERVICE - Connection timeout error');
        break;
      case DioExceptionType.sendTimeout:
        _lastError = 'Request timed out. Please try again.';
        debugPrint('Log_Auth_flow: AUTH_SERVICE - Send timeout error');
        break;
      case DioExceptionType.receiveTimeout:
        _lastError = 'Server response timed out. Please try again.';
        debugPrint('Log_Auth_flow: AUTH_SERVICE - Receive timeout error');
        break;
      case DioExceptionType.badResponse:
        // Check status code for more specific error messages
        final statusCode = error.response?.statusCode;
        debugPrint(
            'Log_Auth_flow: AUTH_SERVICE - Bad response with status code: $statusCode');

        if (statusCode == 400) {
          _lastError = 'Invalid request. Please check your information.';
          debugPrint('Log_Auth_flow: AUTH_SERVICE - 400 Bad Request error');
        } else if (statusCode == 401) {
          _lastError = 'Authentication failed. Please login again.';
          debugPrint('Log_Auth_flow: AUTH_SERVICE - 401 Unauthorized error');
        } else if (statusCode == 403) {
          _lastError = 'Access denied. You don\'t have permission.';
          debugPrint('Log_Auth_flow: AUTH_SERVICE - 403 Forbidden error');
        } else if (statusCode == 404) {
          _lastError = 'Resource not found.';
          debugPrint('Log_Auth_flow: AUTH_SERVICE - 404 Not Found error');
        } else if (statusCode == 500) {
          _lastError = 'Server error. Please try again later.';
          debugPrint('Log_Auth_flow: AUTH_SERVICE - 500 Server error');
        } else {
          _lastError =
              'Error: ${error.response?.statusMessage ?? 'Unknown error'}';
          debugPrint(
              'Log_Auth_flow: AUTH_SERVICE - Other HTTP error: $statusCode');
        }

        // Log response data if available
        if (error.response?.data != null) {
          debugPrint(
              'Log_Auth_flow: AUTH_SERVICE - Error response data: ${error.response?.data}');
        }
        break;
      case DioExceptionType.cancel:
        _lastError = 'Request was cancelled.';
        debugPrint('Log_Auth_flow: AUTH_SERVICE - Request cancelled');
        break;
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          _lastError = 'Network error. Please check your internet connection.';
          debugPrint(
              'Log_Auth_flow: AUTH_SERVICE - Socket exception (network error)');
        } else {
          _lastError = 'Unknown error: ${error.message}';
          debugPrint(
              'Log_Auth_flow: AUTH_SERVICE - Unknown error: ${error.message}');
        }
        break;
      default:
        _lastError = 'An unexpected error occurred.';
        debugPrint('Log_Auth_flow: AUTH_SERVICE - Unexpected error type');
    }

    debugPrint('Log_Auth_flow: AUTH_SERVICE - Error set to: $_lastError');
  }

  // Using the environment config for base URL
  final String _baseUrl = '${EnvConfig.apiBaseUrl}/Auth/';

  final Dio dio = Dio();

  // Check if internet is available

  Future<bool> authenticationWithPhone(String phoneNumber) async {
    // Reset error message
    _lastError = null;
    debugPrint(
        'Log_Auth_flow: AUTH_SERVICE - Starting phone authentication for: $phoneNumber');

    try {
      // Check internet first
      debugPrint(
          'Log_Auth_flow: AUTH_SERVICE - Checking internet connectivity');

      debugPrint(
          'Log_Auth_flow: AUTH_SERVICE - Internet connectivity confirmed');

      var endPoint =
          '${_baseUrl}request-phonenumber-authen?phoneNumber=$phoneNumber';

      debugPrint(
          'Log_Auth_flow: AUTH_SERVICE - Sending API request to: $endPoint');

      final response = await dio.post(
        endPoint,
        options: Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      debugPrint(
          'Log_Auth_flow: AUTH_SERVICE - Received API response with status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Store the OTP token received from the server
        debugPrint(
            'Log_Auth_flow: AUTH_SERVICE - Authentication successful, processing response');
        debugPrint(
            'Log_Auth_flow: AUTH_SERVICE - Response data: ${response.data}');

        if (response.data['data'] == null) {
          _lastError = 'Invalid server response. Please try again.';
          debugPrint(
              'Log_Auth_flow: AUTH_SERVICE - Error: Response data is null or invalid');
          return false;
        }

        String dataJsonString = response.data['data'];
        debugPrint(
            'Log_Auth_flow: AUTH_SERVICE - Data JSON string received: $dataJsonString');

        // Parse the JSON string to extract the token
        try {
          Map<String, dynamic> dataMap = jsonDecode(dataJsonString);
          _otpToken = dataMap['token'];
          debugPrint(
              'Log_Auth_flow: AUTH_SERVICE - Token extracted from response: ${_otpToken != null ? "Success" : "Failed"}');

          if (_otpToken == null) {
            _lastError = 'Invalid token received. Please try again.';
            debugPrint(
                'Log_Auth_flow: AUTH_SERVICE - Error: Token is null or invalid');
            return false;
          }

          await _secureStorage.write(key: "token", value: _otpToken);
          debugPrint(
              'Log_Auth_flow: AUTH_SERVICE - Token saved successfully to secure storage');
          return true;
        } catch (e) {
          _lastError = 'Error parsing server response: ${e.toString()}';
          debugPrint('Log_Auth_flow: AUTH_SERVICE - JSON parsing error: $e');
          return false;
        }
      } else {
        _lastError =
            'Server error: ${response.statusCode} - ${response.statusMessage}';
        debugPrint(
            'Log_Auth_flow: AUTH_SERVICE - Error: ${response.statusCode} - ${response.data}');
        return false;
      }
    } on DioException catch (e) {
      _setErrorFromDioException(e);
      debugPrint(
          'Log_Auth_flow: AUTH_SERVICE - DioException during phone authentication: $e');
      debugPrint('Log_Auth_flow: AUTH_SERVICE - Error type: ${e.type}');
      if (e.response != null) {
        debugPrint(
            'Log_Auth_flow: AUTH_SERVICE - Response status: ${e.response?.statusCode}');
        debugPrint(
            'Log_Auth_flow: AUTH_SERVICE - Response data: ${e.response?.data}');
      }
      return false;
    } catch (e) {
      _lastError = 'Error during authentication: ${e.toString()}';
      debugPrint(
          'Log_Auth_flow: AUTH_SERVICE - Error during authentication: $e');
      return false;
    }
  }

  Future<bool> verifyOtp(String otp) async {
    // Reset error message
    _lastError = null;
    debugPrint(
        'Log_Auth_flow: AUTH_SERVICE - Starting OTP verification for code: $otp');

    try {
      // Check internet first
      debugPrint(
          'Log_Auth_flow: AUTH_SERVICE - Checking internet connectivity');

      debugPrint(
          'Log_Auth_flow: AUTH_SERVICE - Internet connectivity confirmed');

      _otpToken = await _secureStorage.read(key: 'token');
      debugPrint(
          'Log_Auth_flow: AUTH_SERVICE - Retrieved OTP token from storage: ${_otpToken != null ? "Success" : "Failed"}');

      if (_otpToken == null) {
        _lastError =
            'OTP token is not available. Please restart the authentication process.';
        debugPrint(
            'Log_Auth_flow: AUTH_SERVICE - Error: OTP token is not available');
        return false;
      }

      final networkInfo = NetworkInfo();
      String? ipAddress = await networkInfo.getWifiIP();
      debugPrint(
          'Log_Auth_flow: AUTH_SERVICE - Retrieved IP address: ${ipAddress ?? "unknown"}');

      final deviceInfo = await _getDeviceInfo();
      debugPrint(
          'Log_Auth_flow: AUTH_SERVICE - Retrieved device info: ${deviceInfo.toString()}');

      final headers = {
        'Content-Type': 'application/json',
        'X-Forwarded-For': ipAddress ?? 'unknown',
        'X-Device-Name': deviceInfo['device_name'] ?? 'unknown',
        'X-Device-Brand': deviceInfo['brand'] ?? 'unknown',
        'X-Device-Model': deviceInfo['device_model'] ?? 'unknown',
        'X-Platform': defaultTargetPlatform.toString(),
        'id': _otpToken ?? 'unknown',
      };
      debugPrint(
          'Log_Auth_flow: AUTH_SERVICE - Prepared headers for API request');

      var endPoint = '${_baseUrl}confirm-otp-authen?otp=$otp';
      debugPrint(
          'Log_Auth_flow: AUTH_SERVICE - Sending OTP verification request to: $endPoint');

      final response = await dio.post(
        endPoint,
        options: Options(
          headers: headers,
        ),
      );

      debugPrint(
          'Log_Auth_flow: AUTH_SERVICE - Received API response with status: ${response.statusCode}');
      debugPrint(
          'Log_Auth_flow: AUTH_SERVICE - Response data: ${response.data.toString()}');

      if (response.statusCode == 200) {
        debugPrint(
            'Log_Auth_flow: AUTH_SERVICE - OTP verification successful, processing response');
        try {
          String dataJsonString = response.data['data'];
          debugPrint(
              'Log_Auth_flow: AUTH_SERVICE - Data JSON string received: $dataJsonString');

          Map<String, dynamic> dataMap = jsonDecode(dataJsonString);
          debugPrint(
              'Log_Auth_flow: AUTH_SERVICE - Successfully parsed JSON data');

          // Extract sessionId, refreshToken and userId from the response
          final sessionId = dataMap['SessionId'];
          final refreshToken = dataMap['RefreshToken'];

          debugPrint(
              'Log_Auth_flow: AUTH_SERVICE - Extracted sessionId: ${sessionId != null ? "Success" : "Failed"}');
          debugPrint(
              'Log_Auth_flow: AUTH_SERVICE - Extracted refreshToken: ${refreshToken != null ? "Success" : "Failed"}');

          if (sessionId == null || refreshToken == null) {
            _lastError = 'Invalid session data received. Please try again.';
            debugPrint(
                'Log_Auth_flow: AUTH_SERVICE - Error: Invalid session data received');
            return false;
          }

          // Save tokens and user claim
          debugPrint(
              'Log_Auth_flow: AUTH_SERVICE - Saving tokens to secure storage');
          await _secureStorage.write(key: 'session_id', value: sessionId);
          await _secureStorage.write(key: 'refresh_token', value: refreshToken);

          // Verify the session ID was saved correctly
          final savedSessionId = await _secureStorage.read(key: 'session_id');
          if (savedSessionId == null || savedSessionId.isEmpty) {
            _lastError =
                'Failed to save authentication session. Please try again.';
            debugPrint(
                'Log_Auth_flow: AUTH_SERVICE - ERROR: Failed to save session_id to secure storage');
            return false;
          }

          debugPrint(
              'Log_Auth_flow: AUTH_SERVICE - Successfully saved session_id to secure storage');

          // Clear the temporary OTP token
          await _secureStorage.delete(key: 'token');
          debugPrint(
              'Log_Auth_flow: AUTH_SERVICE - Temporary OTP token cleared');

          debugPrint(
              'Log_Auth_flow: AUTH_SERVICE - OTP verification completed successfully');
          return true;
        } catch (e) {
          _lastError = 'Error processing server response: ${e.toString()}';
          debugPrint(
              'Log_Auth_flow: AUTH_SERVICE - JSON parsing error in OTP verification: $e');
          return false;
        }
      } else {
        _lastError =
            'Server error: ${response.statusCode} - ${response.statusMessage}';
        debugPrint(
            'Log_Auth_flow: AUTH_SERVICE - Error: ${response.statusCode} - ${response.data}');
        return false;
      }
    } on DioException catch (e) {
      _setErrorFromDioException(e);
      debugPrint(
          'Log_Auth_flow: AUTH_SERVICE - DioException during OTP verification: $e');
      debugPrint('Log_Auth_flow: AUTH_SERVICE - Error type: ${e.type}');
      if (e.response != null) {
        debugPrint(
            'Log_Auth_flow: AUTH_SERVICE - Response status: ${e.response?.statusCode}');
        debugPrint(
            'Log_Auth_flow: AUTH_SERVICE - Response data: ${e.response?.data}');
      }
      return false;
    } catch (e) {
      _lastError = 'Error during OTP verification: ${e.toString()}';
      debugPrint(
          'Log_Auth_flow: AUTH_SERVICE - Error during OTP verification: $e');
      return false;
    }
  }

  Future<bool> refreshOtp(String identifier) async {
    // Reset error message
    _lastError = null;
    debugPrint(
        'Log_Auth_flow: AUTH_SERVICE - Starting OTP refresh for: $identifier');

    try {
      // Construct the appropriate endpoint
      final endpoint = '${_baseUrl}refresh-otp?item=$identifier';
      debugPrint(
          'Log_Auth_flow: AUTH_SERVICE - Sending OTP refresh request to: $endpoint');

      final response = await dio.post(
        endpoint,
        options: Options(
          headers: {
            'Content-Type': 'application/json charset=UTF-8',
          },
        ),
      );

      debugPrint(
          'Log_Auth_flow: AUTH_SERVICE - Received OTP refresh API response with status: ${response.statusCode}');
      debugPrint(
          'Log_Auth_flow: AUTH_SERVICE - Response data: ${response.data.toString()}');

      if (response.statusCode == 200) {
        debugPrint(
            'Log_Auth_flow: AUTH_SERVICE - OTP refresh successful, processing response');

        try {
          String dataJsonString = response.data['data'];
          debugPrint(
              'Log_Auth_flow: AUTH_SERVICE - Data JSON string received: $dataJsonString');

          Map<String, dynamic> dataMap = jsonDecode(dataJsonString);
          debugPrint(
              'Log_Auth_flow: AUTH_SERVICE - Successfully parsed JSON data');

          _otpToken = dataMap['token'] ?? dataMap['Token'];
          debugPrint(
              'Log_Auth_flow: AUTH_SERVICE - Token extracted from response: ${_otpToken != null ? "Success" : "Failed"}');

          if (_otpToken == null) {
            _lastError = 'Invalid token received. Please try again.';
            debugPrint(
                'Log_Auth_flow: AUTH_SERVICE - Error: Token is null or invalid');
            return false;
          }

          await _secureStorage.write(key: "token", value: _otpToken);
          debugPrint(
              'Log_Auth_flow: AUTH_SERVICE - Token saved successfully to secure storage');
          debugPrint(
              'Log_Auth_flow: AUTH_SERVICE - OTP refresh completed successfully');
          return true;
        } catch (e) {
          _lastError = 'Error parsing server response: ${e.toString()}';
          debugPrint(
              'Log_Auth_flow: AUTH_SERVICE - JSON parsing error in OTP refresh: $e');
          return false;
        }
      } else {
        _lastError =
            'Server error: ${response.statusCode} - ${response.statusMessage}';
        debugPrint(
            'Log_Auth_flow: AUTH_SERVICE - Error refreshing OTP: ${response.statusCode} - ${response.data}');
        return false;
      }
    } on DioException catch (e) {
      _setErrorFromDioException(e);
      debugPrint(
          'Log_Auth_flow: AUTH_SERVICE - DioException during OTP refresh: $e');
      debugPrint('Log_Auth_flow: AUTH_SERVICE - Error type: ${e.type}');
      if (e.response != null) {
        debugPrint(
            'Log_Auth_flow: AUTH_SERVICE - Response status: ${e.response?.statusCode}');
        debugPrint(
            'Log_Auth_flow: AUTH_SERVICE - Response data: ${e.response?.data}');
      }
      return false;
    } catch (e) {
      _lastError = 'Error during OTP refresh: ${e.toString()}';
      debugPrint('Log_Auth_flow: AUTH_SERVICE - Error during OTP refresh: $e');
      return false;
    }
  }

  Future<void> logout() async {
    // Delete all auth-related tokens and claims
    await _secureStorage.delete(key: 'session_id');
    await _secureStorage.delete(key: 'refresh_token');
    await _secureStorage.delete(key: 'user_id'); // Also remove user claim
    await _secureStorage.delete(key: 'token'); // Also remove any OTP token
  }

  Future<bool> refreshToken() async {
    if (_isRefreshing) {
      return false;
    }
    _isRefreshing = true;

    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        _isRefreshing = false;
        return false;
      }

      final response = await dio.post(
        '${_baseUrl}refresh-token',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'refreshToken': ' $refreshToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        final newSessionId = response.data['sessionId'];
        final newRefreshToken = response.data['refreshToken'];

        if (newSessionId != null && newRefreshToken != null) {
          await _secureStorage.write(key: 'session_id', value: newSessionId);
          await _secureStorage.write(
              key: 'refresh_token', value: newRefreshToken);
          _isRefreshing = false;
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');
    }

    _isRefreshing = false;
    return false;
  }

  Future<String?> getSessionId() async {
    return await _secureStorage.read(key: 'session_id');
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: 'refresh_token');
  }

  // Get the user ID (claim)
  Future<String?> getUserId() async {
    return await _secureStorage.read(key: 'user_id');
  }

  Future<bool> isLoggedIn() async {
    // CRITICAL: Authentication status is determined by presence of session_id
    final sessionId = await getSessionId();
    debugPrint(
        'Log_Auth_flow: AUTH_SERVICE - Checking login status: sessionId exists = ${sessionId != null}');

    if (sessionId == null || sessionId.isEmpty) {
      debugPrint(
          'Log_Auth_flow: AUTH_SERVICE - User is not logged in (no session ID found)');
      return false;
    }

    // Session ID exists, user is considered authenticated
    debugPrint(
        'Log_Auth_flow: AUTH_SERVICE - User is authenticated with valid session ID');
    return true;
  }

  // Validate token without user interaction
  Future<bool> validateToken() async {
    final sessionId = await getSessionId();
    if (sessionId == null) {
      return false;
    }

    try {
      // Check internet first

      // Implement a lightweight token validation API call here
      // For now, we'll assume the token is valid if it exists
      return true;
    } catch (e) {
      debugPrint('Error validating token: $e');
      // Consider token valid in case of errors
      return true;
    }
  }

  // Show session expired dialog
  Future<void> showSessionExpiredDialog() async {
    final context = navigatorKey.currentContext;
    if (context == null) {
      return;
    }
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Session Expired'),
          content: const Text('Your session has expired, please log in again.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                context.goNamed('login'); // Use GoRouter
              },
            ),
          ],
        );
      },
    );
  }

  // Check for valid session and show dialog if expired
  Future<bool> checkSession(BuildContext context) async {
    final isValid = await isLoggedIn();
    if (!isValid) {
      await showSessionExpiredDialog();
      return false;
    }
    return true;
  }

  // Authenticate with an already selected Google account email
  Future<bool> authenticateWithSelectedEmail(String email) async {
    // Reset error message
    _lastError = null;
    debugPrint(
        'Log_Auth_flow: AUTH_SERVICE - Starting Google authentication with email: $email');

    try {
      // Prepare the API endpoint
      final endpoint = '${_baseUrl}request-email-authen?email=$email';
      debugPrint(
          'Log_Auth_flow: AUTH_SERVICE - Sending Google auth request to: $endpoint');

      // Send the request
      final response = await dio.post(
        endpoint,
        options: Options(
          headers: {
            'Content-Type': 'application/json charset=UTF-8',
          },
        ),
      );

      debugPrint(
          'Log_Auth_flow: AUTH_SERVICE - Received Google auth API response with status: ${response.statusCode}');
      debugPrint(
          'Log_Auth_flow: AUTH_SERVICE - Response data: ${response.data.toString()}');

      if (response.statusCode == 200) {
        debugPrint(
            'Log_Auth_flow: AUTH_SERVICE - Google auth successful, processing response');

        try {
          String dataJsonString = response.data['data'];
          debugPrint(
              'Log_Auth_flow: AUTH_SERVICE - Data JSON string received: $dataJsonString');

          Map<String, dynamic> dataMap = jsonDecode(dataJsonString);
          debugPrint(
              'Log_Auth_flow: AUTH_SERVICE - Successfully parsed JSON data');

          _otpToken = dataMap['token'];
          debugPrint(
              'Log_Auth_flow: AUTH_SERVICE - Token extracted from response: ${_otpToken != null ? "Success" : "Failed"}');

          if (_otpToken == null) {
            _lastError = 'Invalid token received. Please try again.';
            debugPrint(
                'Log_Auth_flow: AUTH_SERVICE - Error: Token is null or invalid');
            return false;
          }

          await _secureStorage.write(key: "token", value: _otpToken);
          debugPrint(
              'Log_Auth_flow: AUTH_SERVICE - Token saved successfully to secure storage');
          debugPrint(
              'Log_Auth_flow: AUTH_SERVICE - Google authentication completed successfully');
          return true;
        } catch (e) {
          _lastError = 'Error parsing server response: ${e.toString()}';
          debugPrint(
              'Log_Auth_flow: AUTH_SERVICE - JSON parsing error in Google authentication: $e');
          return false;
        }
      } else {
        _lastError =
            'Server error: ${response.statusCode} - ${response.statusMessage}';
        debugPrint(
            'Log_Auth_flow: AUTH_SERVICE - API Error: ${response.statusCode} - ${response.data}');
        return false;
      }
    } on DioException catch (e) {
      _setErrorFromDioException(e);
      debugPrint(
          'Log_Auth_flow: AUTH_SERVICE - DioException during Google authentication: $e');
      debugPrint('Log_Auth_flow: AUTH_SERVICE - Error type: ${e.type}');
      if (e.response != null) {
        debugPrint(
            'Log_Auth_flow: AUTH_SERVICE - Response status: ${e.response?.statusCode}');
        debugPrint(
            'Log_Auth_flow: AUTH_SERVICE - Response data: ${e.response?.data}');
      }
      return false;
    } catch (e) {
      _lastError = 'Error during Google authentication: ${e.toString()}';
      debugPrint(
          'Log_Auth_flow: AUTH_SERVICE - Error during Google authentication: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    final deviceInfo = <String, dynamic>{};

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Android
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceInfo['device_model'] = androidInfo.model;
        deviceInfo['sdk_version'] = androidInfo.version.sdkInt.toString();
        deviceInfo['brand'] = androidInfo.brand;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        // iOS
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceInfo['device_model'] = iosInfo.model;
        deviceInfo['os_version'] = iosInfo.systemVersion;
        deviceInfo['device_name'] = iosInfo.name;
      } else {
        deviceInfo['platform'] = defaultTargetPlatform.toString();
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }
    return deviceInfo;
  }
}
