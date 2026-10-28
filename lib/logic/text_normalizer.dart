const _diacritics = {
  'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a', 'å': 'a',
  'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
  'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
  'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o',
  'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
  'ñ': 'n', 'ç': 'c',
};

/// Minúsculas, sin espacios en los extremos y sin tildes, para comparar
/// respuestas de la evaluación sin ser estricto con acentos ni mayúsculas.
String normalizeText(String? text) {
  final lower = (text ?? '').trim().toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_diacritics[char] ?? char);
  }
  return buffer.toString();
}
