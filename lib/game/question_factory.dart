import 'dart:math';

import '../logic/text_normalizer.dart';
import '../models/word.dart';
import 'question.dart';

/// Fabrica preguntas al azar sobre las palabras de un vocabulario.
class QuestionFactory {
  QuestionFactory(this.words, {Random? random}) : random = random ?? Random();

  final List<Word> words;
  final Random random;

  Direction randomDirection() => random.nextBool() ? Direction.esToEn : Direction.enToEs;

  /// Opción múltiple con hasta [optionCount] opciones. Los distractores salen de
  /// otras palabras del vocabulario (sin repetir textos). `null` si no hay otra
  /// palabra distinta con la que armar opciones.
  Question? multipleChoice(Word word, Direction direction, {int optionCount = 4}) {
    final answer = answerOf(word, direction);
    final seen = {normalizeText(answer)};
    final distractors = <String>[];
    for (final other in [...words]..shuffle(random)) {
      if (other.id == word.id) continue;
      final text = answerOf(other, direction);
      final key = normalizeText(text);
      if (key.isEmpty || !seen.add(key)) continue;
      distractors.add(text);
      if (distractors.length == optionCount - 1) break;
    }
    if (distractors.isEmpty) return null;
    return Question(
      kind: QuestionKind.multipleChoice,
      word: word,
      direction: direction,
      prompt: promptOf(word, direction),
      answer: answer,
      options: [answer, ...distractors]..shuffle(random),
    );
  }

  /// Se puede ordenar si la palabra en inglés es de una sola palabra, solo
  /// letras (3 a 12) y con al menos dos letras distintas.
  bool canScramble(Word word) {
    final english = word.english.trim();
    return RegExp(r'^[A-Za-z]{3,12}$').hasMatch(english) && english.toLowerCase().split('').toSet().length >= 2;
  }

  /// Ordenar las letras de la palabra en inglés a partir de su significado.
  Question? scramble(Word word) {
    if (!canScramble(word)) return null;
    final answer = word.english.trim();
    final original = answer.toUpperCase().split('');
    var letters = [...original];
    for (var tries = 0; tries < 30; tries++) {
      letters = [...original]..shuffle(random);
      if (letters.join() != original.join()) break;
    }
    return Question(
      kind: QuestionKind.scramble,
      word: word,
      direction: Direction.esToEn,
      prompt: word.spanish,
      answer: answer,
      letters: letters,
    );
  }

  Question type(Word word, Direction direction) => Question(
        kind: QuestionKind.type,
        word: word,
        direction: direction,
        prompt: promptOf(word, direction),
        answer: answerOf(word, direction),
      );

  /// Verdadero o falso: la mitad de las veces propone la traducción correcta y
  /// la otra mitad la de otra palabra. `null` si no hay otra palabra distinta.
  Question? trueFalse(Word word, Direction direction) {
    final answer = answerOf(word, direction);
    final others = words
        .where((w) => w.id != word.id && normalizeText(answerOf(w, direction)) != normalizeText(answer))
        .toList();
    if (others.isEmpty) return null;
    final showTrue = random.nextBool();
    final shown = showTrue ? answer : answerOf(others[random.nextInt(others.length)], direction);
    return Question(
      kind: QuestionKind.trueFalse,
      word: word,
      direction: direction,
      prompt: promptOf(word, direction),
      answer: answer,
      shownAnswer: shown,
      isTrue: showTrue,
    );
  }
}
