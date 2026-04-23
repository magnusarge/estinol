import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/word.dart';
import 'flashcard_session_screen.dart';
import 'custom_set_edit_screen.dart';

class FlashcardsScreen extends StatefulWidget {
  final String activeLang; // LISA SEE

  const FlashcardsScreen({super.key, required this.activeLang});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  Set<int> _selectedDifficulties = {0, 1, 2, 3}; 
  int _selectedCount = 15;

  final List<int> _countOptions = [10, 15, 25, 40];

  final Map<int, String> _difficultyNames = {
    0: 'Määramata',
    1: 'Kerge',
    2: 'Keskmine',
    3: 'Raske',
  };

  // Muutuja komplektide jaoks
  List<Map<String, dynamic>> _customSets = [];

  @override
  void initState() {
    super.initState();
    _loadCustomSets();
  }

  // Kui keelt vahetatakse, peame ka komplektid uuesti laadima!
  @override
  void didUpdateWidget(covariant FlashcardsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeLang != widget.activeLang) {
      _loadCustomSets();
    }
  }

  void _loadCustomSets() async {
    final sets = await DatabaseService().getCustomSets(widget.activeLang);
    setState(() {
      _customSets = sets;
    });
  }

  // Funktsioon komplektist mängu alustamiseks
  void _startCustomSetGame(Map<String, dynamic> setMap) async {
    List<dynamic> ids = setMap['wordIds'];
    if (ids.isEmpty) return;

    List<Word> words = await DatabaseService().getWordsByIds(widget.activeLang, ids);
    
    if (words.isEmpty) return;
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardSessionScreen(words: words),
      ),
    );
  }

  void _startLearning() async {
    if (_selectedDifficulties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vali vähemalt üks raskusaste!')),
      );
      return;
    }

    // Kuvame laadimise indikaatorit, kuni otsime andmebaasist sobivaid sõnu
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Kasutame nüüd uut andmebaasi funktsiooni ja aktiivset keelt
    List<Word> words = await DatabaseService().getFlashcardsBatch(
      widget.activeLang, 
      _selectedDifficulties, 
      _selectedCount,
    );

    if (!mounted) return;
    Navigator.pop(context); // Sulgeme laadimisakna

    // Kui valitud kriteeriumitega sõnu ei leitud (või baas on tühi)
    if (words.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selliseid sõnu ei leitud! Proovi muid seadeid.')),
      );
      return;
    }

    // Lähme mängima!
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardSessionScreen(words: words),
      ),
    );
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
              // PEALKIRI EEMALDATUD
              const SizedBox(height: 10),

              // 1. RASKUSASTE (SWITCHID 2 TULPA)
              const Text(
                'Raskusaste',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 0,
                children: _difficultyNames.entries.map((entry) {
                  int diffValue = entry.key;
                  String diffName = entry.value;

                  return FractionallySizedBox(
                    widthFactor: 0.48,
                    child: SwitchListTile( // CHECKBOX ASENDATUD SWITCHIGA
                      contentPadding: EdgeInsets.zero,
                      title: Text(diffName, style: const TextStyle(fontSize: 15)),
                      value: _selectedDifficulties.contains(diffValue),
                      activeColor: Colors.blue,
                      onChanged: (bool value) {
                        setState(() {
                          if (value) {
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

              //const Spacer(), // Lükkab nupu ekraani allaäärde
              const SizedBox(height: 20),

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
              const SizedBox(height: 20),
            // =====================================
              // UUS: MINU KOMPLEKTID SEKTSIOON
              // =====================================
              const Divider(height: 1, thickness: 1), // Eraldusjoon
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Minu komplektid',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.blue, size: 28),
                    onPressed: () async {
                      // Avame loomise akna ja ootame, kas kasutaja salvestas midagi
                      bool? changed = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CustomSetEditScreen(activeLang: widget.activeLang)),
                      );
                      if (changed == true) _loadCustomSets(); // Kui salvestas, laeme nimekirja uuesti!
                    },
                  )
                ],
              ),
              const SizedBox(height: 10),

              // KUVAME TÜHJA TEKSTI VÕI NIMEKIRJA
              if (_customSets.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Sul ei ole veel oma loodud kaardikomplekte.',
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                )
              else
                // Et ListView saaks Columni sees elada, mähime ta Expanded sisse
                Expanded(
                  child: ListView.separated(
                    itemCount: _customSets.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final setMap = _customSets[index];
                      return InkWell(
                        onTap: () => _startCustomSetGame(setMap), // Kogu rida käivitab mängu
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.folder, color: Colors.blueGrey),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(setMap['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                    Text('${(setMap['wordIds'] as List).length} sõna', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.grey),
                                onPressed: () async {
                                  // Avame muutmise akna
                                  bool? changed = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => CustomSetEditScreen(activeLang: widget.activeLang, existingSet: setMap)),
                                  );
                                  if (changed == true) _loadCustomSets();
                                },
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}