import 'package:flutter/material.dart';

import '../services/grid_exporter.dart';
import '../theme/app_theme.dart';

enum _ExportAction { print, savePdf }

/// Botón "Imprimir / PDF" que exporta solo la grilla (la que captura [gridKey]).
class ExportMenu extends StatelessWidget {
  const ExportMenu({
    super.key,
    required this.gridKey,
    required this.enabled,
    this.compact = false,
  });

  final GlobalKey gridKey;

  /// Sin palabras no hay nada que exportar.
  final bool enabled;
  final bool compact;

  Future<void> _run(BuildContext context, _ExportAction action) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      switch (action) {
        case _ExportAction.print:
          await GridExporter.printGrid(gridKey);
        case _ExportAction.savePdf:
          await GridExporter.savePdf(gridKey);
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo exportar la grilla: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ExportAction>(
      enabled: enabled,
      tooltip: enabled ? 'Imprimir o exportar a PDF' : 'Agrega palabras para exportar',
      position: PopupMenuPosition.under,
      onSelected: (action) => _run(context, action),
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: _ExportAction.print,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.print_outlined),
            title: Text('Imprimir'),
          ),
        ),
        PopupMenuItem(
          value: _ExportAction.savePdf,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.picture_as_pdf_outlined),
            title: Text('Guardar como PDF'),
          ),
        ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.control),
          border: Border.all(color: enabled ? AppColors.brand600 : AppColors.slate300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.print_outlined,
              size: 18,
              color: enabled ? AppColors.brand600 : AppColors.slate400,
            ),
            const SizedBox(width: 6),
            Text(
              compact ? 'PDF' : 'Imprimir / PDF',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: enabled ? AppColors.brand600 : AppColors.slate400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
