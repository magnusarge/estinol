class Word {
  final String id;
  final String algvorm;
  final String otsingVorm; // UUS VÄLI!
  final String sisuMd;
  final int raskusaste;

  Word({
    required this.id,
    required this.algvorm,
    required this.otsingVorm,
    required this.sisuMd,
    required this.raskusaste,
  });

  factory Word.fromMap(String key, Map<String, dynamic> data) {
    return Word(
      id: key, // See on nüüd suvaline jada (UUID)
      algvorm: data['algvorm'] ?? '',
      otsingVorm: data['otsing_vorm'] ?? '', // Loeme baasist
      sisuMd: data['sisu_md'] ?? '',
      raskusaste: data['raskusaste'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'algvorm': algvorm,
      'otsing_vorm': otsingVorm,
      'sisu_md': sisuMd,
      'raskusaste': raskusaste,
    };
  }
}