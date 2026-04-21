import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../models/word.dart';

class WordCard extends StatelessWidget {
  final Word word;
  final bool isAdmin;

  const WordCard({
    super.key,
    required this.word,
    this.isAdmin = false, // Vaikimisi tavakasutaja vaade
  });

  // Kopeerimise funktsioon
  void _copyWord(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: word.algvorm));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Kopeeritud: ${word.algvorm}"),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green.shade600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        // Õrn vari kaardile
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Tekst võtab maksimaalse vaba ruumi
              Expanded(
                child: Text(
                  word.algvorm,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ),
              // Kopeerimise nupp kohe paremas ääres, samas stiilis nagu listis
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 20, color: Colors.blue),
                tooltip: "Kopeeri sõna",
                onPressed: () => _copyWord(context),
              ),
              // Admini nupud joonduvad samuti paremale
              if (isAdmin) ...[
                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () {}),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {}),
              ],
            ],
          ),
          const Divider(),
          const SizedBox(height: 10),
          // Markdown tehakse valitavaks
          MarkdownBody(
            data: word.sisuMd.isEmpty ? "Sisu puudub." : word.sisuMd,
            selectable: true, 
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}