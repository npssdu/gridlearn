import 'package:flutter/material.dart';

import '../../game/game_result.dart';
import '../../theme/app_theme.dart';
import 'game_effects.dart';

/// Pantalla final: estrellas, puntos, estadísticas y las palabras para repasar.
class ResultsView extends StatelessWidget {
  const ResultsView({
    super.key,
    required this.result,
    required this.onPlayAgain,
    required this.onMenu,
    this.onReviewMissed,
  });

  final GameResult result;
  final VoidCallback onPlayAgain;
  final VoidCallback onMenu;

  /// Si hay palabras falladas: empieza una Aventura solo con ellas.
  final VoidCallback? onReviewMissed;

  String get _headline {
    if (result.headline != null) return result.headline!;
    switch (result.stars) {
      case 3:
        return '¡Increíble!';
      case 2:
        return '¡Muy bien!';
      default:
        return '¡Buen intento!';
    }
  }

  String _time(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final missed = result.missed;
    final celebrate = result.won && result.stars >= 2;
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Text(_headline, textAlign: TextAlign.center, style: AppTheme.heading(32, weight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < 3; i++)
                          PopIn(
                            duration: Duration(milliseconds: 350 + i * 250),
                            child: Icon(
                              i < result.stars ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 54,
                              color: i < result.stars ? AppColors.amber : AppColors.slate300,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${result.score} puntos',
                      textAlign: TextAlign.center,
                      style: AppTheme.heading(22, color: AppColors.navySoft),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _Stat(icon: Icons.check_circle_rounded, color: AppColors.teal, label: 'Aciertos', value: '${result.correct}/${result.total}'),
                        if (result.bestStreak > 0)
                          _Stat(icon: Icons.local_fire_department_rounded, color: AppColors.orange, label: 'Mejor racha', value: 'x${result.bestStreak}'),
                        if (result.duration != null)
                          _Stat(icon: Icons.timer_outlined, color: AppColors.sky, label: 'Tiempo', value: _time(result.duration!)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (missed.isEmpty && result.total >= 3)
                      const _Note(
                        icon: Icons.emoji_events_rounded,
                        text: '¡Sin palabras falladas! Todas te salieron bien.',
                        color: AppColors.teal,
                      )
                    else if (missed.isNotEmpty) ...[
                      Text('Para repasar', style: AppTheme.heading(18)),
                      const SizedBox(height: 8),
                      for (final w in missed.take(8))
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadii.tile),
                            border: Border.all(color: AppColors.slate200),
                          ),
                          child: Row(
                            children: [
                              Expanded(child: Text(w.english, style: const TextStyle(fontWeight: FontWeight.w800))),
                              const Icon(Icons.arrow_right_alt_rounded, color: AppColors.slate400),
                              Expanded(
                                child: Text(
                                  w.spanish,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(color: AppColors.slate600, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (missed.length > 8)
                        Text('y ${missed.length - 8} más…', style: const TextStyle(color: AppColors.slate500)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: onPlayAgain,
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: const Text('Jugar de nuevo'),
                ),
                if (onReviewMissed != null && missed.isNotEmpty)
                  FilledButton.icon(
                    onPressed: onReviewMissed,
                    icon: const Icon(Icons.rocket_launch_outlined, size: 18),
                    label: const Text('Repasar falladas'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.orange),
                  ),
                OutlinedButton.icon(
                  onPressed: onMenu,
                  icon: const Icon(Icons.apps_rounded, size: 18),
                  label: const Text('Elegir otro juego'),
                ),
              ],
            ),
          ],
        ),
        if (celebrate) const Positioned.fill(child: Confetti()),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.color, required this.label, required this.value});

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.tile),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.slate600)),
              Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.tile),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
