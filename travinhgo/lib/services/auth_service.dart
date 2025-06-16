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
import 'package:travinhgo/screens/auth/login_screen.dart';

import '../utils/env_config.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  String? _otpToken;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal() {
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    dio.options.sendTimeout = const Duration(seconds: 30);

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };

    // Add interceptor to handle 401 responses
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          if (error.response?.statusCode == 401) {
            // Clear tokens on 401 (Unauthorized) response
            await logout();
            debugPrint('Session expired: 401 Unauthorized');
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Using the environment config for base URL
  final String _baseUrl = '${EnvConfig.apiBaseUrl}/Auth/';

  final Dio dio = Dio();

  Future<bool> authenticationWithPhone(String phoneNumber) async {
    try {
      var endPoint =
          '${_baseUrl}request-phonenumber-authen?phoneNumber=$phoneNumber';

      debugPrint('Attempting phone authentication: $endPoint');

      final response = await dio.post(
        endPoint,
        options: Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        // Store the OTP token received from the server
        debugPrint('Authentication successful, processing response');

        if (response.data['data'] == null) {
          debugPrint('Error: Response data is null or invalid');
          return false;
        }

        String dataJsonString = response.data['data'];

        // Parse the JSON string to extract the token
        Map<String, dynamic> dataMap = jsonDecode(dataJsonString);
        _otpToken = dataMap['token'];

        if (_otpToken == null) {
          debugPrint('Error: Token is null or invalid');
          return false;
        }

        await _secureStorage.write(key: "token", value: _otpToken);
        debugPrint('Token saved successfully');
        return true;
      } else {
        debugPrint('Error: ${response.statusCode} - ${response.data}');
        return false;
      }
    } catch (e) {
      debugPrint('Error during authentication: $e');
      return false;
    }
  }

  Future<bool> verifyOtp(String otp) async {
    try {
      _otpToken = await _secureStorage.read(key: 'token');
      if (_otpToken == null) {
        debugPrint('Error: OTP token is not available');
        return false;
      }

      final networkInfo = NetworkInfo();
      String? ipAddress = await networkInfo.getWifiIP();

      final deviceInfo = await _getDeviceInfo();

      final headers = {
        'Content-Type': 'application/json',
        'X-Forwarded-For': ipAddress ?? 'unknown',
        'X-Device-Name': deviceInfo['device_name'] ?? 'unknown',
        'X-Device-Brand': deviceInfo['brand'] ?? 'unknown',
        'X-Device-Model': deviceInfo['device_model'] ?? 'unknown',
        'X-Platform': defaultTargetPlatform.toString(),
        'id': _otpToken ?? 'unknown',
      };

      var endPoint = '${_baseUrl}confirm-otp-authen?otp=$otp';

      final response = await dio.post(
        endPoint,
        options: Options(
          headers: headers,
        ),
      );

      if (response.statusCode == 200) {
        String dataJsonString = response.data['data'];
        Map<String, dynamic> dataMap = jsonDecode(dataJsonString);

        // Extract sessionId, refreshToken and userId from the response
        final sessionId = dataMap['sessionId'];
        final refreshToken = dataMap['refreshToken'];
        final userId = dataMap['userId']; // Get userId from response

        // Save tokens and user claim
        await _secureStorage.write(key: 'session_id', value: sessionId);
        await _secureStorage.write(key: 'refresh_token', value: refreshToken);

        // Store userId as a claim (only exists when logged in)
        if (userId != null) {
          await _secureStorage.write(key: 'user_id', value: userId.toString());
        }

        // Clear the temporary OTP token
        await _secureStorage.delete(key: 'token');

        return true;
      } else {
        debugPrint('Error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error during OTP verification: $e');
      return false;
    }
  }

  Future<bool> refreshOtp(String identifier) async {
    try {
      debugPrint('Requesting OTP refresh for: $identifier');

      // Construct the appropriate endpoint
      final endpoint = '${_baseUrl}refresh-otp?item=$identifier';

      final response = await dio.post(
        endpoint,
        options: Options(
          headers: {
            'Content-Type': 'application/json charset=UTF-8',
          },
        ),
      );

      if (response.statusCode == 200) {
        String dataJsonString = response.data['data'];
        Map<String, dynamic> dataMap = jsonDecode(dataJsonString);
        _otpToken = dataMap['token'];

        await _secureStorage.write(key: "token", value: _otpToken);
        return true;
      } else {
        debugPrint('Error refreshing OTP: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error during OTP refresh: $e');
      return false;
    }
  }

  Future<void> logout() async {
    // Delete all auth-related tokens and claims
    await _secureStorage.delete(key: 'session_id');
    await _secureStorage.delete(key: 'refresh_token');
    await _secureStorage.delete(key: 'user_id'); // Also remove user claim
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
    final token = await getSessionId();
    return token != null;
  }

  // Show session expired dialog
  Future<void> showSessionExpiredDialog(BuildContext context) async {
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
      await showSessionExpiredDialog(context);
      return false;
    }
    return true;
  }

  Future<bool> authenticateWithGoogle() async {
    try {
      debugPrint('Starting Google Sign-In process to get email only...');

      // Simple Google Sign-In to get user email
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Sign out first to force the account picker to show
      await googleSignIn.signOut();

      var user = await googleSignIn.signIn();
      if (user == null) {
        debugPrint('Google Sign-In was cancelled or failed');
        return false;
      }

      var email = user.email;

      debugPrint('Successfully got email from Google: $email');

      // Send the email to your API
      final response = await dio.post(
        '${_baseUrl}request-email-authen?email=$email',
        options: Options(
          headers: {
            'Content-Type': 'application/json charset=UTF-8',
          },
        ),
      );

      if (response.statusCode == 200) {
        String dataJsonString = response.data['data'];
        Map<String, dynamic> dataMap = jsonDecode(dataJsonString);
        _otpToken = dataMap['token'];

        await _secureStorage.write(key: "token", value: _otpToken);
        return true;
      } else {
        debugPrint('API Error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Google auth error: $e');
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
