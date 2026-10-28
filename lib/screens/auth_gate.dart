import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth/auth_service.dart';
import '../services/draft_storage.dart';
import '../services/vocabulary_repository.dart';
import '../state/vocab_controller.dart';
import 'auth_screen.dart';
import 'home_screen.dart';
import 'password_recovery_screen.dart';

/// Decide qué pantalla mostrar según la sesión: inicio de sesión, cambio de
/// contraseña (enlace del correo) o la app con los datos del usuario.
class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.auth,
    required this.prefs,
    required this.repositoryFor,
  });

  final AuthService auth;
  final SharedPreferences prefs;

  /// Crea el repositorio de vocabularios del usuario con sesión.
  final VocabularyRepository Function(AppUser user) repositoryFor;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SessionState>(
      stream: auth.changes,
      initialData: auth.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? auth.state;
        final user = state.user;
        if (user == null) return AuthScreen(auth: auth);
        if (state.passwordRecovery) return PasswordRecoveryScreen(auth: auth);
        return _Workspace(
          // Otro usuario = otro controlador: nunca se mezclan datos entre cuentas.
          key: ValueKey(user.id),
          auth: auth,
          user: user,
          prefs: prefs,
          repository: repositoryFor(user),
        );
      },
    );
  }
}

class _Workspace extends StatefulWidget {
  const _Workspace({
    super.key,
    required this.auth,
    required this.user,
    required this.prefs,
    required this.repository,
  });

  final AuthService auth;
  final AppUser user;
  final SharedPreferences prefs;
  final VocabularyRepository repository;

  @override
  State<_Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<_Workspace> {
  late final VocabController _controller = VocabController(
    repository: widget.repository,
    draft: DraftStorage(widget.prefs, scope: widget.user.id),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreen(controller: _controller, auth: widget.auth, user: widget.user);
  }
}
