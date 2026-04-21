import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Seaded: Autentimine ja Firebase haldus',
        style: TextStyle(fontSize: 20, color: Colors.grey),
      ),
    );
  }
}