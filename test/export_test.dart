import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridlearn/layout/breakpoints.dart';
import 'package:gridlearn/services/grid_exporter.dart';
import 'package:gridlearn/theme/app_theme.dart';
import 'package:gridlearn/widgets/bingo_grid.dart';
import 'package:pdf/pdf.dart';
import 'fakes.dart';

void main() {
  testWidgets('captura la grilla y la convierte en un PDF válido', (tester) async {
    final controller = await makeController();
    controller.setTitle('Pascua 2026');
    controller.addWord(english: 'Sun', spanish: 'Sol');
    controller.addWord(english: 'Egg', spanish: 'Huevo');

    final key = GlobalKey();
    tester.view.physicalSize = const Size(820, 1180);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(useGoogleFonts: false),
        home: Scaffold(
          body: SingleChildScrollView(
            child: BingoGrid(controller: controller, size: ScreenSize.medium, captureKey: key),
          ),
        ),
      ),
    );

    final capture = await tester.runAsync(() => GridExporter.capture(key, pixelRatio: 1));
    expect(capture, isNotNull);
    expect(capture!.width, greaterThan(0));
    expect(capture.height, greaterThan(capture.width ~/ 2));
    // Firma de un archivo PNG.
    expect(capture.png.sublist(1, 4), ascii.encode('PNG'));

    final pdf = await tester.runAsync(() => GridExporter.buildPdf(capture, PdfPageFormat.a4));
    expect(ascii.decode(pdf!.sublist(0, 5)), '%PDF-');
  });
}
