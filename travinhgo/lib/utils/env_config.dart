import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;

/// A class to manage environment variables and configurations.
class EnvConfig {
  static late EnvConfig _instance;

  /// Initialize environment configuration.
  /// Must be called before accessing any environment variables.
  static Future<void> initialize() async {
    try {
      await dotenv.dotenv.load(fileName: '.env');
      _instance = EnvConfig._();
    } catch (e) {
      debugPrint('Error loading .env file: $e');
      // Fallback to default values in case the .env file is not found
      _instance = EnvConfig._();
    }
  }

  /// Private constructor
  EnvConfig._();

  /// Get a string value from environment variables
  static String getString(String key, {String defaultValue = ''}) {
    return dotenv.dotenv.env[key] ?? defaultValue;
  }

  /// Get a boolean value from environment variables
  static bool getBool(String key, {bool defaultValue = false}) {
    final value = dotenv.dotenv.env[key];
    if (value == null) return defaultValue;
    return value.toLowerCase() == 'true';
  }

  /// Get an integer value from environment variables
  static int getInt(String key, {int defaultValue = 0}) {
    final value = dotenv.dotenv.env[key];
    if (value == null) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }

  /// Get the API base URL
  static String get apiBaseUrl => getString('API_BASE_URL',
      defaultValue: 'https://dv67l8z6-7162.asse.devtunnels.ms/api');

  /// Get the HERE API key
  static String get hereApiKey =>
      getString('HERE_API_KEY', defaultValue: 'YOUR_HERE_API_KEY');

  /// Get the HERE API secret
  static String get hereApiSecret =>
      getString('HERE_API_SECRET', defaultValue: 'YOUR_HERE_API_SECRET');
}
