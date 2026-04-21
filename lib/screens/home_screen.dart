import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/word.dart';
import '../widgets/word_card.dart';

class HomeScreen extends StatefulWidget {
  final String activeLang; // 1. Defineerime muutuja

  // 2. Nõuame seda konstruktoris (required this.activeLang)
  const HomeScreen({super.key, required this.activeLang}); 

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  
  List<Word> _searchResults = [];
  bool _isLoading = false;
  Word? _randomWord;

  @override
  void initState() {
    super.initState();
    _initialSync();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Kui keele suund muutub nupust
    if (oldWidget.activeLang != widget.activeLang) {
      setState(() {
        _randomWord = null; // Teeme vana keele sõnast ekraani puhtaks
        _searchController.clear();
        _searchResults = [];
      });
      _initialSync(); // Laeme andmed uues keeles
    }
  }

  void _initialSync() async {
    setState(() => _isLoading = true);
    
    // KASUTAME DÜNAAMILIST KEELT, MITTE 'es'
    await _dbService.syncDictionary(widget.activeLang);
    
    if (_searchController.text.isNotEmpty) {
      _onSearchChanged(_searchController.text);
    } else {
      _loadRandomWord();
    }
  }

  void _loadRandomWord() async {
    // OTSIME SUVALIST SÕNA ÕIGES KEELES
    Word? word = await _dbService.getRandomWord(widget.activeLang);
    if (mounted) {
      setState(() {
        _randomWord = word;
        _isLoading = false;
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

    setState(() => _isLoading = true);

    // OTSIME SÕNU ÕIGES KEELES
    List<Word> results = await _dbService.searchWordsLocally(widget.activeLang, query);

    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchResults = [];
      _loadRandomWord();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, 
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                // Dünaamiline vihjetekst otsingukastis
                hintText: widget.activeLang == 'es' 
                    ? 'Otsi hispaania keeles...' 
                    : 'Otsi eesti keeles...',
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

    if (_searchController.text.trim().length < 2) {
       if (_randomWord == null) {
         // Lisame sõnumi juhuks, kui vahetad 'et' keele peale, aga andmebaas on veel tühi
         return Center(
           child: Text(
             widget.activeLang == 'es' 
                ? 'Sõnu ei leitud. Veendu ühenduses.' 
                : 'Eesti keele sõnu pole veel andmebaasi lisatud.',
             textAlign: TextAlign.center,
             style: const TextStyle(color: Colors.grey),
           ),
         ); 
       }
       
       return ListView(
         children: [
           Padding(
             padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text(
                   '✨ Avasta uus sõna',
                   style: TextStyle(
                     fontSize: 18, 
                     fontWeight: FontWeight.bold, 
                     color: Colors.blueGrey.shade400
                   ),
                 ),
                 IconButton(
                   icon: const Icon(Icons.refresh_rounded, color: Colors.blue),
                   onPressed: _loadRandomWord, 
                   tooltip: 'Laadi uus sõna',
                 ),
               ],
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