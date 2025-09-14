import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import '../providers/locale_provider.dart';

class LanguageSelector extends StatelessWidget {
  static final _log = Logger('LanguageSelector');
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LocaleProvider>(context);
    final currentLocale = provider.locale;

    return PopupMenuButton<Locale>(
      onSelected: (Locale locale) async {
        _log.info('Language selected: ${locale.languageCode}');
        await provider.setLocale(locale);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Language changed to ${provider.getLocaleName(locale.languageCode)}'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      itemBuilder: (context) => LocaleProvider.supportedLocales
          .map(
            (locale) => PopupMenuItem(
              value: locale,
              child: Row(
                children: [
                  if (currentLocale.languageCode == locale.languageCode)
                    const Icon(Icons.check, size: 18),
                  const SizedBox(width: 8),
                  Text(provider.getLocaleName(locale.languageCode)),
                ],
              ),
            ),
          )
          .toList(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              provider.getLocaleName(currentLocale.languageCode),
              style: const TextStyle(fontSize: 16),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}