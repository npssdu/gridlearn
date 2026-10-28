import '../models/vocabulary.dart';

/// Error legible para el usuario al guardar, cargar o borrar vocabularios.
class RepositoryException implements Exception {
  const RepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Almacén de los vocabularios guardados de un usuario.
abstract class VocabularyRepository {
  /// Vocabularios del usuario, el más reciente primero.
  Future<List<VocabularySummary>> list();

  Future<Vocabulary> load(String id);

  /// Crea (si `vocabulary.id` es null) o actualiza el vocabulario y devuelve su id.
  Future<String> save(Vocabulary vocabulary);

  Future<void> delete(String id);
}
