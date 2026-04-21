import 'dart:math';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word.dart';
import '../utils.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 1. SÜNKRONISEERIMINE: Tõmbab pilvest ainult uuenenud andmed
  Future<void> syncDictionary(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    
    try {
      // Pärime jälgimisdokumendi, kus on kirjas kõigi failide viimased muutmise ajad
      DocumentSnapshot changesDoc = await _db.collection('data').doc('changes').get();
      
      if (!changesDoc.exists) return;
      
      Map<String, dynamic> remoteTimestamps = changesDoc.data() as Map<String, dynamic>;

      // Käime läbi kõik tähed/võtmed (nt "es_a", "es_b" jne)
      for (String key in remoteTimestamps.keys) {
        // Kontrollime, kas see võti kuulub praegusele keelele (nt algab "es_")
        if (key.startsWith('${lang}_')) {
          String letter = key.split('_')[1]; // Eraldame tähe, nt "a"
          
          int remoteTime = remoteTimestamps[key] ?? 0;
          int localTime = prefs.getInt('sync_time_${lang}_$letter') ?? 0;

          // Kui serveris on uuem aeg, laeme selle tähe dokumendi alla!
          if (remoteTime > localTime) {
            await _downloadAndCacheLetter(lang, letter, remoteTime, prefs);
          }
        }
      }
    } catch (e) {
      print("Viga sünkroniseerimisel (võib-olla pole internetti): $e");
    }
  }

  /// Abifunktsioon ühe tähe dokumendi allalaadimiseks ja lokaalselt salvestamiseks
  Future<void> _downloadAndCacheLetter(String lang, String letter, int newTime, SharedPreferences prefs) async {
    DocumentSnapshot doc = await _db.collection('words_$lang').doc(letter).get();
    
    if (doc.exists && doc.data() != null) {
      // Salvestame dokumendi sisu (JSON) otse telefoni mällu
      String jsonString = jsonEncode(doc.data());
      await prefs.setString('cache_${lang}_$letter', jsonString);
      
      // Uuendame lokaalset ajatemplit, et me seda homme uuesti ei tõmbaks
      await prefs.setInt('sync_time_${lang}_$letter', newTime);
      print("✅ Uuendatud lokaalne vahemälu: $lang -> $letter");
    }
  }

  /// 2. OTSING: Välkkiire otsing otse lokaalsest mälust (ilma internetita!)
  Future<List<Word>> searchWordsLocally(String lang, String query) async {
    String normalizedQuery = Utils.normalizeSearchText(query.trim());
    if (normalizedQuery.isEmpty) return [];

    // Saame päringu esimese tähe (selle järgi teame, millisest failist otsida)
    String firstLetter = normalizedQuery[0];
    
    final prefs = await SharedPreferences.getInstance();
    String? cachedData = prefs.getString('cache_${lang}_$firstLetter');

    if (cachedData == null) {
      return []; // Seda tähte pole veel vahemälus
    }

    Map<String, dynamic> wordsMap = jsonDecode(cachedData);
    List<Word> results = [];

    // Otsime lokaalsest JSON objektist vasteid
    wordsMap.forEach((key, value) {
      // Vaatame nüüd andmete sisse, mitte enam võtit!
      String otsingVorm = value['otsing_vorm'] ?? '';
      
      if (otsingVorm.startsWith(normalizedQuery)) {
        results.add(Word.fromMap(key, value));
      }
    });

    // Sorteerime tulemused tähestiku järjekorda
    results.sort((a, b) => a.algvorm.compareTo(b.algvorm));
    return results;
  }

  /// 3. JUHUSLIK SÕNA: Leiab vahemälust ühe suvalise sõna
  Future<Word?> getRandomWord(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Leiame kõik võtmed, mis on seotud selle keele vahemäluga
    final keys = prefs.getKeys().where((k) => k.startsWith('cache_${lang}_')).toList();
    
    if (keys.isEmpty) return null; // Andmebaas on veel tühi

    // 1. Valime juhusliku tähe (faili)
    final randomKey = keys[Random().nextInt(keys.length)];
    final cachedData = prefs.getString(randomKey);
    
    if (cachedData == null) return null;

    Map<String, dynamic> wordsMap = jsonDecode(cachedData);
    if (wordsMap.isEmpty) return null;

    // 2. Valime sellest failist juhusliku sõna
    final wordKeys = wordsMap.keys.toList();
    final randomWordId = wordKeys[Random().nextInt(wordKeys.length)];
    
    return Word.fromMap(randomWordId, wordsMap[randomWordId]);
  }

  /// 4. KÕIKIDE SÕNADE LAADIMINE (Nimekirja jaoks)
  Future<List<Word>> getAllCachedWords(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Leiame kõik antud keele failid
    final keys = prefs.getKeys().where((k) => k.startsWith('cache_${lang}_')).toList();
    
    List<Word> allWords = [];

    for (String key in keys) {
      String? cachedData = prefs.getString(key);
      if (cachedData != null) {
        Map<String, dynamic> wordsMap = jsonDecode(cachedData);
        wordsMap.forEach((wordId, wordData) {
          allWords.add(Word.fromMap(wordId, wordData));
        });
      }
    }

    // Sorteerime tulemused algvormi järgi tähestiku järjekorda
    allWords.sort((a, b) => a.algvorm.toLowerCase().compareTo(b.algvorm.toLowerCase()));
    
    return allWords;
  }
}