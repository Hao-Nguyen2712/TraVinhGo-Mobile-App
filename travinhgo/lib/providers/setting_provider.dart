import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingProvider with ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  Locale _locale = const Locale('vi'); // Default to Vietnamese

  Locale get locale => _locale;

  SettingProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final savedLanguageCode = await _secureStorage.read(key: 'language_code');
    if (savedLanguageCode != null) {
      _locale = Locale(savedLanguageCode);
      notifyListeners();
    }
  }

  void setLocale(Locale locale) {
    if (!AppLocalizations.supportedLocales.contains(locale)) return;
    _locale = locale;
    _secureStorage.write(key: 'language_code', value: locale.languageCode);
    notifyListeners();
  }
}
