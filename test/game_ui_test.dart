import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridlearn/game/question.dart';
import 'package:gridlearn/models/word.dart';
import 'package:gridlearn/theme/app_theme.dart';
import 'package:gridlearn/widgets/game/game_dialog.dart';
import 'package:gridlearn/widgets/game/game_effects.dart';
import 'package:gridlearn/widgets/game/question_views.dart';

Word w(String en, String es) => Word(id: en, english: en, spanish: es, createdAt: 0);

final vocab = [w('Sun', 'Sol'), w('Egg', 'Huevo'), w('Lamb', 'Cordero')];

Future<void> pumpShell(WidgetTester tester, List<Word> words, {int seed = 1, VoidCallback? onClose}) async {
  tester.view.physicalSize = const Size(700, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.build(useGoogleFonts: false),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 900,
            child: GameShell(words: words, onClose: onClose ?? () {}, random: Random(seed)),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Question currentQuestion(WidgetTester tester) => tester.widget<QuestionView>(find.byType(QuestionView)).question;

/// Responde la pregunta que se ve en pantalla (bien o mal) según su tipo.
Future<void> answer(WidgetTester tester, {required bool right}) async {
  final q = currentQuestion(tester);
  switch (q.kind) {
    case QuestionKind.multipleChoice:
      final text = right ? q.answer : q.options.firstWhere((o) => o != q.answer);
      await tester.tap(find.text(text));
    case QuestionKind.trueFalse:
      final value = right ? q.isTrue : !q.isTrue;
      await tester.tap(find.text(value ? 'Verdadero' : 'Falso'));
    case QuestionKind.scramble:
      final target = right ? q.answer.toUpperCase() : q.answer.toUpperCase().split('').reversed.join();
      final used = <int>{};
      for (final ch in target.split('')) {
        final i = List.generate(q.letters.length, (i) => i).firstWhere((i) => !used.contains(i) && q.letters[i] == ch);
        used.add(i);
        await tester.tap(find.byKey(ValueKey('tray-$i')));
        await tester.pump();
      }
    case QuestionKind.type:
      await tester.enterText(find.byType(TextField), right ? q.answer : 'zzzz');
      await tester.tap(find.text('Comprobar'));
  }
  await tester.pump();
}

Future<void> tapContinue(WidgetTester tester) async {
  final next = find.widgetWithText(FilledButton, 'Continuar');
  final results = find.widgetWithText(FilledButton, 'Ver resultados');
  await tester.tap(next.evaluate().isNotEmpty ? next : results);
  await tester.pumpAndSettle();
}

void main() {
  group('menú', () {
    testWidgets('muestra los 4 juegos y la cantidad de palabras', (tester) async {
      await pumpShell(tester, vocab);
      for (final t in ['Aventura', 'Relámpago', 'Parejas', 'Bingo cantado']) {
        expect(find.text(t), findsOneWidget);
      }
      expect(find.textContaining('3 palabras'), findsOneWidget);
      expect(find.textContaining('Necesita al menos'), findsNothing);
    });

    testWidgets('los juegos que necesitan más palabras se desactivan', (tester) async {
      await pumpShell(tester, [vocab[0], vocab[1]]);
      // Parejas y Bingo piden 3.
      expect(find.text('Necesita al menos 3 palabras.'), findsNWidgets(2));
      await tester.tap(find.text('Parejas'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Salir del juego'), findsNothing);
    });

    testWidgets('sin palabras avisa y no deja jugar', (tester) async {
      await pumpShell(tester, const []);
      expect(find.text('Agrega palabras para iniciar la evaluación.'), findsOneWidget);
      await tester.tap(find.text('Aventura'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Salir del juego'), findsNothing);
    });
  });

  group('Aventura', () {
    testWidgets('responder bien todo lleva a los resultados con 3 estrellas', (tester) async {
      await pumpShell(tester, vocab);
      await tester.tap(find.text('Aventura'));
      await tester.pumpAndSettle();

      var guard = 0;
      final kinds = <QuestionKind>{};
      while (find.text('Jugar de nuevo').evaluate().isEmpty && guard++ < 40) {
        kinds.add(currentQuestion(tester).kind);
        await answer(tester, right: true);
        expect(find.textContaining('Continuar').evaluate().length + find.text('Ver resultados').evaluate().length, 1);
        await tapContinue(tester);
      }
      expect(find.text('Jugar de nuevo'), findsOneWidget);
      expect(kinds, containsAll([QuestionKind.multipleChoice, QuestionKind.type]));
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
      expect(find.byType(Confetti), findsOneWidget);
      expect(find.textContaining('Sin palabras falladas'), findsOneWidget);
      expect(find.text('Repasar falladas'), findsNothing);
    });

    testWidgets('un error muestra la respuesta correcta y no se puede cambiar', (tester) async {
      await pumpShell(tester, vocab, seed: 2);
      await tester.tap(find.text('Aventura'));
      await tester.pumpAndSettle();

      final q = currentQuestion(tester);
      await answer(tester, right: false);
      expect(find.text('La respuesta era: ${q.answer}'), findsOneWidget);
      // Bloqueada: tocar otra opción no cambia nada.
      await tester.tap(find.text(q.answer), warnIfMissed: false);
      await tester.pump();
      expect(find.text('La respuesta era: ${q.answer}'), findsOneWidget);
    });

    testWidgets('las palabras falladas se pueden repasar', (tester) async {
      await pumpShell(tester, vocab, seed: 3);
      await tester.tap(find.text('Aventura'));
      await tester.pumpAndSettle();

      final failed = currentQuestion(tester).word;
      await answer(tester, right: false);
      await tapContinue(tester);

      var guard = 0;
      while (find.text('Jugar de nuevo').evaluate().isEmpty && guard++ < 60) {
        await answer(tester, right: true);
        await tapContinue(tester);
      }
      expect(find.text('Para repasar'), findsOneWidget);
      expect(find.text(failed.english), findsOneWidget);

      await tester.tap(find.text('Repasar falladas'));
      await tester.pumpAndSettle();
      // Una Aventura nueva con solo la palabra fallada.
      expect(currentQuestion(tester).word.id, failed.id);
      expect(find.textContaining('/1'), findsOneWidget);
    });

    testWidgets('salir devuelve al menú', (tester) async {
      await pumpShell(tester, vocab);
      await tester.tap(find.text('Aventura'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Salir del juego'));
      await tester.pumpAndSettle();
      expect(find.text('Elegir otro juego'), findsNothing);
      expect(find.text('Bingo cantado'), findsOneWidget);
    });
  });

  group('tipos de pregunta', () {
    testWidgets('ordenar letras: se arma tocando fichas y también quitando una', (tester) async {
      await pumpShell(tester, vocab);
      await tester.tap(find.text('Aventura'));
      await tester.pumpAndSettle();

      // Sube la primera palabra hasta el nivel de ordenar letras.
      var guard = 0;
      while (currentQuestion(tester).kind != QuestionKind.scramble && guard++ < 20) {
        await answer(tester, right: true);
        await tapContinue(tester);
      }
      final q = currentQuestion(tester);
      expect(q.kind, QuestionKind.scramble);
      expect(find.textContaining('ORDENA LAS LETRAS'), findsOneWidget);

      // Coloca una letra y la quita.
      await tester.tap(find.byKey(const ValueKey('tray-0')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('slot-0')));
      await tester.pump();
      await answer(tester, right: true);
      expect(find.text('Continuar'), findsOneWidget);
    });

    testWidgets('escribir acepta tildes y mayúsculas', (tester) async {
      await pumpShell(tester, [w('Garden', 'Jardín')]);
      await tester.tap(find.text('Aventura'));
      await tester.pumpAndSettle();
      final q = currentQuestion(tester);
      expect(q.kind, QuestionKind.type);
      await tester.enterText(find.byType(TextField), q.answer.toUpperCase().replaceAll('Í', 'I'));
      await tester.tap(find.text('Comprobar'));
      await tester.pump();
      expect(find.text('La respuesta era: ${q.answer}'), findsNothing);
      expect(find.text('Continuar'), findsOneWidget);
    });
  });

  group('Relámpago', () {
    testWidgets('suma puntos con combo, avanza solo y termina con "¡Tiempo!"', (tester) async {
      await pumpShell(tester, vocab);
      await tester.tap(find.text('Relámpago'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Combo x1'), findsOneWidget);
      expect(find.text('60s'), findsOneWidget);

      for (var i = 0; i < 3; i++) {
        await answer(tester, right: true);
        await tester.pump(const Duration(milliseconds: 700)); // pasa a la siguiente sola
      }
      expect(find.text('Combo x2'), findsOneWidget);

      // Un error resta 5 segundos.
      await answer(tester, right: false);
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('Combo x1'), findsOneWidget);

      await tester.pump(const Duration(seconds: 70));
      await tester.pumpAndSettle();
      expect(find.text('¡Tiempo!'), findsOneWidget);
      expect(find.text('Jugar de nuevo'), findsOneWidget);
    });
  });

  group('Parejas', () {
    testWidgets('emparejar todo termina el juego; fallar cuenta un error', (tester) async {
      await pumpShell(tester, vocab);
      await tester.tap(find.text('Parejas'));
      await tester.pumpAndSettle();

      // Error: Sun con Huevo.
      await tester.tap(find.text('Sun'));
      await tester.tap(find.text('Huevo'));
      await tester.pump();
      expect(find.text('1 error'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 800));

      for (final p in vocab) {
        await tester.tap(find.text(p.english));
        await tester.tap(find.text(p.spanish));
        await tester.pump();
      }
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Jugar de nuevo'), findsOneWidget);
      expect(find.text('¡Increíble!'), findsOneWidget, reason: '1 error = 3 estrellas');
      expect(find.text('275 puntos'), findsOneWidget); // 3*100 - 25
      expect(find.text('Para repasar'), findsOneWidget);
    });
  });

  group('Bingo cantado', () {
    String called() => vocab.firstWhere((p) => find.text(p.spanish).evaluate().isNotEmpty).spanish;
    Word calledWord() => vocab.firstWhere((p) => p.spanish == called());

    testWidgets('acertar todo canta BINGO y pasa a los resultados', (tester) async {
      await pumpShell(tester, vocab);
      await tester.tap(find.text('Bingo cantado'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(3));

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text(calledWord().english));
        await tester.pump();
      }
      expect(find.text('¡BINGO!'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Jugar de nuevo'), findsOneWidget);
      expect(find.text('¡BINGO!'), findsOneWidget); // titular de resultados
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
    });

    testWidgets('fallar quita vidas y con 3 errores se pierde', (tester) async {
      await pumpShell(tester, vocab);
      await tester.tap(find.text('Bingo cantado'));
      await tester.pumpAndSettle();

      for (var lives = 2; lives >= 0; lives--) {
        final target = calledWord();
        final wrong = vocab.firstWhere((p) => p.english != target.english);
        await tester.tap(find.text(wrong.english));
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(lives));
      }
      expect(find.text('¡Sin vidas!'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Jugar de nuevo'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsNothing);
      expect(find.byType(Confetti), findsNothing);
    });
  });

  testWidgets('"Jugar de nuevo" empieza otra partida y "Elegir otro juego" vuelve al menú', (tester) async {
    await pumpShell(tester, vocab);
    await tester.tap(find.text('Parejas'));
    await tester.pumpAndSettle();
    for (final p in vocab) {
      await tester.tap(find.text(p.english));
      await tester.tap(find.text(p.spanish));
      await tester.pump();
    }
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jugar de nuevo'));
    await tester.pumpAndSettle();
    expect(find.text('Une cada palabra con su traducción'), findsOneWidget);
    expect(find.text('Jugar de nuevo'), findsNothing);

    await tester.tap(find.byTooltip('Salir del juego'));
    await tester.pumpAndSettle();
    expect(find.text('Aventura'), findsOneWidget);
  });
}
