import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Colores de una fila de la grilla.
class RowColors {
  const RowColors({
    required this.base,
    required this.tint,
    required this.border,
    required this.strong,
    required this.marked,
  });

  /// Genera los tonos de una fila a partir de su color de ficha, igual que el
  /// logo usa un color pleno para la ficha y el azul marino para el resto.
  factory RowColors.fromBase(Color base) {
    return RowColors(
      base: base,
      tint: Color.lerp(base, Colors.white, 0.84)!,
      border: Color.lerp(base, Colors.white, 0.45)!,
      strong: Color.lerp(base, AppColors.navy, 0.38)!,
      marked: base,
    );
  }

  /// Color pleno de la ficha (como las fichas A, birrete y B del logo).
  final Color base;

  /// Fondo de las casillas de la fila.
  final Color tint;

  /// Borde de las casillas sin marcar.
  final Color border;

  /// Tono oscuro de la fila: borde de las marcadas, marca y números.
  final Color strong;

  /// Fondo de las casillas marcadas (la ficha llena).
  final Color marked;
}

/// Una paleta por cada una de las 6 filas. Las tres primeras son las fichas del
/// logo en su orden (azul, ámbar, verde), la cuarta es el naranja de "Learn" y
/// las dos últimas amplían la paleta con el mismo brillo y saturación.
final rowPalette = <RowColors>[
  RowColors.fromBase(AppColors.sky),
  RowColors.fromBase(AppColors.amber),
  RowColors.fromBase(AppColors.teal),
  RowColors.fromBase(AppColors.orange),
  RowColors.fromBase(AppColors.periwinkle),
  RowColors.fromBase(AppColors.rose),
];
