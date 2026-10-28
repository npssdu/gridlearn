/// Tamaños de pantalla de la app: móvil, tablet y web/escritorio.
enum ScreenSize {
  compact(pagePadding: 12, gridGap: 6, cellHeight: 100, cellTextScale: 0.9),
  medium(pagePadding: 24, gridGap: 10, cellHeight: 124, cellTextScale: 1.15),
  expanded(pagePadding: 32, gridGap: 12, cellHeight: 128, cellTextScale: 1.2);

  const ScreenSize({
    required this.pagePadding,
    required this.gridGap,
    required this.cellHeight,
    required this.cellTextScale,
  });

  /// Margen exterior de la página.
  final double pagePadding;

  /// Separación entre casillas de la grilla.
  final double gridGap;

  /// Alto de cada casilla del bingo.
  final double cellHeight;

  /// Factor aplicado a los textos de las casillas.
  final double cellTextScale;

  static const mediumMinWidth = 600.0;
  static const expandedMinWidth = 1024.0;

  /// Ancho máximo del contenido para que no se estire en monitores grandes.
  static const maxContentWidth = 1400.0;

  static ScreenSize of(double width) {
    if (width >= expandedMinWidth) return expanded;
    if (width >= mediumMinWidth) return medium;
    return compact;
  }

  bool get isCompact => this == compact;
  bool get isMedium => this == medium;
  bool get isExpanded => this == expanded;
}
