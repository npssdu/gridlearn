import 'package:flutter/material.dart';

import '../layout/breakpoints.dart';
import '../logic/grid_builder.dart';
import '../state/vocab_controller.dart';
import '../theme/app_theme.dart';
import '../theme/row_colors.dart';

/// Grilla del bingo de 5 columnas x 6 filas. El alto de las casillas y el
/// tamaño del texto dependen del [ScreenSize].
///
/// Si se pasa [captureKey], la grilla queda dentro de un `RepaintBoundary`
/// para poder exportarla tal cual se ve (impresión / PDF).
class BingoGrid extends StatelessWidget {
  const BingoGrid({
    super.key,
    required this.controller,
    required this.size,
    this.captureKey,
  });

  final VocabController controller;
  final ScreenSize size;
  final GlobalKey? captureKey;

  @override
  Widget build(BuildContext context) {
    final grid = controller.grid;
    final title = controller.title.trim();
    final gridView = GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: grid.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridColumns,
        mainAxisSpacing: size.gridGap,
        crossAxisSpacing: size.gridGap,
        mainAxisExtent: size.cellHeight,
      ),
      itemBuilder: (context, i) {
        final slot = grid[i];
        return _BingoCell(
          slot: slot,
          active: controller.isMarked(slot.slotId),
          size: size,
          onTap: slot.isPlaceholder
              ? null
              : () => controller.toggleMarked(slot.slotId),
        );
      },
    );

    return RepaintBoundary(
      key: captureKey,
      // Fondo blanco propio para que la captura no salga con huecos transparentes.
      child: ColoredBox(
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(size.gridGap),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // El título (opcional) forma parte de lo que se exporta.
              if (title.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: size.gridGap + 4),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTheme.heading(20 * size.cellTextScale),
                  ),
                ),
              gridView,
            ],
          ),
        ),
      ),
    );
  }
}

class _BingoCell extends StatelessWidget {
  const _BingoCell({
    required this.slot,
    required this.active,
    required this.size,
    required this.onTap,
  });

  final GridSlot slot;
  final bool active;
  final ScreenSize size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scale = size.cellTextScale;
    final colors = rowPalette[slot.row % rowPalette.length];
    final Color background;
    final Color border;
    final double borderWidth;
    if (slot.isPlaceholder) {
      // Celda vacía: solo el contorno, como las celdas vacías del logo.
      background = Colors.transparent;
      border = colors.border.withValues(alpha: 0.75);
      borderWidth = 2;
    } else if (active) {
      // Marcada: la ficha llena con el color pleno de su fila.
      background = colors.marked;
      border = colors.marked;
      borderWidth = 2;
    } else {
      background = colors.tint;
      border = colors.border;
      borderWidth = 1.5;
    }
    final radius = BorderRadius.circular(AppRadii.tile);

    return Semantics(
      button: !slot.isPlaceholder,
      selected: active,
      label: '${slot.english}, ${slot.spanish}',
      child: Material(
        color: background,
        elevation: active ? 3 : 0,
        shadowColor: AppColors.navy.withValues(alpha: 0.3),
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          hoverColor: colors.marked.withValues(alpha: 0.35),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: border, width: borderWidth),
            ),
            padding: EdgeInsets.all(size.isCompact ? 4 : 8),
            child: slot.isPlaceholder
                ? _EmptyCell(number: slot.index + 1, color: colors.strong, scale: scale)
                : Stack(
                    children: [
                      Positioned.fill(child: _content(scale)),
                      if (active)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Icon(Icons.check_circle, size: 14 * scale, color: AppColors.navy),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _content(double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FitLines(
          text: slot.english.toUpperCase(),
          style: TextStyle(
            fontSize: 11 * scale,
            fontWeight: FontWeight.w800,
            height: 1.15,
            color: AppColors.slate900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          slot.phonetic.isEmpty ? '-' : slot.phonetic,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10 * scale,
            fontStyle: FontStyle.italic,
            color: AppColors.navySoft,
          ),
        ),
        const Spacer(),
        _FitLines(
          text: slot.spanish,
          style: TextStyle(
            fontSize: 10 * scale,
            fontWeight: FontWeight.w500,
            height: 1.2,
            color: AppColors.slate700,
          ),
        ),
      ],
    );
  }
}

/// Casilla libre: muestra solo su número, para ver dónde irá la próxima palabra.
class _EmptyCell extends StatelessWidget {
  const _EmptyCell({required this.number, required this.color, required this.scale});

  final int number;
  final Color color;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Text(
        '$number',
        style: TextStyle(
          fontSize: 11 * scale,
          fontWeight: FontWeight.w700,
          color: color.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

/// Muestra hasta dos líneas, una por palabra, reduciendo la letra cuando una
/// palabra no cabe en el ancho de la casilla (evita cortes en pantallas chicas).
class _FitLines extends StatelessWidget {
  const _FitLines({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final lines = words.length <= 2
        ? words
        : [words.first, words.skip(1).join(' ')];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(line, maxLines: 1, style: style),
            ),
          ),
      ],
    );
  }
}
