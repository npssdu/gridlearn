import 'dart:async';

import 'package:gridlearn/models/vocabulary.dart';
import 'package:gridlearn/services/auth/auth_service.dart';
import 'package:gridlearn/services/draft_storage.dart';
import 'package:gridlearn/services/vocabulary_repository.dart';
import 'package:gridlearn/state/vocab_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Autenticación en memoria para las pruebas.
class FakeAuthService implements AuthService {
  FakeAuthService({this.confirmationRequired = false});

  /// Si es true, el registro no inicia sesión (hay que confirmar el correo).
  final bool confirmationRequired;

  final Map<String, String> accounts = {};
  final _controller = StreamController<SessionState>.broadcast();
  SessionState _state = const SessionState();
  int _next = 1;
  final ids = <String, String>{};

  @override
  bool get requiresLogin => true;

  @override
  SessionState get state => _state;

  @override
  Stream<SessionState> get changes => _controller.stream;

  void _emit(SessionState state) {
    _state = state;
    _controller.add(state);
  }

  void startRecovery(String email) {
    _emit(SessionState(user: AppUser(id: ids[email]!, email: email), passwordRecovery: true));
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    final e = email.trim();
    if (accounts[e] != password) throw const AuthFailure('Correo o contraseña incorrectos.');
    _emit(SessionState(user: AppUser(id: ids[e]!, email: e)));
  }

  @override
  Future<SignUpOutcome> signUp({required String email, required String password}) async {
    final e = email.trim();
    accounts.putIfAbsent(e, () => password);
    ids.putIfAbsent(e, () => 'user-${_next++}');
    if (confirmationRequired) return SignUpOutcome.confirmationRequired;
    _emit(SessionState(user: AppUser(id: ids[e]!, email: e)));
    return SignUpOutcome.signedIn;
  }

  @override
  Future<void> signOut() async => _emit(const SessionState());

  final resets = <String>[];

  @override
  Future<void> sendPasswordReset(String email) async => resets.add(email.trim());

  String? lastUpdatedPassword;

  @override
  Future<void> updatePassword(String newPassword) async {
    lastUpdatedPassword = newPassword;
    final user = _state.user!;
    accounts[user.email!] = newPassword;
    _emit(SessionState(user: user));
  }
}

/// Repositorio en memoria (un conjunto de vocabularios por instancia).
class InMemoryVocabularyRepository implements VocabularyRepository {
  final Map<String, Vocabulary> store = {};
  final Map<String, DateTime> updated = {};
  int _next = 1;

  /// Si no es null, la siguiente operación falla con este mensaje.
  String? failWith;

  void _maybeFail() {
    final message = failWith;
    if (message != null) {
      failWith = null;
      throw RepositoryException(message);
    }
  }

  @override
  Future<List<VocabularySummary>> list() async {
    _maybeFail();
    final items = [
      for (final v in store.values)
        VocabularySummary(
          id: v.id!,
          title: v.title,
          wordCount: v.words.length,
          updatedAt: updated[v.id!]!,
        ),
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  @override
  Future<Vocabulary> load(String id) async {
    _maybeFail();
    final v = store[id];
    if (v == null) throw const RepositoryException('No se encontró el vocabulario.');
    return v;
  }

  @override
  Future<String> save(Vocabulary vocabulary) async {
    _maybeFail();
    final id = vocabulary.id ?? 'voc-${_next++}';
    store[id] = Vocabulary(id: id, title: vocabulary.title, words: vocabulary.words);
    updated[id] = DateTime(2026, 10, 27, 9, 15).add(Duration(minutes: _next));
    return id;
  }

  @override
  Future<void> delete(String id) async {
    _maybeFail();
    store.remove(id);
  }
}

Future<VocabController> makeController({
  InMemoryVocabularyRepository? repository,
  String scope = 'test',
  Map<String, Object> initialPrefs = const {},
  SharedPreferences? prefs,
}) async {
  if (prefs == null) {
    SharedPreferences.setMockInitialValues(initialPrefs);
  }
  final p = prefs ?? await SharedPreferences.getInstance();
  return VocabController(
    repository: repository ?? InMemoryVocabularyRepository(),
    draft: DraftStorage(p, scope: scope),
  );
}
