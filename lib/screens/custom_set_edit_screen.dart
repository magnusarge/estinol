import 'package:flutter/material.dart';
import '../models/word.dart';
import '../services/database_service.dart';

class CustomSetEditScreen extends StatefulWidget {
  final String activeLang;
  final Map<String, dynamic>? existingSet; // Kui on null, siis loome uue, kui on antud, siis muudame

  const CustomSetEditScreen({super.key, required this.activeLang, this.existingSet});

  @override
  State<CustomSetEditScreen> createState() => _CustomSetEditScreenState();
}

class _CustomSetEditScreenState extends State<CustomSetEditScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<Word> _allCachedWords = [];
  List<Word> _selectedWords = [];
  List<Word> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    // Laeme KÕIK lokaalsed sõnad korraks mällu, et otsing oleks välkkiire
    _allCachedWords = await _dbService.getAllCachedWords(widget.activeLang);

    if (widget.existingSet != null) {
      _nameController.text = widget.existingSet!['name'];
      List<dynamic> ids = widget.existingSet!['wordIds'];
      _selectedWords = await _dbService.getWordsByIds(widget.activeLang, ids);
    }
    setState(() {});
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    
    final lowerQuery = query.toLowerCase();
    setState(() {
      _searchResults = _allCachedWords.where((word) {
        // Otsime alguse järgi ja välistame need, mis on juba komplektis
        bool matches = word.algvorm.toLowerCase().startsWith(lowerQuery);
        bool notAlreadyAdded = !_selectedWords.any((w) => w.id == word.id);
        return matches && notAlreadyAdded;
      }).take(8).toList(); // Piirame visuaalselt soovituste arvu
    });
  }

  void _addWord(Word word) {
    setState(() {
      _selectedWords.insert(0, word); // Lisame nimekirja tippu
      _searchController.clear();
      _searchResults = [];
    });
  }

  void _saveSet() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Palun sisesta komplektile nimi!')));
      return;
    }
    if (_selectedWords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Komplekt ei saa olla tühi!')));
      return;
    }

    String setId = widget.existingSet?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    List<String> ids = _selectedWords.map((w) => w.id).toList();

    await _dbService.saveCustomSet(widget.activeLang, setId, _nameController.text.trim(), ids);
    if (mounted) Navigator.pop(context, true); // true tähendab, et midagi muutus
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kustuta komplekt?'),
        content: const Text('Kas oled kindel, et soovid selle kaardikomplekti jäädavalt kustutada?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Katkesta')),
          TextButton(
            onPressed: () async {
              await _dbService.deleteCustomSet(widget.activeLang, widget.existingSet!['id']);
              if (mounted) {
                Navigator.pop(context); // Sulge dialog
                Navigator.pop(context, true); // Mine tagasi ja anna teada muudatusest
              }
            },
            child: const Text('Kustuta', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingSet == null ? 'Uus komplekt' : 'Muuda komplekti'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. NIME LAHTER
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Komplekti nimi',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),

              // 2. OTSINGU LAHTER
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Otsi sõna (algab tähega...)',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

              // 3. SOOVITUSTE NIMEKIRI (Kuvatakse ainult siis, kui on tulemusi)
              if (_searchResults.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.blue.shade100),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
                  ),
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final word = _searchResults[index];
                      return ListTile(
                        title: Text(word.algvorm, style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: const Icon(Icons.add_circle, color: Colors.blue),
                        onTap: () => _addWord(word),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 20),

              // 4. INFO SÕNADE ARVU KOHTA
              Text(
                'Sõnu komplektis: ${_selectedWords.length}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 10),

              // 5. LOHISTATAV (REORDERABLE) NIMEKIRI
              Expanded(
                child: ReorderableListView.builder(
                  itemCount: _selectedWords.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = _selectedWords.removeAt(oldIndex);
                      _selectedWords.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final word = _selectedWords[index];
                    return ListTile(
                      key: ValueKey(word.id), // Nõutud lohistamiseks!
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                      leading: const Icon(Icons.drag_handle, color: Colors.grey),
                      title: Text(word.algvorm),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () {
                          setState(() => _selectedWords.removeAt(index)); // Kustutab kohe ilma küsimata
                        },
                      ),
                    );
                  },
                ),
              ),

              // 6. ALUMISED NUPUD
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Katkesta'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: _saveSet,
                      child: const Text('Salvesta', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (widget.existingSet != null) ...[
                    const SizedBox(width: 10),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        padding: const EdgeInsets.all(15),
                      ),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: _confirmDelete,
                    ),
                  ]
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}