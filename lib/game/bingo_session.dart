import 'dart:math';

import '../logic/grid_builder.dart';
import '../models/word.dart';
import 'game_result.dart';

enum TapOutcome { ignored, correct, wrong }

/// "Bingo cantado": se canta una palabra en español y hay que encontrar su
/// traducción en el cartón (la grilla del vocabulario). Se gana al completar una
/// fila (o una columna) o todo el cartón. Fallar cuesta una vida.
class BingoSession {
  BingoSession(List<Word> words, {Random? random, this.lives = 3})
      : random = random ?? Random(),
        board = buildGrid(words),
        maxLives = lives {
    final occupied = [for (final s in board) if (!s.isPlaceholder) s.index];
    calls = occupied..shuffle(this.random);
  }

  final Random random;
  final List<GridSlot> board;
  final int maxLives;
  int lives;

  /// Casillas (índices) en el orden en que se cantan.
  late final List<int> calls;
  int _callPos = 0;
  final Set<int> marked = {};
  final Set<int> _missedSlots = {};
  final Stopwatch _clock = Stopwatch()..start();

  int correct = 0;
  int mistakes = 0;
  int streak = 0;
  int bestStreak = 0;
  bool bingo = false;

  int get occupiedCount => calls.length;
  bool get lost => lives <= 0;
  bool get finished => bingo || lost;

  /// Casilla cantada ahora, o null si terminó.
  GridSlot? get currentCall => _callPos < calls.length && !finished ? board[calls[_callPos]] : null;

  TapOutcome tap(int index) {
    final call = currentCall;
    if (call == null || index < 0 || index >= board.length) return TapOutcome.ignored;
    final slot = board[index];
    if (slot.isPlaceholder || marked.contains(index)) return TapOutcome.ignored;
    if (index == call.index) {
      marked.add(index);
      correct++;
      streak++;
      bestStreak = max(bestStreak, streak);
      _callPos++;
      bingo = _hasLine() || marked.length == occupiedCount;
      return TapOutcome.correct;
    }
    mistakes++;
    streak = 0;
    lives--;
    _missedSlots.add(call.index);
    return TapOutcome.wrong;
  }

  /// Fila de 5 (o columna de 6) completa y marcada.
  bool _hasLine() {
    bool full(Iterable<int> cells) => cells.every((i) => !board[i].isPlaceholder && marked.contains(i));
    for (var r = 0; r < gridRows; r++) {
      if (full([for (var c = 0; c < gridColumns; c++) r * gridColumns + c])) return true;
    }
    for (var c = 0; c < gridColumns; c++) {
      if (full([for (var r = 0; r < gridRows; r++) r * gridColumns + c])) return true;
    }
    return false;
  }

  /// Casillas de la línea ganadora (para resaltarlas).
  Set<int> get winningCells {
    if (!bingo) return {};
    bool full(List<int> cells) => cells.every((i) => !board[i].isPlaceholder && marked.contains(i));
    for (var r = 0; r < gridRows; r++) {
      final cells = [for (var c = 0; c < gridColumns; c++) r * gridColumns + c];
      if (full(cells)) return cells.toSet();
    }
    for (var c = 0; c < gridColumns; c++) {
      final cells = [for (var r = 0; r < gridRows; r++) r * gridColumns + c];
      if (full(cells)) return cells.toSet();
    }
    return marked;
  }

  GameResult result() {
    final won = bingo;
    return GameResult(
      mode: GameMode.bingo,
      score: correct * 100 + (won ? lives * 150 : 0),
      stars: won ? max(1, lives) : 0,
      correct: correct,
      total: correct + mistakes,
      bestStreak: bestStreak,
      missed: [
        for (final i in _missedSlots)
          Word(
            id: board[i].slotId,
            english: board[i].english,
            spanish: board[i].spanish,
            phonetic: board[i].phonetic,
            createdAt: 0,
          ),
      ],
      duration: _clock.elapsed,
      won: won,
      headline: won ? '¡BINGO!' : '¡Sin vidas!',
    );
  }
}
