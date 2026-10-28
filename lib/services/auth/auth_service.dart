/// Usuario con sesión iniciada.
class AppUser {
  const AppUser({required this.id, this.email});

  final String id;
  final String? email;
}

/// Estado de la sesión. [passwordRecovery] es true cuando la persona llegó
/// desde el enlace del correo "restablecer contraseña" y debe elegir una nueva.
class SessionState {
  const SessionState({this.user, this.passwordRecovery = false});

  final AppUser? user;
  final bool passwordRecovery;
}

enum SignUpOutcome {
  /// La cuenta quedó activa y con sesión iniciada.
  signedIn,

  /// Hay que confirmar el correo antes de entrar.
  confirmationRequired,
}

/// Error con un mensaje listo para mostrar al usuario.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Contrato de autenticación. La app solo depende de esto, así que se puede
/// cambiar de proveedor o usar un doble en las pruebas.
abstract class AuthService {
  SessionState get state;
  Stream<SessionState> get changes;

  /// `false` en modo local: no hay cuentas ni inicio de sesión.
  bool get requiresLogin;

  Future<void> signIn({required String email, required String password});
  Future<SignUpOutcome> signUp({required String email, required String password});
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);
  Future<void> updatePassword(String newPassword);
}

/// Reglas de contraseña del cliente (Supabase aplica además las suyas).
const minPasswordLength = 8;

/// Devuelve un mensaje si la contraseña es débil, o `null` si es aceptable.
String? validatePassword(String? value) {
  final password = value ?? '';
  if (password.length < minPasswordLength) {
    return 'Usa al menos $minPasswordLength caracteres';
  }
  if (!RegExp(r'[A-Za-z]').hasMatch(password) || !RegExp(r'\d').hasMatch(password)) {
    return 'Combina letras y números';
  }
  return null;
}

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

String? validateEmail(String? value) {
  final email = (value ?? '').trim();
  if (email.isEmpty) return 'Ingresa tu correo';
  if (email.length > 254 || !_emailPattern.hasMatch(email)) return 'Correo no válido';
  return null;
}
