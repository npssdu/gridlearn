import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/vocabulary.dart';
import '../models/word.dart';

/// Borrador del vocabulario que se está editando, para no perder el trabajo
/// al recargar la página. Está separado por usuario ([scope]) y se borra al
/// cerrar sesión.
class DraftStorage {
  DraftStorage(this._prefs, {required String scope})
      : _scope = scope,
        _key = 'gridlearn.draft.v2.$scope';

  /// Clave que usaba la versión web original (palabras, la más reciente primero).
  static const _legacyKey = 'gridlearn.words.v1';

  final SharedPreferences _prefs;
  final String _scope;
  final String _key;

  Draft load() {
    try {
      final raw = _prefs.getString(_key);
      if (raw != null) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        return Draft(
          vocabulary: Vocabulary(
            id: json['id'] as String?,
            title: json['title'] as String? ?? '',
            words: [
              for (final w in json['words'] as List<dynamic>) Word.fromJson(w as Map<String, dynamic>),
            ],
          ),
          dirty: json['dirty'] as bool? ?? false,
        );
      }
      return _loadLegacy();
    } catch (_) {
      return const Draft(vocabulary: Vocabulary(), dirty: false);
    }
  }

  /// Importa las palabras guardadas por la versión anterior (solo modo local).
  Draft _loadLegacy() {
    final raw = _prefs.getString(_legacyKey);
    if (_scope != 'local' || raw == null) {
      return const Draft(vocabulary: Vocabulary(), dirty: false);
    }
    final words = [
      for (final w in jsonDecode(raw) as List<dynamic>) Word.fromJson(w as Map<String, dynamic>),
    ].reversed.toList();
    return Draft(vocabulary: Vocabulary(words: words), dirty: words.isNotEmpty);
  }

  Future<void> save(Vocabulary vocabulary, {required bool dirty}) {
    return _prefs.setString(
      _key,
      jsonEncode({
        'id': vocabulary.id,
        'title': vocabulary.title,
        'dirty': dirty,
        'words': vocabulary.words.map((w) => w.toJson()).toList(),
      }),
    );
  }

  Future<void> clear() => _prefs.remove(_key);
}

class Draft {
  const Draft({required this.vocabulary, required this.dirty});

  final Vocabulary vocabulary;

  /// Hay cambios que aún no se guardaron.
  final bool dirty;
}
