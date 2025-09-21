import 'package:flutter/material.dart';
import 'package:cattle_breed_app/app_localizations.dart';
import 'breed_identifier_screen.dart';
import 'about_screen.dart';
import 'contact_screen.dart';
import 'history_screen.dart';
import 'widgets/language_selector.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const BreedIdentifierScreen(),
    const HistoryScreen(),
    const AboutScreen(),
    const ContactScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.translate('app_name') ?? 'Cattle Breed App'),
        actions: [
          LanguageSelector(),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
          bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Good for 4+ items
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: AppLocalizations.of(context)?.translate('nav_home') ?? 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: AppLocalizations.of(context)?.translate('nav_history') ?? 'History',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.info),
            label: AppLocalizations.of(context)?.translate('nav_about') ?? 'About',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.contact_page),
            label: AppLocalizations.of(context)?.translate('nav_contact') ?? 'Contact',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}