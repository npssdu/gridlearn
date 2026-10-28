import 'dart:math';

import '../models/word.dart';
import 'answer_checker.dart';
import 'game_result.dart';
import 'question.dart';
import 'question_factory.dart';

/// "Relámpago": una cuenta atrás, preguntas rápidas (opción múltiple y
/// verdadero/falso) y un multiplicador que sube con la racha. Fallar resta tiempo.
class BlitzSession {
  BlitzSession(
    List<Word> words, {
    Random? random,
    this.duration = const Duration(seconds: 60),
    this.penalty = const Duration(seconds: 5),
  })  : random = random ?? Random(),
        assert(words.length >= 2) {
    factory = QuestionFactory(words, random: this.random);
    remaining = duration;
    _words = words;
    next();
  }

  final Random random;
  final Duration duration;
  final Duration penalty;
  late final QuestionFactory factory;
  late final List<Word> _words;
  final List<Word> _bag = [];
  final Set<String> _missed = {};
  String? _lastWordId;

  late Duration remaining;
  Question? current;
  Verdict? lastVerdict;

  int score = 0;
  int streak = 0;
  int bestStreak = 0;
  int correct = 0;
  int answered = 0;

  bool get finished => remaining <= Duration.zero;

  /// x1 al empezar; sube uno cada 3 aciertos seguidos (máximo x4).
  int get multiplier => min(4, 1 + streak ~/ 3);

  double get timeFraction => remaining.inMilliseconds / duration.inMilliseconds;

  void tick(Duration elapsed) {
    if (finished) return;
    remaining -= elapsed;
    if (remaining < Duration.zero) remaining = Duration.zero;
  }

  Verdict submit(String given) {
    final q = current!;
    final verdict = evaluate(q, given);
    answered++;
    if (verdict.isRight) {
      correct++;
      score += 10 * multiplier;
      streak++;
      bestStreak = max(bestStreak, streak);
    } else {
      streak = 0;
      _missed.add(q.word.id);
      remaining -= penalty;
      if (remaining < Duration.zero) remaining = Duration.zero;
    }
    lastVerdict = verdict;
    return verdict;
  }

  /// Genera la siguiente pregunta.
  void next() {
    lastVerdict = null;
    if (_bag.isEmpty) {
      _bag.addAll([..._words]..shuffle(random));
      // Evita repetir la misma palabra justo al rellenar la bolsa.
      if (_bag.length > 1 && _bag.first.id == _lastWordId) {
        _bag.add(_bag.removeAt(0));
      }
    }
    final word = _bag.removeAt(0);
    _lastWordId = word.id;
    final dir = factory.randomDirection();
    current = (random.nextInt(10) < 6
            ? factory.multipleChoice(word, dir, optionCount: 3)
            : factory.trueFalse(word, dir)) ??
        factory.multipleChoice(word, dir, optionCount: 3) ??
        factory.trueFalse(word, dir) ??
        factory.type(word, dir);
  }

  GameResult result() {
    return GameResult(
      mode: GameMode.blitz,
      score: score,
      stars: answered == 0 ? 0 : (score >= 400 ? 3 : (score >= 200 ? 2 : 1)),
      correct: correct,
      total: answered,
      bestStreak: bestStreak,
      missed: _words.where((w) => _missed.contains(w.id)).toList(),
      duration: duration,
      headline: '¡Tiempo!',
    );
  }
}
