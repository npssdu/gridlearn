import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const _fileName = 'GridLearn-grilla.pdf';

/// Imagen de la grilla tal como se ve en pantalla.
class GridCapture {
  const GridCapture(this.png, this.width, this.height);

  final Uint8List png;
  final int width;
  final int height;
}

/// Imprime o guarda en PDF únicamente la grilla del bingo.
///
/// Se captura el propio widget (con sus colores por fila y casillas marcadas)
/// y se coloca como imagen en la página, así el resultado coincide con lo que
/// se ve en pantalla.
class GridExporter {
  /// [pixelRatio] alto para que el texto salga nítido al imprimir.
  static Future<GridCapture> capture(GlobalKey boundaryKey, {double pixelRatio = 4}) async {
    final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('La grilla todavía no está lista para exportar.');
    }
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('No se pudo generar la imagen de la grilla.');
      return GridCapture(data.buffer.asUint8List(), image.width, image.height);
    } finally {
      image.dispose();
    }
  }

  static Future<Uint8List> buildPdf(GridCapture grid, PdfPageFormat format) {
    // Hoja vertical u horizontal según la forma de la grilla.
    final page = grid.width > grid.height ? format.landscape : format.portrait;
    final doc = pw.Document(title: 'GridLearn - Grilla de bingo');
    final image = pw.MemoryImage(grid.png);
    doc.addPage(
      pw.Page(
        pageFormat: page,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
      ),
    );
    return doc.save();
  }

  /// Abre el cuadro de impresión (en web, el del navegador, que también
  /// permite "Guardar como PDF").
  static Future<void> printGrid(GlobalKey boundaryKey) async {
    final grid = await capture(boundaryKey);
    await Printing.layoutPdf(
      name: _fileName,
      format: PdfPageFormat.a4,
      onLayout: (format) => buildPdf(grid, format),
    );
  }

  /// Descarga el PDF (web y escritorio) o abre el menú de compartir (móvil).
  static Future<void> savePdf(GlobalKey boundaryKey) async {
    final grid = await capture(boundaryKey);
    final bytes = await buildPdf(grid, PdfPageFormat.a4);
    await Printing.sharePdf(bytes: bytes, filename: _fileName);
  }
}
