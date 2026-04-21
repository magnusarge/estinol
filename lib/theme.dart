import 'package:flutter/material.dart';

class AppTheme {
  // Põhivärvid sinu Fleti projektist
  static const Color primaryColor = Color(0xFF1976D2); // Colors.blue.shade700
  static const Color secondaryColor = Color(0xFFFF9800); // Colors.orange
  static const Color bgColor = Color(0xFFF8F9FA);
  static const Color navBgColor = Color(0xFFF0F2F5);

  // Kogu äpi valmisteema
  static ThemeData get lightTheme {
    return ThemeData(
      colorSchemeSeed: primaryColor,
      scaffoldBackgroundColor: bgColor,
      useMaterial3: true,
      
      // Teeme kohe valmis ka Fletist tuttava "style_input" disaini
      // Nüüd näevad kõik tekstikastid terves äpis automaatselt sellised välja!
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none, // Peidab musta joone
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      ),
    );
  }
}