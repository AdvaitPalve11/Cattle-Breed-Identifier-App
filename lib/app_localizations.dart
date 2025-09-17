import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

final _log = Logger('AppLocalizations');

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
      _log.info('Loading translations for locale: ${locale.languageCode}');
      
      // Verify the file exists
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      final String assetPath = 'assets/i18n/${locale.languageCode}.json';
      
      if (!manifestMap.containsKey(assetPath)) {
        _log.severe('Localization file not found in assets: $assetPath');
        return _loadFallbackLocale();
      }

      // Load the locale-specific file
      final String jsonString = await rootBundle.loadString(assetPath);
      
      if (jsonString.isEmpty) {
        _log.warning('Warning: Empty localization file for ${locale.languageCode}');
        return _loadFallbackLocale();
      }

      try {
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        _localizedStrings = jsonMap.map((key, value) {
          return MapEntry(key, value.toString());
        });
        _log.info('Successfully loaded ${_localizedStrings?.length} translations for ${locale.languageCode}');
        return true;
      } catch (e) {
        _log.severe('Error parsing JSON for ${locale.languageCode}: $e');
        return _loadFallbackLocale();
      }
    } catch (e) {
      _log.severe('Error loading locale ${locale.languageCode}: $e');
      return _loadFallbackLocale();
    }
  }

  Future<bool> _loadFallbackLocale() async {
    try {
      // Try to load English as fallback
      if (locale.languageCode != 'en') {
        final String fallbackJson = await rootBundle.loadString('assets/i18n/en.json');
        if (fallbackJson.isEmpty) {
          _log.severe('Error: Fallback locale file (en.json) is empty');
          return false;
        }
        final Map<String, dynamic> jsonMap = json.decode(fallbackJson);
        _localizedStrings = jsonMap.map((key, value) {
          return MapEntry(key, value.toString());
        });
        _log.info('Successfully loaded ${_localizedStrings?.length} translations for fallback locale (en)');
        return true;
      }
      return false;
    } catch (e) {
      _log.severe('Error loading fallback locale: $e');
      return false;
    }
  }

  String translate(String key) {
    if (_localizedStrings == null) {
      _log.warning('Warning: Translations not loaded for ${locale.languageCode}');
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