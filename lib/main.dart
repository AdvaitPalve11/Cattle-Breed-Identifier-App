import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import 'app_localizations.dart';
import 'home_screen.dart';
import 'providers/locale_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
  
  // Load environment variables
  await dotenv.load(fileName: ".env");

  runApp(
    ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
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
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: LocaleProvider.supportedLocales,
          locale: localeProvider.locale,
          home: const HomeScreen(),
        );
      },
    );
  }
}
