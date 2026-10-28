import 'package:flutter/material.dart';

import '../../game/game_result.dart';
import '../../theme/app_theme.dart';
import '../brand_logo.dart';

/// Metadatos de cada juego para el menú.
class _ModeInfo {
  const _ModeInfo(this.mode, this.title, this.subtitle, this.icon, this.color);

  final GameMode mode;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

const _modes = [
  _ModeInfo(
    GameMode.adventure,
    'Aventura',
    'Cada palabra sube de nivel: elige, ordena las letras y escribe. Las falladas vuelven.',
    Icons.rocket_launch_rounded,
    AppColors.sky,
  ),
  _ModeInfo(
    GameMode.blitz,
    'Relámpago',
    '60 segundos de preguntas rápidas con combos. Si fallas, pierdes tiempo.',
    Icons.bolt_rounded,
    AppColors.amber,
  ),
  _ModeInfo(
    GameMode.match,
    'Parejas',
    'Une cada palabra en inglés con su traducción lo más rápido que puedas.',
    Icons.extension_rounded,
    AppColors.teal,
  ),
  _ModeInfo(
    GameMode.bingo,
    'Bingo cantado',
    'Cantamos una palabra y tú la buscas en tu cartón. ¡Completa una línea!',
    Icons.grid_view_rounded,
    AppColors.orange,
  ),
];

/// Menú de la evaluación: elegir a qué jugar.
class GameMenu extends StatelessWidget {
  const GameMenu({super.key, required this.wordCount, required this.onPick, required this.onClose});

  final int wordCount;
  final ValueChanged<GameMode> onPick;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const BrandMark(size: 30),
            const SizedBox(width: 10),
            Expanded(child: Text('Modo Evaluación', style: AppTheme.heading(24))),
            OutlinedButton(
              onPressed: onClose,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.slate600,
                side: const BorderSide(color: AppColors.slate200),
              ),
              child: const Text('Cerrar'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          wordCount == 0
              ? 'Agrega palabras para iniciar la evaluación.'
              : 'Elige cómo practicar tus $wordCount ${wordCount == 1 ? 'palabra' : 'palabras'}. '
                  'Las preguntas salen al azar.',
          style: const TextStyle(color: AppColors.slate600, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 520;
              final width = twoColumns ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;
              return SingleChildScrollView(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final info in _modes)
                      SizedBox(
                        width: width,
                        child: _ModeCard(
                          info: info,
                          enabled: wordCount >= info.mode.minWords,
                          onTap: () => onPick(info.mode),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.info, required this.enabled, required this.onTap});

  final _ModeInfo info;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final min = info.mode.minWords;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.card - 4),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadii.card - 4),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.card - 4),
              border: Border.all(color: info.color.withValues(alpha: 0.7), width: 2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: info.color,
                    borderRadius: BorderRadius.circular(AppRadii.tile),
                  ),
                  child: Icon(info.icon, color: AppColors.navy, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(info.title, style: AppTheme.heading(19, weight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(
                        enabled ? info.subtitle : 'Necesita al menos $min ${min == 1 ? 'palabra' : 'palabras'}.',
                        style: const TextStyle(fontSize: 13, color: AppColors.slate600, fontWeight: FontWeight.w600, height: 1.25),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
