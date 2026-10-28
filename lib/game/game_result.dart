import '../models/word.dart';

enum GameMode {
  adventure(minWords: 1),
  blitz(minWords: 2),
  match(minWords: 3),
  bingo(minWords: 3);

  const GameMode({required this.minWords});

  /// Palabras necesarias para poder jugarlo.
  final int minWords;
}

/// Resumen al terminar una partida.
class GameResult {
  const GameResult({
    required this.mode,
    required this.score,
    required this.stars,
    required this.correct,
    required this.total,
    required this.bestStreak,
    this.missed = const [],
    this.duration,
    this.won = true,
    this.headline,
  });

  final GameMode mode;
  final int score;

  /// 0 a 3.
  final int stars;
  final int correct;
  final int total;
  final int bestStreak;

  /// Palabras que costaron trabajo, para repasarlas.
  final List<Word> missed;
  final Duration? duration;

  /// Falso si se acabaron las vidas.
  final bool won;

  /// Título opcional ("¡BINGO!", "¡Tiempo!").
  final String? headline;

  double get accuracy => total == 0 ? 0 : correct / total;
}

/// Estrellas según el porcentaje de aciertos.
int starsForAccuracy(double accuracy) {
  if (accuracy >= 0.85) return 3;
  if (accuracy >= 0.65) return 2;
  return 1;
}

/// Frases de ánimo para los aciertos.
const praises = ['¡Excelente!', '¡Muy bien!', '¡Eso es!', '¡Genial!', '¡Perfecto!', '¡Así se hace!'];
const encouragements = ['¡Casi!', '¡Ánimo!', 'Esta vez no, ¡a la próxima!', 'Sigue practicando'];
