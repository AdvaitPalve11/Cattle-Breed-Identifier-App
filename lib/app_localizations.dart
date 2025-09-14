import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  Map<String, String>? _localizedStrings;

  Future<bool> load() async {
    try {
      print('Loading translations for locale: ${locale.languageCode}');
      // Try to load the locale-specific file
      final String jsonString = await rootBundle.loadString('assets/i18n/${locale.languageCode}.json');
      
      if (jsonString.isEmpty) {
        print('Warning: Empty localization file for ${locale.languageCode}');
        return _loadFallbackLocale();
      }

      try {
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        _localizedStrings = jsonMap.map((key, value) {
          return MapEntry(key, value.toString());
        });
        print('Successfully loaded ${_localizedStrings?.length} translations for ${locale.languageCode}');
        return true;
      } catch (e) {
        print('Error parsing JSON for ${locale.languageCode}: $e');
        return _loadFallbackLocale();
      }
    } catch (e) {
      print('Error loading locale ${locale.languageCode}: $e');
      return _loadFallbackLocale();
    }
  }

  Future<bool> _loadFallbackLocale() async {
    try {
      // Try to load English as fallback
      if (locale.languageCode != 'en') {
        final String fallbackJson = await rootBundle.loadString('assets/i18n/en.json');
        if (fallbackJson.isEmpty) {
          print('Error: Fallback locale file (en.json) is empty');
          return false;
        }
        final Map<String, dynamic> jsonMap = json.decode(fallbackJson);
        _localizedStrings = jsonMap.map((key, value) {
          return MapEntry(key, value.toString());
        });
        print('Successfully loaded ${_localizedStrings?.length} translations for fallback locale (en)');
        return true;
      }
      return false;
    } catch (e) {
      print('Error loading fallback locale: $e');
      return false;
    }
  }

  String translate(String key) {
    if (_localizedStrings == null) {
      print('Warning: Translations not loaded for ${locale.languageCode}');
      return key;
    }
    return _localizedStrings![key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'hi', 'mr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => true; // Allow reloading when locale changes
}