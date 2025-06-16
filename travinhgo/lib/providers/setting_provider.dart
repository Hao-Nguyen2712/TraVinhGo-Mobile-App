import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingProvider with ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String _currentLanguage = 'vi'; // Default language is Vietnamese

  String get currentLanguage => _currentLanguage;

  // Constructor to load saved language preference
  SettingProvider() {
    _loadSavedLanguage();
  }

  // Load saved language preference
  Future<void> _loadSavedLanguage() async {
    final savedLanguage = await _secureStorage.read(key: 'language_code');
    if (savedLanguage != null) {
      _currentLanguage = savedLanguage;
      notifyListeners();
    }
  }

  // Toggle language between Vietnamese and English
  Future<void> toggleLanguage() async {
    _currentLanguage = _currentLanguage == 'vi' ? 'en' : 'vi';

    // Save the language preference
    await _secureStorage.write(key: 'language_code', value: _currentLanguage);

    notifyListeners();
  }

  // Set specific language
  Future<void> setLanguage(String languageCode) async {
    if (languageCode != _currentLanguage) {
      _currentLanguage = languageCode;

      // Save the language preference
      await _secureStorage.write(key: 'language_code', value: _currentLanguage);

      notifyListeners();
    }
  }
}
