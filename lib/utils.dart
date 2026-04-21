class Utils {
  /// Muudab teksti väiketähtedeks ja eemaldab täpitähed/erimärgid
  /// Näiteks: "Niño" -> "nino", "Sõna" -> "sona"
  static String normalizeSearchText(String text) {
    if (text.isEmpty) return "";
    
    String normalized = text.toLowerCase();
    
    const Map<String, String> diacritics = {
      'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ñ': 'n',
      'õ': 'o', 'ä': 'a', 'ö': 'o', 'ü': 'u', 'š': 's', 'ž': 'z',
    };

    diacritics.forEach((key, value) {
      normalized = normalized.replaceAll(key, value);
    });

    return normalized;
  }
}