import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import 'app_localizations.dart';
import 'home_screen.dart';
import 'providers/locale_provider.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// Import the mobile implementation debug helper. This file is safe to import
// on non-web platforms. We'll call the debug helper only on mobile platforms.
import 'services/breed_classifier_mobile.dart' as mobile_impl;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
  
  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Pre-load the locale to avoid UI flicker
  final localeProvider = LocaleProvider();
  await localeProvider.loadSavedLocale();

  // In debug mode, try to load the interpreter early and log tensor info for diagnostics
  assert(() {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      mobile_impl.BreedClassifierMobile.debugTryLoadModel('assets/model/cattle_breed_model.tflite').then((ok) {
        if (ok) {
          debugPrint('Debug: model loaded successfully in startup check');
        } else {
          debugPrint('Debug: model failed to load in startup check');
        }
      });
    }
    return true;
  }());

  // Install global error handlers so we don't end up with a black screen
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    // Show a red error box with the error message
    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Text('An error occurred: ${details.exceptionAsString()}', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  };

  runApp(
    ChangeNotifierProvider(
      create: (_) => localeProvider,
      child: const CattleBreedApp(),
    ),
  );
}

class CattleBreedApp extends StatelessWidget {
  const CattleBreedApp({super.key});

  static final _log = Logger('CattleBreedApp');

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        _log.info('Rebuilding MaterialApp with locale: ${localeProvider.locale.languageCode}');
        return MaterialApp(
          title: 'Cattle Breed App',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            fontFamily: 'Inter',
          ),
          locale: localeProvider.locale, // Set the current locale
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: LocaleProvider.supportedLocales,
          home: const HomeScreen(),
        );
      },
    );
  }
}
