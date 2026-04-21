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

  static const List<Widget> _pages = <Widget>[
    HomeScreen(),
    DictionaryScreen(),
    FlashcardsScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleDirection() {
    setState(() {
      _isSpanishToEstonian = !_isSpanishToEstonian;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.bgColor,
        title: const Text(
          'Estiñol',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ActionChip(
              backgroundColor: _isSpanishToEstonian 
                  ? Colors.blue.shade50 
                  : Colors.orange.shade50,
              label: Text(
                _isSpanishToEstonian ? 'ES ➔ ET' : 'ET ➔ ES',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _isSpanishToEstonian 
                      ? AppTheme.primaryColor 
                      : AppTheme.secondaryColor,
                ),
              ),
              onPressed: _toggleDirection,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          )
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: AppTheme.navBgColor,
        indicatorColor: AppTheme.primaryColor.withOpacity(0.2),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Kodu'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Sõnastik'),
          NavigationDestination(icon: Icon(Icons.style_outlined), selectedIcon: Icon(Icons.style), label: 'Kaardid'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Seaded'),
        ],
      ),
    );
  }
}