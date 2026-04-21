import 'package:flutter/material.dart';

class FlashcardsScreen extends StatelessWidget {
  const FlashcardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Kaardid: Siia tuleb õppimise vaade',
        style: TextStyle(fontSize: 20, color: Colors.grey),
      ),
    );
  }
}