import 'dart:math';

import '../logic/text_normalizer.dart';
import '../models/word.dart';
import 'game_result.dart';

enum MatchOutcome { none, match, mismatch }

/// "Parejas": une cada palabra en inglés con su traducción. Se eligen al azar
/// hasta [maxPairs] palabras (sin traducciones repetidas) y las dos columnas se
/// mezclan por separado.
class MatchRound {
  MatchRound(List<Word> words, {Random? random, this.maxPairs = 6}) : random = random ?? Random() {
    final seen = <String>{};
    pairs = [
      for (final w in [...words]..shuffle(this.random))
        if (seen.add(normalizeText(w.spanish)) && seen.add('en:${normalizeText(w.english)}')) w,
    ].take(maxPairs).toList();
    left = [...pairs]..shuffle(this.random);
    right = [...pairs]..shuffle(this.random);
  }

  final Random random;
  final int maxPairs;
  late final List<Word> pairs;

  /// Columna izquierda (inglés) y derecha (español), en orden mezclado.
  late final List<Word> left;
  late final List<Word> right;

  final Set<String> matched = {};
  final Set<String> _missed = {};
  final Stopwatch _clock = Stopwatch()..start();

  String? selectedLeft;
  String? selectedRight;
  int mistakes = 0;

  bool get finished => matched.length == pairs.length;

  Duration get elapsed => _clock.elapsed;

  MatchOutcome selectLeft(String id) {
    if (matched.contains(id)) return MatchOutcome.none;
    selectedLeft = selectedLeft == id ? null : id;
    return _resolve();
  }

  MatchOutcome selectRight(String id) {
    if (matched.contains(id)) return MatchOutcome.none;
    selectedRight = selectedRight == id ? null : id;
    return _resolve();
  }

  MatchOutcome _resolve() {
    final l = selectedLeft;
    final r = selectedRight;
    if (l == null || r == null) return MatchOutcome.none;
    if (l == r) {
      matched.add(l);
      selectedLeft = selectedRight = null;
      if (finished) _clock.stop();
      return MatchOutcome.match;
    }
    mistakes++;
    _missed..add(l)..add(r);
    return MatchOutcome.mismatch;
  }

  /// Quita la selección tras un error (la interfaz lo llama tras mostrarlo).
  void clearSelection() {
    selectedLeft = selectedRight = null;
  }

  GameResult result() {
    final score = max(0, pairs.length * 100 - mistakes * 25);
    return GameResult(
      mode: GameMode.match,
      score: score,
      stars: mistakes <= 1 ? 3 : (mistakes <= 3 ? 2 : 1),
      correct: pairs.length,
      total: pairs.length + mistakes,
      bestStreak: 0,
      missed: pairs.where((w) => _missed.contains(w.id)).toList(),
      duration: _clock.elapsed,
    );
  }
}
