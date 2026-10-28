import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/vocabulary.dart';
import '../models/word.dart';
import 'vocabulary_repository.dart';

/// Vocabularios guardados en Postgres (Supabase). Las políticas RLS de la base
/// garantizan que cada consulta solo ve y modifica las filas del usuario.
class SupabaseVocabularyRepository implements VocabularyRepository {
  SupabaseVocabularyRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<VocabularySummary>> list() {
    return _guard(() async {
      final rows = await _client
          .from('vocabularies')
          .select('id, title, updated_at, vocabulary_words(count)')
          .order('updated_at', ascending: false);
      return [
        for (final row in rows)
          VocabularySummary(
            id: row['id'] as String,
            title: row['title'] as String? ?? '',
            wordCount: _count(row['vocabulary_words']),
            updatedAt: DateTime.parse(row['updated_at'] as String).toLocal(),
          ),
      ];
    });
  }

  @override
  Future<Vocabulary> load(String id) {
    return _guard(() async {
      final vocabulary = await _client
          .from('vocabularies')
          .select('id, title, updated_at')
          .eq('id', id)
          .maybeSingle();
      if (vocabulary == null) {
        throw const RepositoryException('No se encontró el vocabulario.');
      }
      final rows = await _client
          .from('vocabulary_words')
          .select('id, english, spanish, phonetic, created_at')
          .eq('vocabulary_id', id)
          .order('position');
      return Vocabulary(
        id: vocabulary['id'] as String,
        title: vocabulary['title'] as String? ?? '',
        updatedAt: DateTime.parse(vocabulary['updated_at'] as String).toLocal(),
        words: [
          for (final row in rows)
            Word(
              id: row['id'] as String,
              english: row['english'] as String,
              spanish: row['spanish'] as String,
              phonetic: row['phonetic'] as String? ?? '',
              createdAt: DateTime.parse(row['created_at'] as String).millisecondsSinceEpoch,
            ),
        ],
      );
    });
  }

  @override
  Future<String> save(Vocabulary vocabulary) {
    return _guard(() async {
      final id = await _client.rpc(
        'save_vocabulary',
        params: {
          'p_id': vocabulary.id,
          'p_title': vocabulary.title,
          'p_words': [
            for (final w in vocabulary.words)
              {'english': w.english, 'spanish': w.spanish, 'phonetic': w.phonetic},
          ],
        },
      );
      return id as String;
    });
  }

  @override
  Future<void> delete(String id) {
    return _guard(() => _client.from('vocabularies').delete().eq('id', id));
  }

  int _count(dynamic embedded) {
    if (embedded is List && embedded.isNotEmpty) {
      return (embedded.first['count'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on RepositoryException {
      rethrow;
    } on PostgrestException catch (e) {
      throw RepositoryException(_translate(e));
    } on AuthRetryableFetchException {
      throw const RepositoryException('No se pudo conectar. Revisa tu conexión e inténtalo de nuevo.');
    } on AuthException {
      throw const RepositoryException('Tu sesión expiró. Inicia sesión de nuevo.');
    } catch (_) {
      throw const RepositoryException('No se pudo conectar. Revisa tu conexión e inténtalo de nuevo.');
    }
  }

  String _translate(PostgrestException e) {
    switch (e.code) {
      case '54000':
        return e.message;
      case 'P0002':
        return 'No se encontró el vocabulario (quizá ya fue eliminado).';
      case '28000':
      case '42501':
      case 'PGRST301':
        return 'Tu sesión expiró. Inicia sesión de nuevo.';
      case '23514':
        return 'Alguna palabra o el título supera el largo permitido (120 caracteres).';
    }
    return 'No se pudo completar la operación. Inténtalo de nuevo.';
  }
}
