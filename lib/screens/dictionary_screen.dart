import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Vajalik kopeerimiseks
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart'; // Sinu pubspec-is olemasolev pakett
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../models/word.dart';
import '../services/database_service.dart';

class DictionaryScreen extends StatefulWidget {
  // Esialgu võtame suuna parameetrina, tulevikus saad seda globaalselt manageerida (nt Provider/Riverpod)
  final String activeLang; 

  const DictionaryScreen({super.key, this.activeLang = 'es'});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final DatabaseService _dbService = DatabaseService();
  final ItemScrollController _itemScrollController = ItemScrollController();

  List<Word> _words = [];
  Set<String> _availableLetters = {};
  bool _isLoading = true;

  // Erinevad tähestikud
  final List<String> _alphabetEs = 'abcdefghijklmnñopqrstuvwxyz'.split('');
  final List<String> _alphabetEt = 'abcdefghijklmnopqrsšzžtuvwõäöüxy'.split('');

  @override
  void initState() {
    super.initState();
    _loadDictionary();
  }

  Future<void> _loadDictionary() async {
    setState(() => _isLoading = true);
    
    List<Word> loadedWords = await _dbService.getAllCachedWords(widget.activeLang);
    Set<String> letters = {};
    
    // Kaardistame olemasolevad esitähed
    for (var word in loadedWords) {
      if (word.algvorm.isNotEmpty) {
        letters.add(word.algvorm[0].toLowerCase());
      }
    }

    setState(() {
      _words = loadedWords;
      _availableLetters = letters;
      _isLoading = false;
    });
  }

  void _scrollToLetter(String letter) {
    if (!_availableLetters.contains(letter)) return;

    // Otsime esimese sõna indeksi, mis algab valitud tähega
    int index = _words.indexWhere((w) => w.algvorm.toLowerCase().startsWith(letter));
    if (index != -1) {
      // jumpTo hüppab koheselt, scrollTo teeb sujuva kerimise
      _itemScrollController.jumpTo(index: index); 
    }
  }

  void _showWordDetails(Word word) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // Sõna algvorm
                Expanded(
                  child: Text(
                    word.algvorm,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
                // KOPEERIMISE NUPP
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 20, color: Colors.blue),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: word.algvorm));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sõna kopeeritud lõikelauale'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                // SULGEMISE NUPP
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              // MARKDOWN KUVAJA JA VALITAV TEKST
              child: MarkdownBody(
                data: word.sisuMd.isEmpty ? "Sisu puudub." : word.sisuMd,
                selectable: true, // Teeb sisu kopeeritavaks
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(fontSize: 17, height: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_words.isEmpty) {
      return const Center(
        child: Text(
          'Sõnastik on tühi.\nSünkroniseeri andmed avakuvalt.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    List<String> currentAlphabet = widget.activeLang == 'es' ? _alphabetEs : _alphabetEt;

    return Row(
      children: [
        // Vasak pool: Sõnade nimekiri
        Expanded(
          child: ScrollablePositionedList.builder(
            itemCount: _words.length,
            itemBuilder: (context, index) {
              final word = _words[index];
              return InkWell( // Muudab Terve rea vajutatavaks nupuks
                onTap: () => _showWordDetails(word),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.withOpacity(0.15)),
                    ),
                  ),
                  child: Text(
                    word.algvorm,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              );
            },
            itemScrollController: _itemScrollController,
          ),
        ),

        // Parem pool: Dünaamiline tähestiku külgriba
        Container(
          width: 32,
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            children: currentAlphabet.map((letter) {
              bool isAvailable = _availableLetters.contains(letter);
              return Expanded(
                child: GestureDetector(
                  onTap: () => _scrollToLetter(letter),
                  behavior: HitTestBehavior.opaque, // Teeb ka tühja ala vajutatavaks
                  child: Center(
                    child: Text(
                      letter.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isAvailable ? FontWeight.bold : FontWeight.normal,
                        color: isAvailable ? Colors.blue : Colors.grey[400],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}