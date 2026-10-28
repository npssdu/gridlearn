import 'dart:async';

import 'package:flutter/foundation.dart';

import '../logic/grid_builder.dart';
import '../models/vocabulary.dart';
import '../models/word.dart';
import '../services/draft_storage.dart';
import '../services/vocabulary_repository.dart';

/// Estado del vocabulario que se está editando: título opcional, palabras,
/// grilla del bingo, casillas marcadas, y guardado/apertura de vocabularios.
///
/// Las palabras se guardan en orden de llegada (la primera ocupa la primera
/// casilla). El borrador se conserva localmente para no perder el trabajo al
/// recargar la página.
class VocabController extends ChangeNotifier {
  VocabController({required VocabularyRepository repository, required DraftStorage draft})
      : _repository = repository,
        _draft = draft {
    final restored = draft.load();
    _id = restored.vocabulary.id;
    _title = restored.vocabulary.title;
    _words = [...restored.vocabulary.words];
    _dirty = restored.dirty;
    _grid = buildGrid(_words);
  }

  final VocabularyRepository _repository;
  final DraftStorage _draft;

  String? _id;
  String _title = '';
  List<Word> _words = [];
  late List<GridSlot> _grid;
  final Set<String> _marked = {};
  Word? _editing;
  bool _dirty = false;
  bool _saving = false;
  int _idCounter = 0;

  /// Id del vocabulario guardado que está abierto; `null` si aún no se guardó.
  String? get id => _id;
  String get title => _title;

  /// Palabras en orden de llegada.
  List<Word> get words => List.unmodifiable(_words);
  List<GridSlot> get grid => _grid;
  Word? get editing => _editing;
  bool get saving => _saving;

  bool get hasContent => _title.trim().isNotEmpty || _words.isNotEmpty;

  /// Hay algo que se perdería al abrir otro vocabulario o cerrar sesión.
  bool get hasUnsavedWork => _dirty && hasContent;

  /// El vocabulario abierto ya está guardado y sin cambios pendientes.
  bool get isSaved => _id != null && !_dirty;

  bool isMarked(String slotId) => _marked.contains(slotId);

  // --- Título y palabras ----------------------------------------------------

  void setTitle(String value) {
    final next = value.length > maxTitleLength ? value.substring(0, maxTitleLength) : value;
    if (next == _title) return;
    _title = next;
    _changed();
  }

  void addWord({required String english, required String spanish, String phonetic = ''}) {
    final word = Word(
      id: '${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}',
      english: english.trim(),
      spanish: spanish.trim(),
      phonetic: phonetic.trim(),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    _editing = null;
    _setWords([..._words, word]);
  }

  void updateWord(String id, {required String english, required String spanish, String phonetic = ''}) {
    _editing = null;
    _setWords([
      for (final w in _words)
        if (w.id == id)
          w.copyWith(
            english: english.trim(),
            spanish: spanish.trim(),
            phonetic: phonetic.trim(),
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          )
        else
          w,
    ]);
  }

  void removeWord(String id) {
    if (_editing?.id == id) _editing = null;
    _marked.remove(id);
    _setWords(_words.where((w) => w.id != id).toList());
  }

  void startEditing(Word word) {
    _editing = word;
    notifyListeners();
  }

  void cancelEditing() {
    _editing = null;
    notifyListeners();
  }

  void toggleMarked(String slotId) {
    if (!_marked.remove(slotId)) _marked.add(slotId);
    notifyListeners();
  }

  // --- Vocabularios guardados -----------------------------------------------

  /// Guarda (crea o actualiza) el vocabulario actual. Lanza [RepositoryException]
  /// con un mensaje para el usuario si falla.
  Future<void> save() async {
    if (_saving) return;
    _saving = true;
    notifyListeners();
    try {
      final id = await _repository.save(Vocabulary(id: _id, title: _title.trim(), words: _words));
      _id = id;
      _dirty = false;
      await _persistDraft();
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<List<VocabularySummary>> listSaved() => _repository.list();

  /// Abre un vocabulario guardado, reemplazando el actual.
  Future<void> openSaved(String id) async {
    final vocabulary = await _repository.load(id);
    _replaceWith(vocabulary, dirty: false);
  }

  Future<void> deleteSaved(String id) async {
    await _repository.delete(id);
    if (_id == id) startNew();
  }

  /// Empieza un vocabulario vacío (descarta el actual).
  void startNew() => _replaceWith(const Vocabulary(), dirty: false);

  /// Borra el borrador local (al cerrar sesión).
  Future<void> discardDraft() => _draft.clear();

  // --- Internos -------------------------------------------------------------

  void _replaceWith(Vocabulary vocabulary, {required bool dirty}) {
    _id = vocabulary.id;
    _title = vocabulary.title;
    _words = [...vocabulary.words];
    _dirty = dirty;
    _editing = null;
    _marked.clear();
    _grid = buildGrid(_words);
    unawaited(_persistDraft());
    notifyListeners();
  }

  void _setWords(List<Word> next) {
    _words = next;
    _grid = buildGrid(_words);
    _changed();
  }

  void _changed() {
    _dirty = true;
    unawaited(_persistDraft());
    notifyListeners();
  }

  Future<void> _persistDraft() {
    return _draft.save(Vocabulary(id: _id, title: _title, words: _words), dirty: _dirty);
  }
}
