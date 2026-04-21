import 'package:flutter/material.dart';

class DictionaryScreen extends StatelessWidget {
  const DictionaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Sõnastik: Siia tuleb tähestikuline nimekiri',
        style: TextStyle(fontSize: 20, color: Colors.grey),
      ),
    );
  }
}