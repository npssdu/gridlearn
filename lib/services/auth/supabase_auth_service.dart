import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

/// Autenticación con Supabase Auth (correo y contraseña).
///
/// Los mensajes de error son deliberadamente genéricos en el inicio de sesión
/// y el registro para no revelar si un correo ya tiene cuenta.
class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._client) {
    _subscription = _client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) _recovering = true;
      if (data.event == AuthChangeEvent.signedOut) _recovering = false;
      _controller.add(state);
    });
  }

  final SupabaseClient _client;
  final _controller = StreamController<SessionState>.broadcast();
  late final StreamSubscription<dynamic> _subscription;
  bool _recovering = false;

  @override
  bool get requiresLogin => true;

  @override
  Stream<SessionState> get changes => _controller.stream;

  @override
  SessionState get state {
    final user = _client.auth.currentUser;
    return SessionState(
      user: user == null ? null : AppUser(id: user.id, email: user.email),
      passwordRecovery: _recovering,
    );
  }

  /// Dirección a la que vuelve la persona desde los enlaces del correo.
  String? get _redirectUrl => kIsWeb ? Uri.base.origin : null;

  @override
  Future<void> signIn({required String email, required String password}) {
    return _guard(() => _client.auth.signInWithPassword(email: email.trim(), password: password));
  }

  @override
  Future<SignUpOutcome> signUp({required String email, required String password}) async {
    final response = await _guard(
      () => _client.auth.signUp(
        email: email.trim(),
        password: password,
        emailRedirectTo: _redirectUrl,
      ),
    );
    return response.session != null ? SignUpOutcome.signedIn : SignUpOutcome.confirmationRequired;
  }

  @override
  Future<void> signOut() => _guard(() => _client.auth.signOut());

  @override
  Future<void> sendPasswordReset(String email) {
    return _guard(() => _client.auth.resetPasswordForEmail(email.trim(), redirectTo: _redirectUrl));
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await _guard(() => _client.auth.updateUser(UserAttributes(password: newPassword)));
    _recovering = false;
    _controller.add(state);
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthRetryableFetchException {
      throw const AuthFailure('No se pudo conectar. Revisa tu conexión e inténtalo de nuevo.');
    } on AuthException catch (e) {
      throw AuthFailure(_translate(e));
    } catch (_) {
      throw const AuthFailure('No se pudo conectar. Revisa tu conexión e inténtalo de nuevo.');
    }
  }

  String _translate(AuthException e) {
    switch (e.code) {
      case 'invalid_credentials':
      case 'user_not_found':
        return 'Correo o contraseña incorrectos.';
      case 'email_not_confirmed':
        return 'Confirma tu correo antes de iniciar sesión (revisa tu bandeja de entrada).';
      case 'weak_password':
        return 'La contraseña es demasiado débil. Usa al menos $minPasswordLength caracteres con letras y números.';
      case 'same_password':
        return 'La nueva contraseña debe ser distinta de la anterior.';
      case 'over_request_rate_limit':
      case 'over_email_send_rate_limit':
        return 'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.';
      case 'signup_disabled':
        return 'El registro de nuevas cuentas está desactivado.';
      case 'validation_failed':
      case 'email_address_invalid':
        return 'Revisa el correo y la contraseña ingresados.';
    }
    final message = e.message.toLowerCase();
    if (message.contains('invalid login') || message.contains('invalid credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (message.contains('rate limit')) {
      return 'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.';
    }
    return 'No se pudo completar la operación. Inténtalo de nuevo.';
  }

  void dispose() {
    _subscription.cancel();
    _controller.close();
  }
}
