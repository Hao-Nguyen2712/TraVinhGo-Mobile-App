import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingProvider with ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  Locale _locale = const Locale('vi'); // Default to Vietnamese
  ThemeMode _themeMode = ThemeMode.system;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;

  SettingProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final savedLanguageCode = await _secureStorage.read(key: 'language_code');
    if (savedLanguageCode != null) {
      _locale = Locale(savedLanguageCode);
    }

    final savedTheme = await _secureStorage.read(key: 'theme_mode');
    switch (savedTheme) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
        break;
    }

    notifyListeners();
  }

  void setLocale(Locale locale) {
    if (!AppLocalizations.supportedLocales.contains(locale)) return;
    _locale = locale;
    _secureStorage.write(key: 'language_code', value: locale.languageCode);
    notifyListeners();
  }

  void setTheme(ThemeMode themeMode) {
    _themeMode = themeMode;
    _secureStorage.write(key: 'theme_mode', value: themeMode.name);
    notifyListeners();
  }
}
