import '../models/word.dart';

/// Sentido de la pregunta: se muestra una palabra y se pide su traducción.
enum Direction { esToEn, enToEs }

/// Tipos de pregunta. De menos a más esfuerzo de memoria:
/// reconocer (opción múltiple, verdadero/falso) → armar (ordenar letras) →
/// producir (escribir).
enum QuestionKind { multipleChoice, trueFalse, scramble, type }

String promptOf(Word word, Direction direction) =>
    direction == Direction.esToEn ? word.spanish : word.english;

String answerOf(Word word, Direction direction) =>
    direction == Direction.esToEn ? word.english : word.spanish;

/// Una pregunta lista para mostrar.
class Question {
  const Question({
    required this.kind,
    required this.word,
    required this.direction,
    required this.prompt,
    required this.answer,
    this.options = const [],
    this.letters = const [],
    this.shownAnswer = '',
    this.isTrue = true,
  });

  final QuestionKind kind;
  final Word word;
  final Direction direction;

  /// Lo que se muestra (la palabra a traducir).
  final String prompt;

  /// La respuesta correcta.
  final String answer;

  /// Opción múltiple: las opciones (incluye la correcta), ya mezcladas.
  final List<String> options;

  /// Ordenar letras: las letras mezcladas.
  final List<String> letters;

  /// Verdadero/falso: la traducción que se propone (puede ser falsa).
  final String shownAnswer;
  final bool isTrue;

  /// Idioma en que hay que responder.
  String get targetLanguage => direction == Direction.esToEn ? 'inglés' : 'español';

  /// Valor que se envía al responder verdadero/falso.
  static String trueFalseValue(bool value) => value ? 'true' : 'false';
}
