import 'word.dart';

/// Máximo de caracteres del título (igual que la restricción de la base de datos).
const maxTitleLength = 120;

/// Un vocabulario completo: título opcional y sus palabras en orden de
/// llegada (la primera ocupa la primera casilla de la grilla).
class Vocabulary {
  const Vocabulary({
    this.id,
    this.title = '',
    this.words = const [],
    this.updatedAt,
  });

  /// `null` mientras no se ha guardado nunca.
  final String? id;
  final String title;
  final List<Word> words;
  final DateTime? updatedAt;
}

/// Resumen para la lista "Mis vocabularios".
class VocabularySummary {
  const VocabularySummary({
    required this.id,
    required this.title,
    required this.wordCount,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final int wordCount;
  final DateTime updatedAt;

  String get displayTitle => title.trim().isEmpty ? 'Sin título' : title;
}
