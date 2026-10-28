import 'package:flutter/material.dart';

import '../../game/answer_checker.dart';
import '../../theme/app_theme.dart';
import 'game_effects.dart';

/// Resultado de la respuesta con el mensaje ("¡Excelente!", "La respuesta era: …")
/// y el botón para continuar.
class FeedbackBanner extends StatelessWidget {
  const FeedbackBanner({
    super.key,
    required this.verdict,
    required this.message,
    required this.onContinue,
    this.continueLabel = 'Continuar',
  });

  final Verdict verdict;
  final String message;
  final VoidCallback onContinue;
  final String continueLabel;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    switch (verdict) {
      case Verdict.correct:
        color = AppColors.teal;
        icon = Icons.check_circle_rounded;
      case Verdict.almost:
        color = AppColors.amber;
        icon = Icons.thumb_up_alt_rounded;
      case Verdict.wrong:
        color = AppColors.danger;
        icon = Icons.cancel_rounded;
    }
    return PopIn(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadii.card - 6),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onContinue,
              autofocus: true,
              style: FilledButton.styleFrom(
                backgroundColor: verdict == Verdict.wrong ? AppColors.navy : color,
                foregroundColor: verdict == Verdict.wrong ? Colors.white : AppColors.navy,
              ),
              child: Text(continueLabel),
            ),
          ],
        ),
      ),
    );
  }
}
