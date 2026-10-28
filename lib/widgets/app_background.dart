import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Fondo de todas las pantallas: gris muy claro con un halo azul arriba a la
/// izquierda y otro naranja abajo a la derecha.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.slate50),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -1.0),
            radius: 0.9,
            colors: [Color(0x2943B0EB), Color(0x0043B0EB)],
          ),
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(1.0, 1.0),
              radius: 1.0,
              colors: [Color(0x1AFF7512), Color(0x00FF7512)],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
