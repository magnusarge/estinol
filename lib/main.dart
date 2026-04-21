import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/dictionary_screen.dart';
import 'screens/flashcards_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const EstinolApp());
}

class EstinolApp extends StatelessWidget {
  const EstinolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Estiñol',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isSpanishToEstonian = true;

  // See getter arvutab alati õige keele stringi
  String get _activeLang => _isSpanishToEstonian ? 'es' : 'et';

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleLanguage() {
    setState(() {
      _isSpanishToEstonian = !_isSpanishToEstonian;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estiñol', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: _toggleLanguage,
            icon: Icon(Icons.swap_horiz, color: Theme.of(context).primaryColor),
            label: Text(
              _isSpanishToEstonian ? 'ES ➔ ET' : 'ET ➔ ES',
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      // KUSTUTA VANA _pages JA KASUTA SEDA:
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Nüüd anname _activeLang ilusti edasi ja punased jooned kaovad
          HomeScreen(activeLang: _activeLang),
          DictionaryScreen(activeLang: _activeLang),
          const FlashcardsScreen(), // Kuna siin pole parameetreid, siis const sobib
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: AppTheme.navBgColor,
        indicatorColor: AppTheme.primaryColor.withOpacity(0.2),
        destinations: const [
          // 1. Uuendatud "Otsi" vaade
          NavigationDestination(
            icon: Icon(Icons.search), 
            selectedIcon: Icon(Icons.search, size: 28), // Lisame väikese visuaalse eristuse
            label: 'Otsi',
          ),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Sõnastik'),
          NavigationDestination(icon: Icon(Icons.style_outlined), selectedIcon: Icon(Icons.style), label: 'Kaardid'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Seaded'),
        ],
      ),
    );
  }
}