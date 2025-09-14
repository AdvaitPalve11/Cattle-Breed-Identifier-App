import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';

class LocaleProvider extends ChangeNotifier {
  static final _log = Logger('LocaleProvider');
  Locale? _locale;
  static const String _prefsKey = 'selected_locale';

  LocaleProvider() {
    // Load saved locale on initialization
    _loadSavedLocale();
  }

  Locale get locale => _locale ?? const Locale('en', '');

  // Available locales
  static const List<Locale> supportedLocales = [
    Locale('en', ''),
    Locale('hi', ''),
    Locale('mr', ''),
  ];

  // Get locale name for display
  String getLocaleName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'hi':
        return 'हिंदी';
      case 'mr':
        return 'मराठी';
      default:
        return languageCode;
    }
  }

  // Load saved locale from SharedPreferences
  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString(_prefsKey);
    if (savedLanguageCode != null) {
      setLocale(Locale(savedLanguageCode, ''));
    }
  }

  // Set new locale and save to SharedPreferences
  Future<void> setLocale(Locale newLocale) async {
    _log.info('Setting new locale: ${newLocale.languageCode}');
    if (!supportedLocales.contains(newLocale)) {
      _log.warning('Locale not supported: ${newLocale.languageCode}');
      return;
    }

    _locale = newLocale;
    _log.info('Locale set to: ${_locale?.languageCode}');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, newLocale.languageCode);
      _log.info('Locale saved to preferences: ${newLocale.languageCode}');
    } catch (e) {
      _log.severe('Error saving locale: $e');
    }
    
    notifyListeners();
    _log.info('Notified listeners of locale change');
  }
}