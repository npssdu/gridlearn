import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Barra superior del juego: salir, progreso, puntos, racha y un extra
/// ([trailing]: vidas, tiempo, etc.).
class GameHud extends StatelessWidget {
  const GameHud({
    super.key,
    required this.onExit,
    this.progress,
    this.progressColor = AppColors.sky,
    required this.score,
    this.streak = 0,
    this.trailing,
  });

  final VoidCallback onExit;

  /// 0..1, o null para ocultar la barra.
  final double? progress;
  final Color progressColor;
  final int score;
  final int streak;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onExit,
          tooltip: 'Salir del juego',
          icon: const Icon(Icons.close_rounded),
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: progress == null
              ? const SizedBox.shrink()
              : ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: progress!.clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOut,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 14,
                      backgroundColor: AppColors.slate100,
                      color: progressColor,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 10),
        if (streak >= 2) ...[
          _Pill(
            icon: Icons.local_fire_department_rounded,
            label: 'x$streak',
            background: AppColors.orange,
            foreground: Colors.white,
          ),
          const SizedBox(width: 6),
        ],
        _Pill(
          icon: Icons.star_rounded,
          label: '$score',
          background: AppColors.amber,
          foreground: AppColors.navy,
        ),
        if (trailing != null) ...[const SizedBox(width: 6), trailing!],
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.background, required this.foreground});

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadii.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 3),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
            child: Text(
              label,
              key: ValueKey(label),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vidas como corazones.
class Hearts extends StatelessWidget {
  const Hearts({super.key, required this.lives, required this.max});

  final int lives;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < max; i++)
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Icon(
              i < lives ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 20,
              color: i < lives ? AppColors.rose : AppColors.slate300,
            ),
          ),
      ],
    );
  }
}
