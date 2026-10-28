import 'package:flutter/material.dart';

import '../layout/breakpoints.dart';
import '../theme/app_theme.dart';
import 'brand_logo.dart';

/// Marca (icono + palabra GridLearn), menú de cuenta ([account]), título de la
/// pantalla y el botón que abre el modo evaluación.
class HeaderBar extends StatelessWidget {
  const HeaderBar({
    super.key,
    required this.size,
    required this.onStartQuiz,
    this.account,
  });

  final ScreenSize size;
  final VoidCallback onStartQuiz;
  final Widget? account;

  @override
  Widget build(BuildContext context) {
    final compact = size.isCompact;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: BrandLockup(markSize: compact ? 32 : 38, fontSize: compact ? 24 : 28),
              ),
            ),
            const Spacer(),
            ?account,
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text('Bingo de Vocabulario', style: AppTheme.heading(compact ? 20 : 24)),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: onStartQuiz,
              icon: const Icon(Icons.emoji_events_outlined, size: 18),
              label: Text(compact ? 'Evaluación' : 'Comenzar Evaluación'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
