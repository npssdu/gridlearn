import 'dart:math';

import '../models/word.dart';
import 'answer_checker.dart';
import 'game_result.dart';
import 'question.dart';
import 'question_factory.dart';

/// "Aventura": cada palabra sube de nivel al acertar y baja al fallar.
///
///   nivel 0  reconocer  → opción múltiple
///   nivel 1  armar      → ordenar letras (o la otra dirección si no se puede)
///   nivel 2  producir   → escribir
///   nivel 3  dominada
///
/// Se eligen al azar hasta [maxWords] palabras. Las falladas bajan de nivel y
/// vuelven más tarde (con más peso), no de inmediato: repetir espaciado retiene
/// más que repetir seguido.
class AdventureSession {
  AdventureSession(List<Word> words, {Random? random, this.maxWords = 8})
      : random = random ?? Random(),
        assert(words.isNotEmpty) {
    factory = QuestionFactory(words, random: this.random);
    selected = ([...words]..shuffle(this.random)).take(maxWords).toList();
    for (final w in selected) {
      _level[w.id] = 0;
      _misses[w.id] = 0;
      _cooldown[w.id] = 0;
    }
    _advance();
  }

  static const masteredLevel = 3;

  final Random random;
  final int maxWords;
  late final QuestionFactory factory;
  late final List<Word> selected;

  final Map<String, int> _level = {};
  final Map<String, int> _misses = {};
  final Map<String, int> _cooldown = {};
  String? _lastWordId;
  final Stopwatch _clock = Stopwatch()..start();

  Question? current;

  int score = 0;
  int streak = 0;
  int bestStreak = 0;
  int correct = 0;
  int answered = 0;

  /// Resultado de la última respuesta (hasta llamar a [next]).
  Verdict? lastVerdict;
  String lastFeedback = '';

  int levelOf(Word w) => _level[w.id] ?? 0;
  int get totalWords => selected.length;
  int get masteredCount => selected.where((w) => levelOf(w) >= masteredLevel).length;

  /// Avance 0..1: suma de niveles sobre el máximo posible.
  double get progress {
    final done = selected.fold<int>(0, (sum, w) => sum + levelOf(w));
    return done / (selected.length * masteredLevel);
  }

  int get _cap => selected.length * 5 + 3;
  bool get finished => masteredCount == selected.length || answered >= _cap;

  /// Palabras que se fallaron al menos una vez.
  List<Word> get missedWords => selected.where((w) => (_misses[w.id] ?? 0) > 0).toList();

  /// Envía la respuesta a la pregunta actual. No avanza: la interfaz muestra el
  /// resultado y luego llama a [next].
  Verdict submit(String given) {
    final q = current!;
    final verdict = evaluate(q, given);
    answered++;
    final id = q.word.id;
    if (verdict.isRight) {
      correct++;
      score += (verdict == Verdict.almost ? 70 : 100) + 20 * min(streak, 5);
      streak++;
      bestStreak = max(bestStreak, streak);
      _level[id] = levelOf(q.word) + 1;
      lastFeedback = verdict == Verdict.almost
          ? '¡Casi! Se escribe: ${q.answer}'
          : praises[random.nextInt(praises.length)];
    } else {
      streak = 0;
      _misses[id] = (_misses[id] ?? 0) + 1;
      _level[id] = max(0, levelOf(q.word) - 1);
      lastFeedback = 'La respuesta era: ${q.answer}';
    }
    lastVerdict = verdict;
    return verdict;
  }

  /// Pasa a la siguiente pregunta (o termina).
  void next() {
    lastVerdict = null;
    if (finished) {
      current = null;
      return;
    }
    _advance();
  }

  GameResult result() {
    final stars = finished && masteredCount == selected.length ? starsForAccuracy(accuracy) : 1;
    return GameResult(
      mode: GameMode.adventure,
      score: score,
      stars: stars,
      correct: correct,
      total: answered,
      bestStreak: bestStreak,
      missed: missedWords,
      duration: _clock.elapsed,
    );
  }

  double get accuracy => answered == 0 ? 0 : correct / answered;

  // --- Internos ---------------------------------------------------------------

  void _advance() {
    final word = _pickWord();
    _cooldown.updateAll((_, v) => max(0, v - 1));
    _cooldown[word.id] = min(3, _active.length - 1);
    _lastWordId = word.id;
    current = _questionFor(word);
  }

  List<Word> get _active => selected.where((w) => levelOf(w) < masteredLevel).toList();

  Word _pickWord() {
    final active = _active;
    var eligible = active.where((w) => (_cooldown[w.id] ?? 0) <= 0 && w.id != _lastWordId).toList();
    if (eligible.isEmpty) {
      // Poco que elegir: la de menor espera, evitando repetir la última si se puede.
      final others = active.where((w) => w.id != _lastWordId).toList();
      final pool = others.isEmpty ? active : others;
      pool.sort((a, b) => (_cooldown[a.id] ?? 0).compareTo(_cooldown[b.id] ?? 0));
      return pool.first;
    }
    // Más peso a las que más se han fallado.
    final weights = [for (final w in eligible) 1 + 2 * (_misses[w.id] ?? 0)];
    var roll = random.nextInt(weights.fold<int>(0, (a, b) => a + b));
    for (var i = 0; i < eligible.length; i++) {
      roll -= weights[i];
      if (roll < 0) return eligible[i];
    }
    return eligible.last;
  }

  Question _questionFor(Word word) {
    final level = levelOf(word);
    final dir = factory.randomDirection();
    switch (level) {
      case 0:
        return factory.multipleChoice(word, dir) ?? factory.type(word, dir);
      case 1:
        return factory.scramble(word) ??
            factory.multipleChoice(word, dir == Direction.esToEn ? Direction.enToEs : Direction.esToEn) ??
            factory.type(word, dir);
      default:
        return factory.type(word, dir);
    }
  }
}
