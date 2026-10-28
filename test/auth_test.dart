import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridlearn/app.dart';
import 'package:gridlearn/screens/auth_screen.dart';
import 'package:gridlearn/screens/home_screen.dart';
import 'package:gridlearn/screens/password_recovery_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

class _Harness {
  _Harness(this.auth, this.prefs, this.repositories);

  final FakeAuthService auth;
  final SharedPreferences prefs;
  final Map<String, InMemoryVocabularyRepository> repositories;
}

Future<_Harness> _pump(WidgetTester tester, {bool confirmationRequired = false}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final auth = FakeAuthService(confirmationRequired: confirmationRequired);
  final repositories = <String, InMemoryVocabularyRepository>{};
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GridLearnApp(
      auth: auth,
      prefs: prefs,
      repositoryFor: (user) => repositories.putIfAbsent(user.id, InMemoryVocabularyRepository.new),
      useGoogleFonts: false,
    ),
  );
  await tester.pumpAndSettle();
  return _Harness(auth, prefs, repositories);
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

Future<void> _register(
  WidgetTester tester, {
  String email = 'ana@correo.com',
  String password = 'clave-segura-2026',
  String? confirm,
}) async {
  await tester.tap(find.text('Crear cuenta'));
  await tester.pumpAndSettle();
  await tester.enterText(_field('Correo electrónico'), email);
  await tester.enterText(_field('Contraseña'), password);
  await tester.enterText(_field('Repite la contraseña'), confirm ?? password);
  await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sin sesión se muestra el inicio de sesión, no la app', (tester) async {
    await _pump(tester);
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('valida correo y contraseña antes de enviar', (tester) async {
    final h = await _pump(tester);
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Ingresa tu correo'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);

    await tester.enterText(_field('Correo electrónico'), 'no-es-correo');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Correo no válido'), findsOneWidget);
    expect(h.auth.state.user, isNull);
  });

  testWidgets('credenciales incorrectas muestran un error genérico', (tester) async {
    final h = await _pump(tester);
    h.auth.accounts['ana@correo.com'] = 'clave-segura-2026';
    h.auth.ids['ana@correo.com'] = 'user-1';

    await tester.enterText(_field('Correo electrónico'), 'ana@correo.com');
    await tester.enterText(_field('Contraseña'), 'otra-clave-1');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('inicia sesión con credenciales correctas y muestra el correo', (tester) async {
    final h = await _pump(tester);
    h.auth.accounts['ana@correo.com'] = 'clave-segura-2026';
    h.auth.ids['ana@correo.com'] = 'user-1';

    await tester.enterText(_field('Correo electrónico'), 'ana@correo.com');
    await tester.enterText(_field('Contraseña'), 'clave-segura-2026');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('ana@correo.com'), findsOneWidget);
    expect(find.text('Modo local'), findsNothing);
  });

  group('registro', () {
    testWidgets('rechaza contraseñas débiles o que no coinciden', (tester) async {
      final h = await _pump(tester);
      await _register(tester, password: 'corta1');
      expect(find.text('Usa al menos 8 caracteres'), findsOneWidget);

      await tester.enterText(_field('Contraseña'), 'clave-segura-2026');
      await tester.enterText(_field('Repite la contraseña'), 'distinta-2026');
      await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
      await tester.pumpAndSettle();
      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
      expect(h.auth.accounts, isEmpty);
    });

    testWidgets('crea la cuenta y entra a la app', (tester) async {
      await _pump(tester);
      await _register(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('si hace falta confirmar el correo, avisa sin revelar si ya existía', (tester) async {
      final h = await _pump(tester, confirmationRequired: true);
      await _register(tester);

      expect(find.byType(HomeScreen), findsNothing);
      expect(find.textContaining('te enviamos un enlace para confirmar'), findsOneWidget);
      expect(h.auth.accounts, contains('ana@correo.com'));
      // Vuelve al modo de inicio de sesión.
      expect(find.text('Entrar'), findsOneWidget);
    });
  });

  group('recuperación de contraseña', () {
    testWidgets('pide el correo y envía el enlace', (tester) async {
      final h = await _pump(tester);

      await tester.tap(find.text('¿Olvidaste tu contraseña?'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Escribe tu correo'), findsOneWidget);
      expect(h.auth.resets, isEmpty);

      await tester.enterText(_field('Correo electrónico'), 'ana@correo.com');
      await tester.tap(find.text('¿Olvidaste tu contraseña?'));
      await tester.pumpAndSettle();
      expect(h.auth.resets, ['ana@correo.com']);
      expect(find.textContaining('Si el correo tiene una cuenta'), findsOneWidget);
    });

    testWidgets('el enlace del correo lleva a elegir una nueva contraseña', (tester) async {
      final h = await _pump(tester);
      h.auth.accounts['ana@correo.com'] = 'clave-vieja-1';
      h.auth.ids['ana@correo.com'] = 'user-1';
      h.auth.startRecovery('ana@correo.com');
      await tester.pumpAndSettle();

      expect(find.byType(PasswordRecoveryScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);

      await tester.enterText(_field('Nueva contraseña'), 'clave-nueva-2026');
      await tester.enterText(_field('Repite la contraseña'), 'clave-nueva-2026');
      await tester.tap(find.text('Guardar contraseña'));
      await tester.pumpAndSettle();

      expect(h.auth.lastUpdatedPassword, 'clave-nueva-2026');
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('cerrar sesión y aislamiento entre usuarios', () {
    testWidgets('cerrar sesión vuelve al login y borra el borrador local', (tester) async {
      final h = await _pump(tester);
      await _register(tester);

      tester.widget<HomeScreen>(find.byType(HomeScreen)).controller.addWord(english: 'Egg', spanish: 'Huevo');
      await tester.pumpAndSettle();
      expect(h.prefs.getKeys().any((k) => k.startsWith('gridlearn.draft.v2.user-1')), isTrue);

      await tester.tap(find.text('ana@correo.com'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      // Hay palabras sin guardar: pide confirmación.
      expect(find.text('Cambios sin guardar'), findsOneWidget);
      await tester.tap(find.text('Descartar cambios'));
      await tester.pumpAndSettle();

      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(h.prefs.getKeys().any((k) => k.startsWith('gridlearn.draft.v2.user-1')), isFalse);
    });

    testWidgets('cada usuario ve solo sus propios vocabularios', (tester) async {
      final h = await _pump(tester);
      await _register(tester, email: 'ana@correo.com');
      var controller = tester.widget<HomeScreen>(find.byType(HomeScreen)).controller;
      controller.addWord(english: 'Egg', spanish: 'Huevo');
      await controller.save();
      expect(h.repositories['user-1']!.store, hasLength(1));

      // Sale Ana y entra Beto.
      await h.auth.signOut();
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);
      await _register(tester, email: 'beto@correo.com');

      controller = tester.widget<HomeScreen>(find.byType(HomeScreen)).controller;
      expect(controller.words, isEmpty, reason: 'no hereda el trabajo de Ana');
      expect(await controller.listSaved(), isEmpty);
      expect(h.repositories['user-2']!.store, isEmpty);
      expect(h.repositories['user-1']!.store, hasLength(1));
    });

    testWidgets('si la sesión termina de golpe (expira) se vuelve al login', (tester) async {
      final h = await _pump(tester);
      await _register(tester);
      expect(find.byType(HomeScreen), findsOneWidget);

      await h.auth.signOut();
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);
    });
  });
}
