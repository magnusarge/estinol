import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/word.dart';
import '../widgets/word_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  
  List<Word> _searchResults = [];
  bool _isLoading = false;
  Word? _randomWord; // UUS: Hoiab meie juhuslikku sõna

  @override
  void initState() {
    super.initState();
    _initialSync();
  }

  void _initialSync() async {
    await _dbService.syncDictionary('es');
    
    if (_searchController.text.isNotEmpty) {
      _onSearchChanged(_searchController.text);
    } else {
      // Kui otsing on tühi, laeme juhusliku sõna!
      _loadRandomWord();
    }
  }

  // UUS FUNKTSIOON: Laeb baasist juhusliku sõna
  void _loadRandomWord() async {
    Word? word = await _dbService.getRandomWord('es');
    if (mounted) {
      setState(() {
        _randomWord = word;
      });
    }
  }

  void _onSearchChanged(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    List<Word> results = await _dbService.searchWordsLocally('es', query);

    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchResults = [];
      _loadRandomWord(); // Laeme uue juhusliku sõna, kui ristist kinni pannakse!
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Otsi hispaania keeles...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: _clearSearch,
                    )
                  : null,
            ),
          ),
          
          const SizedBox(height: 20),
          
          Expanded(
            child: _buildResultsArea(),
          )
        ],
      ),
    );
  }

  Widget _buildResultsArea() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.trim().length >= 2 && _searchResults.isEmpty) {
      return const Center(
        child: Text(
          'Sõna ei leitud.',
          style: TextStyle(color: Colors.redAccent, fontSize: 16),
        ),
      );
    }

    // UUS LOOGIKA: Kui otsing on tühi, näitame juhuslikku sõna
    if (_searchController.text.trim().length < 2) {
       if (_randomWord == null) {
         // Kui baas on alles laadimisel või täiesti tühi
         return const SizedBox(); 
       }
       
       return ListView(
         children: [
           Padding(
             padding: const EdgeInsets.only(bottom: 16.0, left: 4.0),
             child: Text(
               '✨ Avasta uus sõna',
               style: TextStyle(
                 fontSize: 18, 
                 fontWeight: FontWeight.bold, 
                 color: Colors.blueGrey.shade400
               ),
             ),
           ),
           WordCard(word: _randomWord!),
         ],
       );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return WordCard(word: _searchResults[index]);
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}