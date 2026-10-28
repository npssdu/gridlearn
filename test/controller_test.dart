import 'package:flutter_test/flutter_test.dart';
import 'package:gridlearn/models/vocabulary.dart';
import 'package:gridlearn/services/draft_storage.dart';
import 'package:gridlearn/services/local_vocabulary_repository.dart';
import 'package:gridlearn/services/vocabulary_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  group('VocabController', () {
    test('el título es opcional y se limita a 120 caracteres', () async {
      final c = await makeController();
      expect(c.title, '');
      c.setTitle('a' * 200);
      expect(c.title.length, maxTitleLength);
    });

    test('guarda como nuevo y luego actualiza el mismo vocabulario', () async {
      final repo = InMemoryVocabularyRepository();
      final c = await makeController(repository: repo);
      c.setTitle('Pascua');
      c.addWord(english: 'Egg', spanish: 'Huevo');
      expect(c.hasUnsavedWork, isTrue);
      expect(c.isSaved, isFalse);

      await c.save();
      expect(c.id, isNotNull);
      expect(c.isSaved, isTrue);
      expect(repo.store, hasLength(1));
      expect(repo.store[c.id]!.title, 'Pascua');

      c.addWord(english: 'Sun', spanish: 'Sol');
      expect(c.isSaved, isFalse);
      await c.save();
      expect(repo.store, hasLength(1), reason: 'actualiza, no duplica');
      expect(repo.store[c.id]!.words, hasLength(2));
    });

    test('sin título se guarda igualmente', () async {
      final repo = InMemoryVocabularyRepository();
      final c = await makeController(repository: repo);
      c.addWord(english: 'Egg', spanish: 'Huevo');
      await c.save();
      expect(repo.store.values.single.title, '');
    });

    test('un fallo al guardar deja los cambios pendientes y lanza el mensaje', () async {
      final repo = InMemoryVocabularyRepository();
      final c = await makeController(repository: repo);
      c.addWord(english: 'Egg', spanish: 'Huevo');
      repo.failWith = 'Sin conexión';
      await expectLater(c.save(), throwsA(isA<RepositoryException>()));
      expect(c.saving, isFalse);
      expect(c.hasUnsavedWork, isTrue);
    });

    test('abrir un guardado reemplaza el contenido y lo deja sin cambios', () async {
      final repo = InMemoryVocabularyRepository();
      final a = await makeController(repository: repo);
      a.setTitle('Uno');
      a.addWord(english: 'Egg', spanish: 'Huevo');
      await a.save();
      final savedId = a.id!;

      a.startNew();
      expect(a.words, isEmpty);
      expect(a.id, isNull);

      await a.openSaved(savedId);
      expect(a.title, 'Uno');
      expect(a.words.single.english, 'Egg');
      expect(a.isSaved, isTrue);
    });

    test('borrar el vocabulario abierto empieza uno nuevo', () async {
      final repo = InMemoryVocabularyRepository();
      final c = await makeController(repository: repo);
      c.addWord(english: 'Egg', spanish: 'Huevo');
      await c.save();
      await c.deleteSaved(c.id!);
      expect(repo.store, isEmpty);
      expect(c.id, isNull);
      expect(c.words, isEmpty);
    });

    test('el borrador sobrevive a una recarga y se separa por usuario', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final first = await makeController(prefs: prefs, scope: 'ana');
      first.setTitle('Borrador');
      first.addWord(english: 'Egg', spanish: 'Huevo');

      final reloaded = await makeController(prefs: prefs, scope: 'ana');
      expect(reloaded.title, 'Borrador');
      expect(reloaded.words, hasLength(1));
      expect(reloaded.hasUnsavedWork, isTrue);

      final other = await makeController(prefs: prefs, scope: 'beto');
      expect(other.title, '');
      expect(other.words, isEmpty);

      await reloaded.discardDraft();
      final afterDiscard = await makeController(prefs: prefs, scope: 'ana');
      expect(afterDiscard.words, isEmpty);
    });

    test('importa las palabras de la versión web anterior (modo local)', () async {
      final c = await makeController(
        scope: 'local',
        initialPrefs: {
          // La versión anterior guardaba la palabra más reciente primero.
          'gridlearn.words.v1':
              '[{"id":"2","english":"Sun","spanish":"Sol","phonetic":"","createdAt":2},'
                  '{"id":"1","english":"Egg","spanish":"Huevo","phonetic":"","createdAt":1}]',
        },
      );
      expect(c.words.map((w) => w.english), ['Egg', 'Sun']);
    });
  });

  group('LocalVocabularyRepository', () {
    test('crea, lista, carga, actualiza y borra por usuario', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = LocalVocabularyRepository(prefs, scope: 'ana');
      final otherUser = LocalVocabularyRepository(prefs, scope: 'beto');

      final id = await repo.save(const Vocabulary(title: 'Uno'));
      expect(await repo.list(), hasLength(1));
      expect(await otherUser.list(), isEmpty);
      expect((await repo.load(id)).title, 'Uno');

      await repo.save(Vocabulary(id: id, title: 'Dos'));
      expect((await repo.list()).single.title, 'Dos');

      await repo.delete(id);
      expect(await repo.list(), isEmpty);
      await expectLater(repo.load(id), throwsA(isA<RepositoryException>()));
    });
  });

  test('DraftStorage ignora datos corruptos', () async {
    SharedPreferences.setMockInitialValues({'gridlearn.draft.v2.x': 'no es json'});
    final prefs = await SharedPreferences.getInstance();
    final draft = DraftStorage(prefs, scope: 'x').load();
    expect(draft.vocabulary.words, isEmpty);
    expect(draft.dirty, isFalse);
  });
}
