import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gridlearn/game/adventure_session.dart';
import 'package:gridlearn/game/answer_checker.dart';
import 'package:gridlearn/game/bingo_session.dart';
import 'package:gridlearn/game/blitz_session.dart';
import 'package:gridlearn/game/game_result.dart';
import 'package:gridlearn/game/match_round.dart';
import 'package:gridlearn/game/question.dart';
import 'package:gridlearn/game/question_factory.dart';
import 'package:gridlearn/models/word.dart';

Word w(String en, String es, [String id = '']) =>
    Word(id: id.isEmpty ? en : id, english: en, spanish: es, createdAt: 0);

final vocab = [
  w('Sun', 'Sol'),
  w('Egg', 'Huevo'),
  w('Lamb', 'Cordero'),
  w('Bunny', 'Conejito'),
  w('Garden', 'Jardín'),
  w('Jelly Beans', 'Gomitas'),
  w('Rainbow', 'Arcoíris'),
];

/// Responde bien cualquier tipo de pregunta.
String correctAnswer(Question q) {
  switch (q.kind) {
    case QuestionKind.trueFalse:
      return Question.trueFalseValue(q.isTrue);
    default:
      return q.answer;
  }
}

/// Responde mal cualquier tipo de pregunta.
String wrongAnswer(Question q) {
  switch (q.kind) {
    case QuestionKind.trueFalse:
      return Question.trueFalseValue(!q.isTrue);
    case QuestionKind.multipleChoice:
      return q.options.firstWhere((o) => o != q.answer);
    default:
      return 'zzzz';
  }
}

void main() {
  group('checkTyped', () {
    test('ignora mayúsculas y tildes', () {
      expect(checkTyped('JARDIN', 'Jardín'), Verdict.correct);
    });
    test('un error de una letra en palabras largas es "casi"', () {
      expect(checkTyped('Rainbov', 'Rainbow'), Verdict.almost);
      expect(checkTyped('Sul', 'Sol'), Verdict.wrong, reason: 'en palabras cortas no se perdona');
    });
    test('vacío o distinto es incorrecto', () {
      expect(checkTyped('', 'Sol'), Verdict.wrong);
      expect(checkTyped('Luna', 'Sol'), Verdict.wrong);
    });
    test('levenshtein', () {
      expect(levenshtein('kitten', 'sitting'), 3);
      expect(levenshtein('', 'abc'), 3);
    });
  });

  group('QuestionFactory', () {
    final f = QuestionFactory(vocab, random: Random(1));

    test('opción múltiple: 4 opciones únicas que incluyen la correcta', () {
      for (final word in vocab) {
        for (final d in Direction.values) {
          final q = f.multipleChoice(word, d)!;
          expect(q.options, hasLength(4));
          expect(q.options.toSet(), hasLength(4));
          expect(q.options, contains(q.answer));
          expect(q.answer, answerOf(word, d));
          expect(q.prompt, promptOf(word, d));
        }
      }
    });

    test('con 2 palabras hay 2 opciones; con 1 no se puede', () {
      final two = QuestionFactory([vocab[0], vocab[1]], random: Random(2));
      expect(two.multipleChoice(vocab[0], Direction.esToEn)!.options, hasLength(2));
      final one = QuestionFactory([vocab[0]], random: Random(2));
      expect(one.multipleChoice(vocab[0], Direction.esToEn), isNull);
      expect(one.trueFalse(vocab[0], Direction.esToEn), isNull);
    });

    test('ordenar letras: mismas letras, en otro orden', () {
      for (var i = 0; i < 30; i++) {
        final q = f.scramble(vocab[3])!; // Bunny
        expect([...q.letters]..sort(), [...'BUNNY'.split('')]..sort());
        expect(q.letters.join(), isNot('BUNNY'));
      }
    });

    test('no se ordenan palabras con espacios', () {
      expect(f.canScramble(vocab[5]), isFalse); // Jelly Beans
      expect(f.scramble(vocab[5]), isNull);
    });

    test('verdadero/falso: lo propuesto es consistente con isTrue', () {
      var trues = 0, falses = 0;
      for (var i = 0; i < 200; i++) {
        final q = f.trueFalse(vocab[i % vocab.length], Direction.enToEs)!;
        expect(q.isTrue, q.shownAnswer == q.answer);
        q.isTrue ? trues++ : falses++;
      }
      expect(trues, greaterThan(50));
      expect(falses, greaterThan(50));
    });

    test('evaluate responde según el tipo', () {
      final tf = f.trueFalse(vocab[0], Direction.esToEn)!;
      expect(evaluate(tf, correctAnswer(tf)), Verdict.correct);
      expect(evaluate(tf, wrongAnswer(tf)), Verdict.wrong);
      final mc = f.multipleChoice(vocab[0], Direction.esToEn)!;
      expect(evaluate(mc, mc.answer), Verdict.correct);
      expect(evaluate(mc, wrongAnswer(mc)), Verdict.wrong);
    });
  });

  group('AdventureSession', () {
    test('responder siempre bien domina todas las palabras', () {
      final s = AdventureSession(vocab, random: Random(3));
      expect(s.totalWords, 7);
      var guard = 0;
      while (!s.finished && guard++ < 200) {
        s.submit(correctAnswer(s.current!));
        s.next();
      }
      expect(s.finished, isTrue);
      expect(s.masteredCount, s.totalWords);
      // 3 niveles por palabra
      expect(s.answered, s.totalWords * 3);
      expect(s.accuracy, 1);
      expect(s.result().stars, 3);
      expect(s.missedWords, isEmpty);
    });

    test('cada palabra pasa por reconocer → armar/elegir → escribir', () {
      final s = AdventureSession(vocab, random: Random(4));
      final kindsByWord = <String, List<QuestionKind>>{};
      while (!s.finished) {
        kindsByWord.putIfAbsent(s.current!.word.id, () => []).add(s.current!.kind);
        s.submit(correctAnswer(s.current!));
        s.next();
      }
      for (final kinds in kindsByWord.values) {
        expect(kinds.first, QuestionKind.multipleChoice);
        expect(kinds.last, QuestionKind.type);
        expect(kinds, hasLength(3));
      }
    });

    test('una palabra fallada baja de nivel, vuelve más tarde y no de inmediato', () {
      final s = AdventureSession(vocab, random: Random(5));
      final target = s.current!.word;
      s.submit(wrongAnswer(s.current!));
      expect(s.lastVerdict, Verdict.wrong);
      expect(s.streak, 0);
      expect(s.lastFeedback, startsWith('La respuesta era'));
      s.next();
      expect(s.current!.word.id, isNot(target.id), reason: 'no se repite de inmediato');
      expect(s.missedWords.map((x) => x.id), [target.id]);
    });

    test('las falladas reaparecen y la partida termina igualmente', () {
      final s = AdventureSession(vocab, random: Random(6));
      var turn = 0;
      while (!s.finished && turn < 500) {
        // Falla las 3 primeras respuestas y luego acierta.
        final q = s.current!;
        s.submit(turn < 3 ? wrongAnswer(q) : correctAnswer(q));
        s.next();
        turn++;
      }
      expect(s.finished, isTrue);
      expect(s.masteredCount, s.totalWords);
      expect(s.answered, greaterThan(s.totalWords * 3), reason: 'hubo repeticiones');
      expect(s.missedWords, hasLength(3));
    });

    test('puntos: 100 + bonus por racha', () {
      final s = AdventureSession(vocab, random: Random(7));
      s.submit(correctAnswer(s.current!));
      expect(s.score, 100);
      s.next();
      s.submit(correctAnswer(s.current!));
      expect(s.score, 100 + 120);
      expect(s.streak, 2);
      expect(s.bestStreak, 2);
    });

    test('con una sola palabra sigue funcionando (sin opciones)', () {
      final s = AdventureSession([vocab[0]], random: Random(8));
      var guard = 0;
      while (!s.finished && guard++ < 50) {
        expect(s.current!.kind, isNot(QuestionKind.multipleChoice));
        s.submit(correctAnswer(s.current!));
        s.next();
      }
      expect(s.finished, isTrue);
    });

    test('elige como máximo maxWords palabras al azar', () {
      final many = [for (var i = 0; i < 30; i++) w('word$i', 'palabra$i')];
      final a = AdventureSession(many, random: Random(1));
      final b = AdventureSession(many, random: Random(2));
      expect(a.totalWords, 8);
      expect(a.selected.map((x) => x.id).toList(), isNot(b.selected.map((x) => x.id).toList()));
    });

    test('una respuesta "casi" cuenta como acierto con menos puntos', () {
      final s = AdventureSession([w('Rainbow', 'Arcoíris')], random: Random(9));
      // Un solo término: solo se pregunta escribiendo.
      final q = s.current!;
      expect(q.kind, QuestionKind.type);
      final typo = q.answer.length > 1 ? '${q.answer.substring(0, q.answer.length - 1)}x' : 'x';
      s.submit(typo);
      expect(s.lastVerdict, Verdict.almost);
      expect(s.score, 70);
      expect(s.correct, 1);
    });
  });

  group('BlitzSession', () {
    test('multiplicador sube cada 3 aciertos y se reinicia al fallar', () {
      final s = BlitzSession(vocab, random: Random(1));
      expect(s.multiplier, 1);
      for (var i = 0; i < 3; i++) {
        s.submit(correctAnswer(s.current!));
        s.next();
      }
      expect(s.multiplier, 2);
      s.submit(wrongAnswer(s.current!));
      expect(s.multiplier, 1);
      expect(s.streak, 0);
    });

    test('fallar resta tiempo y la cuenta atrás termina la partida', () {
      final s = BlitzSession(vocab, random: Random(2), duration: const Duration(seconds: 20));
      s.submit(wrongAnswer(s.current!));
      expect(s.remaining, const Duration(seconds: 15));
      s.tick(const Duration(seconds: 14));
      expect(s.finished, isFalse);
      s.tick(const Duration(seconds: 5));
      expect(s.finished, isTrue);
      expect(s.remaining, Duration.zero);
      expect(s.result().headline, '¡Tiempo!');
    });

    test('no repite la misma palabra seguida y recorre todo el vocabulario', () {
      final s = BlitzSession(vocab, random: Random(3));
      final seen = <String>[];
      for (var i = 0; i < vocab.length * 3; i++) {
        seen.add(s.current!.word.id);
        s.next();
      }
      for (var i = 1; i < seen.length; i++) {
        expect(seen[i], isNot(seen[i - 1]));
      }
      for (var round = 0; round < 3; round++) {
        expect(seen.skip(round * vocab.length).take(vocab.length).toSet(), hasLength(vocab.length));
      }
    });

    test('las preguntas son de opción múltiple o verdadero/falso', () {
      final s = BlitzSession(vocab, random: Random(4));
      final kinds = <QuestionKind>{};
      for (var i = 0; i < 100; i++) {
        kinds.add(s.current!.kind);
        s.next();
      }
      expect(kinds, {QuestionKind.multipleChoice, QuestionKind.trueFalse});
    });
  });

  group('MatchRound', () {
    test('elige hasta 6 parejas y las columnas contienen las mismas palabras', () {
      final r = MatchRound(vocab, random: Random(1));
      expect(r.pairs, hasLength(6));
      expect(r.left.map((x) => x.id).toSet(), r.right.map((x) => x.id).toSet());
    });

    test('acertar empareja; fallar suma un error y no empareja', () {
      final r = MatchRound(vocab, random: Random(2));
      final a = r.pairs[0], b = r.pairs[1];
      expect(r.selectLeft(a.id), MatchOutcome.none);
      expect(r.selectRight(b.id), MatchOutcome.mismatch);
      expect(r.mistakes, 1);
      expect(r.matched, isEmpty);
      r.clearSelection();
      r.selectLeft(a.id);
      expect(r.selectRight(a.id), MatchOutcome.match);
      expect(r.matched, {a.id});
    });

    test('termina al emparejar todas y puntúa por errores', () {
      final r = MatchRound(vocab, random: Random(3));
      for (final p in r.pairs) {
        r.selectLeft(p.id);
        r.selectRight(p.id);
      }
      expect(r.finished, isTrue);
      final res = r.result();
      expect(res.stars, 3);
      expect(res.score, 600);
      expect(res.missed, isEmpty);
    });

    test('ignora traducciones repetidas', () {
      final r = MatchRound([w('Hi', 'Hola', 'a'), w('Hello', 'Hola', 'b'), w('Sun', 'Sol'), w('Egg', 'Huevo')],
          random: Random(4));
      expect(r.pairs.map((p) => p.spanish).toSet(), hasLength(r.pairs.length));
    });
  });

  group('BingoSession', () {
    List<Word> many(int n) => [for (var i = 0; i < n; i++) w('word$i', 'palabra$i')];

    test('el cartón es la grilla y se cantan solo casillas con palabra', () {
      final s = BingoSession(many(8), random: Random(1));
      expect(s.occupiedCount, 8);
      expect(s.calls.every((i) => !s.board[i].isPlaceholder), isTrue);
    });

    test('acertar marca; fallar quita una vida; sin vidas se pierde', () {
      final s = BingoSession(many(8), random: Random(2));
      final call = s.currentCall!;
      final other = s.calls.firstWhere((i) => i != call.index);
      expect(s.tap(other), TapOutcome.wrong);
      expect(s.lives, 2);
      expect(s.tap(call.index), TapOutcome.correct);
      expect(s.marked, {call.index});
      s.tap(s.board.indexWhere((x) => x.isPlaceholder)); // vacía: se ignora
      while (!s.finished) {
        final c = s.currentCall!;
        s.tap(s.calls.firstWhere((i) => i != c.index && !s.marked.contains(i)));
      }
      expect(s.lost, isTrue);
      expect(s.result().won, isFalse);
      expect(s.result().stars, 0);
    });

    test('completar la primera fila (5 palabras) da BINGO', () {
      final s = BingoSession(many(5), random: Random(3));
      while (!s.finished) {
        s.tap(s.currentCall!.index);
      }
      expect(s.bingo, isTrue);
      final res = s.result();
      expect(res.headline, '¡BINGO!');
      expect(res.stars, 3);
      expect(s.winningCells, {0, 1, 2, 3, 4});
    });

    test('con 12 palabras gana al cerrar una fila aunque queden casillas', () {
      final s = BingoSession(many(12), random: Random(4));
      // Marca primero la fila 0 en el orden en que se cante.
      var guard = 0;
      while (!s.finished && guard++ < 50) {
        s.tap(s.currentCall!.index);
      }
      expect(s.bingo, isTrue);
      expect(s.correct, lessThanOrEqualTo(12));
    });

    test('una columna completa también es bingo', () {
      final s = BingoSession(many(30), random: Random(5));
      // Fuerza el orden de cantos: columna 0 (0,5,10,15,20,25).
      s.calls
        ..clear()
        ..addAll([0, 5, 10, 15, 20, 25, 1]);
      for (final i in [0, 5, 10, 15, 20, 25]) {
        s.tap(i);
      }
      expect(s.bingo, isTrue);
      expect(s.winningCells, {0, 5, 10, 15, 20, 25});
    });
  });

  test('starsForAccuracy', () {
    expect(starsForAccuracy(1), 3);
    expect(starsForAccuracy(0.7), 2);
    expect(starsForAccuracy(0.2), 1);
  });
}
