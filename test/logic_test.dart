import 'package:flutter_test/flutter_test.dart';
import 'package:gridlearn/logic/grid_builder.dart';
import 'package:gridlearn/logic/text_normalizer.dart';
import 'package:gridlearn/models/word.dart';
import 'package:gridlearn/services/auth/auth_service.dart';

Word _word(String id) => Word(id: id, english: 'w$id', spanish: 's$id', createdAt: 0);

void main() {
  group('normalizeText', () {
    test('ignora mayúsculas, espacios y tildes', () {
      expect(normalizeText('  Canción '), 'cancion');
      expect(normalizeText('NIÑO'), 'nino');
      expect(normalizeText(null), '');
    });
  });

  group('buildGrid', () {
    test('sin palabras devuelve 30 casillas vacías', () {
      final grid = buildGrid([]);
      expect(grid, hasLength(gridSize));
      expect(grid.every((s) => s.isPlaceholder), isTrue);
    });

    test('cada palabra ocupa una sola casilla, en orden de llegada', () {
      final grid = buildGrid([_word('1'), _word('2'), _word('3')]);
      expect(grid, hasLength(gridSize));
      expect(grid.take(3).map((s) => s.english), ['w1', 'w2', 'w3']);
      expect(grid.skip(3).every((s) => s.isPlaceholder), isTrue);
    });

    test('una palabra nueva va a la primera casilla libre', () {
      final before = buildGrid([_word('1'), _word('2')]);
      final after = buildGrid([_word('1'), _word('2'), _word('3')]);
      expect(after[0].english, before[0].english);
      expect(after[1].english, before[1].english);
      expect(before[2].isPlaceholder, isTrue);
      expect(after[2].english, 'w3');
    });

    test('con más de 30 palabras solo caben 30', () {
      final grid = buildGrid([for (var i = 1; i <= 40; i++) _word('$i')]);
      expect(grid, hasLength(gridSize));
      expect(grid.last.english, 'w30');
    });

    test('las filas se calculan de 5 en 5', () {
      final grid = buildGrid([]);
      expect(grid[0].row, 0);
      expect(grid[4].row, 0);
      expect(grid[5].row, 1);
      expect(grid[29].row, 5);
    });
  });

  group('Word', () {
    test('ida y vuelta JSON compatible con la versión web', () {
      final json = {
        'id': 'abc',
        'english': 'Sun',
        'spanish': 'Sol',
        'phonetic': 'san',
        'createdAt': 123,
      };
      expect(Word.fromJson(json).toJson(), json);
    });
  });

  group('validatePassword', () {
    test('rechaza contraseñas cortas o sin mezcla de letras y números', () {
      expect(validatePassword(null), isNotNull);
      expect(validatePassword('abc123'), isNotNull);
      expect(validatePassword('sololetrasaqui'), isNotNull);
      expect(validatePassword('12345678'), isNotNull);
    });

    test('acepta una contraseña razonable', () {
      expect(validatePassword('clave-segura-2026'), isNull);
    });
  });

  group('validateEmail', () {
    test('valida el formato', () {
      expect(validateEmail(''), isNotNull);
      expect(validateEmail('sin-arroba'), isNotNull);
      expect(validateEmail('a@b'), isNotNull);
      expect(validateEmail(' persona@correo.com '), isNull);
    });
  });
}
