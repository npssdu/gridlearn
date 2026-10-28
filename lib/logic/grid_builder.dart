import '../models/word.dart';

const gridColumns = 5;
const gridRows = 6;
const gridSize = gridColumns * gridRows;

/// Una casilla del bingo. Las casillas vacías esperan una palabra nueva.
class GridSlot {
  const GridSlot({
    required this.slotId,
    required this.index,
    this.english = '',
    this.spanish = '',
    this.phonetic = '',
    this.isPlaceholder = false,
  });

  final String slotId;

  /// Posición de la casilla en la grilla (0 a 29).
  final int index;
  final String english;
  final String spanish;
  final String phonetic;
  final bool isPlaceholder;

  /// Fila de la grilla a la que pertenece (0 a 5).
  int get row => index ~/ gridColumns;
}

/// Coloca cada palabra en una sola casilla, siguiendo el orden en que se
/// agregaron: la primera palabra ocupa la primera casilla y cada palabra nueva
/// va a la siguiente casilla libre. Las casillas sobrantes quedan vacías.
///
/// [words] va en orden de llegada. Si hay más de 30, las que no caben quedan
/// fuera de la grilla pero siguen en el listado.
List<GridSlot> buildGrid(List<Word> words) {
  return List.generate(gridSize, (i) {
    if (i >= words.length) {
      return GridSlot(slotId: 'empty-$i', index: i, isPlaceholder: true);
    }
    final word = words[i];
    return GridSlot(
      slotId: word.id,
      index: i,
      english: word.english,
      spanish: word.spanish,
      phonetic: word.phonetic,
    );
  });
}
