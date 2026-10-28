import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridlearn/app.dart';
import 'package:gridlearn/screens/home_screen.dart';
import 'package:gridlearn/screens/saved_vocabularies_screen.dart';
import 'package:gridlearn/services/auth/local_auth_service.dart';
import 'package:gridlearn/services/local_vocabulary_repository.dart';
import 'package:gridlearn/state/vocab_controller.dart';
import 'package:gridlearn/theme/row_colors.dart';
import 'package:gridlearn/widgets/bingo_grid.dart';
import 'package:gridlearn/widgets/export_menu.dart';
import 'package:gridlearn/widgets/game/game_dialog.dart';
import 'package:gridlearn/widgets/word_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abre la app en modo local con el tamaño de pantalla indicado.
Future<VocabController> _pump(WidgetTester tester, Size size) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GridLearnApp(
      auth: LocalAuthService(),
      prefs: prefs,
      repositoryFor: (user) => LocalVocabularyRepository(prefs, scope: user.id),
      useGoogleFonts: false,
    ),
  );
  await tester.pumpAndSettle();
  return tester.widget<HomeScreen>(find.byType(HomeScreen)).controller;
}

void main() {
  const sizes = {
    'móvil': Size(390, 844),
    'tablet': Size(820, 1180),
    'web': Size(1440, 900),
  };

  for (final entry in sizes.entries) {
    testWidgets('${entry.key}: muestra la grilla y agrega una palabra', (tester) async {
      final controller = await _pump(tester, entry.value);

      expect(find.text('Bingo de Vocabulario'), findsOneWidget);
      expect(find.byType(BingoGrid), findsOneWidget);
      expect(find.text('Aún no agregaste palabras.'), findsOneWidget);
      expect(find.text('Modo local'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Palabra en inglés'), 'Sun');
      await tester.enterText(find.widgetWithText(TextFormField, 'Traducción al español'), 'Sol');
      await tester.tap(find.text('Agregar'));
      await tester.pumpAndSettle();

      expect(controller.words, hasLength(1));
      expect(find.byType(WordList), findsOneWidget);
      expect(find.text('SUN'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('validación: no agrega sin traducción', (tester) async {
    final controller = await _pump(tester, sizes['móvil']!);
    await tester.enterText(find.widgetWithText(TextFormField, 'Palabra en inglés'), 'Sun');
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();
    expect(controller.words, isEmpty);
    expect(find.text('Obligatorio'), findsOneWidget);
  });

  testWidgets('editar y eliminar palabras', (tester) async {
    final controller = await _pump(tester, sizes['web']!);
    controller.addWord(english: 'Egg', spanish: 'Huevo');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Editar palabra'));
    await tester.pumpAndSettle();
    expect(find.text('Actualizar'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Palabra en inglés'), 'Eggs');
    await tester.tap(find.text('Actualizar'));
    await tester.pumpAndSettle();
    expect(controller.words.single.english, 'Eggs');
    expect(find.text('Agregar'), findsOneWidget);

    await tester.tap(find.byTooltip('Eliminar palabra'));
    await tester.pumpAndSettle();
    expect(controller.words, isEmpty);
  });

  testWidgets('una palabra nueva ocupa solo la primera casilla libre', (tester) async {
    final controller = await _pump(tester, sizes['web']!);

    controller.addWord(english: 'Sun', spanish: 'Sol');
    await tester.pumpAndSettle();
    expect(controller.grid.where((s) => !s.isPlaceholder), hasLength(1));
    expect(controller.grid[0].english, 'Sun');
    expect(find.text('SUN'), findsOneWidget);

    controller.addWord(english: 'Egg', spanish: 'Huevo');
    await tester.pumpAndSettle();
    expect(controller.grid.where((s) => !s.isPlaceholder), hasLength(2));
    expect(controller.grid[0].english, 'Sun');
    expect(controller.grid[1].english, 'Egg');
    expect(find.text('EGG'), findsOneWidget);
  });

  testWidgets('cada fila de la grilla tiene un color distinto', (tester) async {
    await _pump(tester, sizes['web']!);
    expect(rowPalette, hasLength(6));
    expect(rowPalette.map((c) => c.tint).toSet(), hasLength(6));
    expect(rowPalette.map((c) => c.strong).toSet(), hasLength(6));
  });

  testWidgets('el botón de exportar se habilita solo con palabras', (tester) async {
    final controller = await _pump(tester, sizes['tablet']!);
    expect(tester.widget<ExportMenu>(find.byType(ExportMenu)).enabled, isFalse);

    controller.addWord(english: 'Sun', spanish: 'Sol');
    await tester.pumpAndSettle();
    expect(tester.widget<ExportMenu>(find.byType(ExportMenu)).enabled, isTrue);

    await tester.tap(find.byType(ExportMenu));
    await tester.pumpAndSettle();
    expect(find.text('Imprimir'), findsOneWidget);
    expect(find.text('Guardar como PDF'), findsOneWidget);
  });

  group('título del vocabulario', () {
    for (final entry in sizes.entries) {
      testWidgets('${entry.key}: es opcional y aparece en la grilla exportable', (tester) async {
        final controller = await _pump(tester, entry.value);
        final inGrid = find.descendant(of: find.byType(BingoGrid), matching: find.text('Pascua 2026'));

        // Sin título no se muestra nada extra en la grilla.
        expect(inGrid, findsNothing);
        controller.addWord(english: 'Egg', spanish: 'Huevo');
        await tester.pumpAndSettle();
        expect(inGrid, findsNothing);

        await tester.enterText(
          find.widgetWithText(TextField, 'Título del vocabulario (opcional)'),
          'Pascua 2026',
        );
        await tester.pumpAndSettle();
        expect(controller.title, 'Pascua 2026');
        expect(inGrid, findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('guardar y repasar vocabularios', () {
    testWidgets('guarda, aparece en Mis vocabularios y se puede abrir', (tester) async {
      final controller = await _pump(tester, sizes['tablet']!);

      await tester.enterText(
        find.widgetWithText(TextField, 'Título del vocabulario (opcional)'),
        'Pascua',
      );
      controller.addWord(english: 'Egg', spanish: 'Huevo');
      await tester.pumpAndSettle();
      expect(find.text('Sin guardar'), findsOneWidget);

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(find.text('Vocabulario guardado.'), findsOneWidget);
      expect(find.text('Guardado'), findsOneWidget);
      expect(controller.isSaved, isTrue);

      // Empezar otro y volver a abrir el guardado.
      await tester.tap(find.text('Nuevo'));
      await tester.pumpAndSettle();
      expect(controller.words, isEmpty);

      await tester.tap(find.text('Mis vocabularios'));
      await tester.pumpAndSettle();
      expect(find.byType(SavedVocabulariesScreen), findsOneWidget);
      expect(find.text('Pascua'), findsOneWidget);
      expect(find.textContaining('1 palabra'), findsOneWidget);

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(find.byType(SavedVocabulariesScreen), findsNothing);
      expect(controller.title, 'Pascua');
      expect(controller.words.single.english, 'Egg');
    });

    testWidgets('no permite guardar un vocabulario vacío', (tester) async {
      await _pump(tester, sizes['móvil']!);
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(find.text('Agrega al menos una palabra antes de guardar.'), findsOneWidget);
    });

    testWidgets('pide confirmación antes de descartar cambios sin guardar', (tester) async {
      final controller = await _pump(tester, sizes['tablet']!);
      controller.addWord(english: 'Egg', spanish: 'Huevo');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nuevo'));
      await tester.pumpAndSettle();
      expect(find.text('Cambios sin guardar'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(controller.words, hasLength(1));

      await tester.tap(find.text('Nuevo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Descartar cambios'));
      await tester.pumpAndSettle();
      expect(controller.words, isEmpty);
    });

    testWidgets('"Evaluar" abre el vocabulario y arranca la evaluación', (tester) async {
      final controller = await _pump(tester, sizes['tablet']!);
      controller.addWord(english: 'Sun', spanish: 'Sol');
      await controller.save();
      controller.startNew();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mis vocabularios'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Evaluar'));
      await tester.pumpAndSettle();

      expect(controller.words.single.english, 'Sun');
      expect(find.text('Modo Evaluación'), findsOneWidget);
    });

    testWidgets('elimina un vocabulario guardado tras confirmar', (tester) async {
      final controller = await _pump(tester, sizes['tablet']!);
      controller.addWord(english: 'Sun', spanish: 'Sol');
      await controller.save();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mis vocabularios'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Eliminar vocabulario'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Aún no guardaste ningún vocabulario'), findsOneWidget);
      expect(controller.words, isEmpty);
    });
  });

  group('modo evaluación', () {
    testWidgets('se abre, muestra los juegos y se cierra en móvil y en web', (tester) async {
      for (final size in [sizes['móvil']!, sizes['web']!]) {
        final controller = await _pump(tester, size);
        controller.addWord(english: 'Sun', spanish: 'Sol');
        controller.addWord(english: 'Egg', spanish: 'Huevo');
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.emoji_events_outlined));
        await tester.pumpAndSettle();
        expect(find.text('Modo Evaluación'), findsOneWidget);
        for (final game in ['Aventura', 'Relámpago', 'Parejas', 'Bingo cantado']) {
          expect(find.text(game), findsOneWidget, reason: game);
        }

        await tester.tap(find.text('Aventura'));
        await tester.pumpAndSettle();
        expect(find.byTooltip('Salir del juego'), findsOneWidget);
        expect(find.textContaining('ELIGE LA TRADUCCIÓN'), findsOneWidget);

        // Salir al menú y cerrar.
        await tester.tap(find.byTooltip('Salir del juego'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cerrar'));
        await tester.pumpAndSettle();
        expect(find.text('Modo Evaluación'), findsNothing);
      }
    });

    for (final entry in sizes.entries) {
      testWidgets('${entry.key}: desenfoca y oscurece lo que hay detrás', (tester) async {
        final controller = await _pump(tester, entry.value);
        controller.addWord(english: 'Sun', spanish: 'Sol');
        await tester.pumpAndSettle();
        expect(find.byType(QuizBackdrop), findsNothing);

        await tester.tap(find.byIcon(Icons.emoji_events_outlined));
        await tester.pumpAndSettle();

        // Desenfoque fuerte que cubre toda la pantalla...
        final backdrop = tester.widget<BackdropFilter>(
          find.descendant(of: find.byType(QuizBackdrop), matching: find.byType(BackdropFilter)),
        );
        expect(backdrop.filter.toString(), contains('blur'));
        expect(tester.getSize(find.byType(QuizBackdrop)), tester.view.physicalSize);

        // ...con una capa oscura encima para que las palabras no se lean.
        final tint = tester.widget<ColoredBox>(
          find.descendant(of: find.byType(QuizBackdrop), matching: find.byType(ColoredBox)),
        );
        expect(tint.color.a, greaterThan(0.4));

        await tester.tap(find.text('Cerrar'));
        await tester.pumpAndSettle();
        expect(find.byType(QuizBackdrop), findsNothing);
      });
    }

    testWidgets('la tecla Escape cierra la evaluación', (tester) async {
      final controller = await _pump(tester, sizes['web']!);
      controller.addWord(english: 'Sun', spanish: 'Sol');
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.emoji_events_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(QuizBackdrop), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(QuizBackdrop), findsNothing);
    });
  });
}
