import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../models/word.dart';

class FlashcardSessionScreen extends StatefulWidget {
  final List<Word> words;

  const FlashcardSessionScreen({super.key, required this.words});

  @override
  State<FlashcardSessionScreen> createState() => _FlashcardSessionScreenState();
}

class _FlashcardSessionScreenState extends State<FlashcardSessionScreen> {
  int _currentIndex = 0;
  bool _isFlipped = false;

  void _nextCard() {
    if (_currentIndex < widget.words.length - 1) {
      setState(() {
        _currentIndex++;
        _isFlipped = false; // Uus kaart on alati peidetud vastusega
      });
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tubli töö! 🎉', textAlign: TextAlign.center),
        content: const Text(
          'Oled kõik valitud kaardid läbi vaadanud. Puhka natuke või alusta uut sessiooni!',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context); // Sulge dialog
              Navigator.pop(context); // Mine tagasi seadete lehele
            },
            child: const Text('Lõpeta'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.words[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Kaart ${_currentIndex + 1} / ${widget.words.length}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // PROGRESSIRIBA
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / widget.words.length,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
              const SizedBox(height: 40),

              // KAART ISE (Interaktiivne ala)
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!_isFlipped) {
                      setState(() => _isFlipped = true);
                    }
                  },
                  // Animatsioon kaardi pööramiseks
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: animation,
                          child: child,
                        ),
                      );
                    },
                    child: _isFlipped ? _buildBackSide(word) : _buildFrontSide(word),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // NUPUD (Nähtavad ainult siis, kui kaart on pööratud)
              AnimatedOpacity(
                opacity: _isFlipped ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red.shade900,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      ),
                      onPressed: _isFlipped ? _nextCard : null, // Hiljem saame siia lisada negatiivse skoori loogika
                      icon: const Icon(Icons.close),
                      label: const Text('Ei teadnud', style: TextStyle(fontSize: 16)),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade50,
                        foregroundColor: Colors.green.shade900,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      ),
                      onPressed: _isFlipped ? _nextCard : null,
                      icon: const Icon(Icons.check),
                      label: const Text('Teadsin', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // KAARDI ESIMENE POOL (Ainult sõna)
  Widget _buildFrontSide(Word word) {
    return Container(
      key: const ValueKey(1), // ValueKey on AnimatedSwitcherile vajalik!
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 5),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              word.algvorm,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Vajuta kaardile',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            )
          ],
        ),
      ),
    );
  }

  // KAARDI TAGUMINE POOL (Sisu ja Markdown)
  Widget _buildBackSide(Word word) {
    return Container(
      key: const ValueKey(2),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.shade50, // Õrn toon tagaküljel aitab visuaalselt eristada
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 5),
        ],
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        children: [
          Text(
            word.algvorm,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const Divider(height: 30),
          Expanded(
            child: SingleChildScrollView(
              child: MarkdownBody(
                data: word.sisuMd.isEmpty ? "Sisu puudub." : word.sisuMd,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(fontSize: 18, height: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}