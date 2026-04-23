import 'dart:math';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word.dart';
import '../utils.dart';

class DatabaseService {
  // --- UUS: SINGLETONI LOOGIKA ---
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal(); // Privaatne konstruktor
  // --------------------------------

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Kuna kõik ekraanid jagavad nüüd ühtteist DatabaseService'i,
  // jagavad nad edukalt ka seda sama muutujat!
  Future<void>? _activeSyncFuture;

  void _logFirestoreCall(String action) {
    final now = DateTime.now();
    final timeString = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}";
    print('🔥 [FIRESTORE PÄRING] $timeString -> $action');
  }

  /// VÄLISPOOLT VÄLJAKUTSUTAV FUNKTSIOON
  Future<void> syncDictionary(String lang) {
    if (_activeSyncFuture != null) {
      print('⏳ Sünkroniseerimine juba käib, jagan olemasolevat päringut.');
      return _activeSyncFuture!;
    }

    _activeSyncFuture = _performSync(lang).whenComplete(() {
      _activeSyncFuture = null;
    });

    return _activeSyncFuture!;
  }

  /// SIIN TOIMUB REAALNE ANDMEBAASIGA SUHTLEMINE
  Future<void> _performSync(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    
    try {
      _logFirestoreCall("Loen 'changes' dokumenti");
      DocumentSnapshot changesDoc = await _db.collection('data').doc('changes').get();
      
      if (!changesDoc.exists) return;
      
      Map<String, dynamic> remoteTimestamps = changesDoc.data() as Map<String, dynamic>;

      for (String key in remoteTimestamps.keys) {
        if (key.startsWith('${lang}_')) {
          String letter = key.split('_')[1]; 
          
          int remoteTime = remoteTimestamps[key] ?? 0;
          int localTime = prefs.getInt('sync_time_${lang}_$letter') ?? 0;

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
    _logFirestoreCall("Laen alla uued sõnad: sõnastik $lang, täht $letter");
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

  // ==========================================
  // FLASHCARDS (JUHUSLIK VALIK)
  // ==========================================

  /// Leiab etteantud arvu juhuslikke sõnu valitud raskusastmete põhjal
  Future<List<Word>> getFlashcardsBatch(String lang, Set<int> allowedDifficulties, int count) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('cache_${lang}_')).toList();

    List<Word> validWords = [];

    // Käime kõik lokaalsed failid läbi ja korjame välja ainult sobiva raskusastmega sõnad
    for (String key in keys) {
      String? cachedData = prefs.getString(key);
      if (cachedData != null) {
        Map<String, dynamic> wordsMap = jsonDecode(cachedData);
        wordsMap.forEach((wordId, wordData) {
          int difficulty = wordData['raskusaste'] ?? 0;
          
          if (allowedDifficulties.contains(difficulty)) {
            validWords.add(Word.fromMap(wordId, wordData));
          }
        });
      }
    }

    // Segame nimekirja suvalisse järjekorda
    validWords.shuffle();

    // Tagastame soovitud arvu sõnu (või kõik, mis leidsime, kui neid on vähem kui küsiti)
    return validWords.take(count).toList();
  }


// ==========================================
  // OMA KOMPLEKTID (CUSTOM SETS - LOKAALNE)
  // ==========================================

  /// Loeb kõik kasutaja enda loodud komplektid valitud keeles
  Future<List<Map<String, dynamic>>> getCustomSets(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('custom_sets_$lang');
    if (data == null) return [];
    
    List<dynamic> decoded = jsonDecode(data);
    return decoded.cast<Map<String, dynamic>>();
  }

  /// Salvestab või uuendab komplekti
  Future<void> saveCustomSet(String lang, String id, String name, List<String> wordIds) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> sets = await getCustomSets(lang);
    
    int index = sets.indexWhere((s) => s['id'] == id);
    final newSet = {'id': id, 'name': name, 'wordIds': wordIds};
    
    if (index >= 0) {
      sets[index] = newSet; // Uuendame olemasolevat
    } else {
      sets.add(newSet); // Lisame uue
    }
    
    await prefs.setString('custom_sets_$lang', jsonEncode(sets));
  }

  /// Kustutab komplekti
  Future<void> deleteCustomSet(String lang, String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> sets = await getCustomSets(lang);
    sets.removeWhere((s) => s['id'] == id);
    await prefs.setString('custom_sets_$lang', jsonEncode(sets));
  }

  /// Teeb ID-de nimekirja põhjal lokaalsest vahemälust valmis Word objektide nimekirja (mängu alustamiseks)
  Future<List<Word>> getWordsByIds(String lang, List<dynamic> wordIds) async {
    List<Word> allWords = await getAllCachedWords(lang);
    List<Word> result = [];
    
    for (String id in wordIds) {
      try {
        // Otsime sõna üles ja säilitame kasutaja määratud järjekorra!
        result.add(allWords.firstWhere((w) => w.id == id));
      } catch (e) {
        // Kui sõna on andmebaasist vahepeal kustutatud, ignoreerime seda vaikselt
      }
    }
    return result;
  }

  // ==========================================
  // SEADETE SALVESTAMINE (PREFERENCES)
  // ==========================================

  /// Salvestab kaartide seaded
  Future<void> saveFlashcardSettings(Set<int> difficulties, int count) async {
    final prefs = await SharedPreferences.getInstance();
    // Salvestame raskusastmed JSON listina
    await prefs.setString('flashcard_difficulties', jsonEncode(difficulties.toList()));
    await prefs.setInt('flashcard_count', count);
  }

  /// Laeb varem salvestatud seaded
  Future<Map<String, dynamic>?> loadFlashcardSettings() async {
    final prefs = await SharedPreferences.getInstance();
    String? diffData = prefs.getString('flashcard_difficulties');
    int? count = prefs.getInt('flashcard_count');
    
    if (diffData == null && count == null) return null;
    
    Set<int> difficulties = {0, 1, 2, 3}; // Vaikeväärtus
    if (diffData != null) {
      List<dynamic> list = jsonDecode(diffData);
      difficulties = list.cast<int>().toSet();
    }
    
    return {
      'difficulties': difficulties,
      'count': count ?? 15,
    };
  }

}