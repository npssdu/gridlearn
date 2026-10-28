import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tarjeta blanca translúcida con sombra azul, como las secciones de la web.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child, this.padding = 16});

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.10),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
