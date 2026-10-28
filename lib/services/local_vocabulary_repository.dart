import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/vocabulary.dart';
import '../models/word.dart';
import 'vocabulary_repository.dart';

/// Vocabularios guardados en este dispositivo (modo local, sin Supabase).
/// Cada [scope] (usuario) tiene su propia colección.
class LocalVocabularyRepository implements VocabularyRepository {
  LocalVocabularyRepository(this._prefs, {required String scope})
      : _key = 'gridlearn.vocabularies.v1.$scope';

  final SharedPreferences _prefs;
  final String _key;

  List<Map<String, dynamic>> _read() {
    try {
      final raw = _prefs.getString(_key);
      if (raw == null) return [];
      return (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _write(List<Map<String, dynamic>> rows) {
    return _prefs.setString(_key, jsonEncode(rows));
  }

  @override
  Future<List<VocabularySummary>> list() async {
    final summaries = [
      for (final row in _read())
        VocabularySummary(
          id: row['id'] as String,
          title: row['title'] as String? ?? '',
          wordCount: (row['words'] as List<dynamic>).length,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updatedAt'] as int),
        ),
    ];
    summaries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return summaries;
  }

  @override
  Future<Vocabulary> load(String id) async {
    final row = _read().where((r) => r['id'] == id).firstOrNull;
    if (row == null) throw const RepositoryException('No se encontró el vocabulario.');
    return Vocabulary(
      id: id,
      title: row['title'] as String? ?? '',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updatedAt'] as int),
      words: [
        for (final w in row['words'] as List<dynamic>) Word.fromJson(w as Map<String, dynamic>),
      ],
    );
  }

  @override
  Future<String> save(Vocabulary vocabulary) async {
    final rows = _read();
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = vocabulary.id ?? 'v$now';
    final row = {
      'id': id,
      'title': vocabulary.title.trim(),
      'updatedAt': now,
      'words': vocabulary.words.map((w) => w.toJson()).toList(),
    };
    final index = rows.indexWhere((r) => r['id'] == id);
    if (index >= 0) {
      rows[index] = row;
    } else {
      rows.add(row);
    }
    await _write(rows);
    return id;
  }

  @override
  Future<void> delete(String id) async {
    final rows = _read()..removeWhere((r) => r['id'] == id);
    await _write(rows);
  }
}
