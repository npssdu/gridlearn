import 'auth_service.dart';

/// Modo local (sin Supabase): no hay inicio de sesión; siempre existe un
/// único usuario local y sus datos viven solo en este dispositivo.
class LocalAuthService implements AuthService {
  static const localUser = AppUser(id: 'local');

  @override
  SessionState get state => const SessionState(user: localUser);

  @override
  Stream<SessionState> get changes => const Stream.empty();

  @override
  bool get requiresLogin => false;

  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  Future<SignUpOutcome> signUp({required String email, required String password}) async =>
      SignUpOutcome.signedIn;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> updatePassword(String newPassword) async {}
}
