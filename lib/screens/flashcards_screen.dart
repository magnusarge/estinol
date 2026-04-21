import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/word.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  // Vaikimisi valikud
  Set<int> _selectedDifficulties = {0, 1, 2, 3}; // Kõik on alguses valitud
  int _selectedCount = 15;

  final List<int> _countOptions = [10, 15, 25, 40];

  // Abistav sõnastik raskusastmete nimede kuvamiseks
  final Map<int, String> _difficultyNames = {
    0: 'Määramata',
    1: 'Kerge',
    2: 'Keskmine',
    3: 'Raske',
  };

  void _startLearning() async {
    // Kaitseme kasutajat selle eest, et ta ei vajutaks starti ilma ühtegi raskusastet valimata
    if (_selectedDifficulties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vali vähemalt üks raskusaste!')),
      );
      return;
    }

    print('Valitud kaarte: $_selectedCount, Raskusastmed: $_selectedDifficulties');
    
    // Siia lisame hiljem päringu ja ekraanivahetuse:
    // List<Word> words = await DatabaseService().getFlashcardsBatch('es', _selectedDifficulties, _selectedCount);
    // Navigator.push(...)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Seadista õppesessioon',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              // 1. RASKUSASTE (2 TULPA)
              const Text(
                'Raskusaste',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              // Wrap paigutab elemendid ritta ja murrab need uuele reale, kui ruum otsa saab
              Wrap(
                spacing: 10, 
                runSpacing: 0,
                children: _difficultyNames.entries.map((entry) {
                  int diffValue = entry.key;
                  String diffName = entry.value;

                  // FractionallySizedBox tagab, et iga valik võtab ~poole ekraani laiusest
                  return FractionallySizedBox(
                    widthFactor: 0.48,
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(diffName, style: const TextStyle(fontSize: 15)),
                      value: _selectedDifficulties.contains(diffValue),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: Colors.blue,
                      onChanged: (bool? checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedDifficulties.add(diffValue);
                          } else {
                            _selectedDifficulties.remove(diffValue);
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 30),

              // 2. KAARTIDE ARV (SegmentedButton)
              const Text(
                'Kaartide arv',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  segments: _countOptions.map((count) {
                    return ButtonSegment<int>(
                      value: count,
                      label: Text('$count', style: const TextStyle(fontSize: 16)),
                    );
                  }).toList(),
                  selected: {_selectedCount},
                  onSelectionChanged: (Set<int> newSelection) {
                    setState(() {
                      _selectedCount = newSelection.first;
                    });
                  },
                ),
              ),

              const Spacer(), // Lükkab nupu ekraani allaäärde

              // 3. ALUSTA NUPP
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _startLearning,
                  child: const Text(
                    'Alusta',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}