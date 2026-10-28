import '../logic/text_normalizer.dart';
import 'question.dart';

/// Resultado de una respuesta. [almost] es un error de una letra en una palabra
/// larga: cuenta como acierto pero se muestra la forma correcta.
enum Verdict { correct, almost, wrong }

extension VerdictX on Verdict {
  bool get isRight => this != Verdict.wrong;
}

int levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      current[j] = [previous[j] + 1, current[j - 1] + 1, previous[j - 1] + cost].reduce((x, y) => x < y ? x : y);
    }
    previous = current;
  }
  return previous[b.length];
}

/// Compara lo escrito con lo esperado ignorando tildes y mayúsculas.
Verdict checkTyped(String given, String expected) {
  final g = normalizeText(given);
  final e = normalizeText(expected);
  if (g.isEmpty) return Verdict.wrong;
  if (g == e) return Verdict.correct;
  if (e.length >= 5 && levenshtein(g, e) == 1) return Verdict.almost;
  return Verdict.wrong;
}

/// Evalúa la respuesta [given] a [question] según su tipo:
/// opción elegida, letras ordenadas, texto escrito o `true`/`false`.
Verdict evaluate(Question question, String given) {
  switch (question.kind) {
    case QuestionKind.type:
      return checkTyped(given, question.answer);
    case QuestionKind.multipleChoice:
    case QuestionKind.scramble:
      return normalizeText(given) == normalizeText(question.answer) ? Verdict.correct : Verdict.wrong;
    case QuestionKind.trueFalse:
      return given == Question.trueFalseValue(question.isTrue) ? Verdict.correct : Verdict.wrong;
  }
}
