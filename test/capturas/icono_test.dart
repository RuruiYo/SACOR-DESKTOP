@Tags(['capturas'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sacor_desktop/nucleo/colores.dart';

void main() {
  setUpAll(() async {
    final flutter = Platform.environment['FLUTTER_ROOT']!;
    final cargador = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(
        File('$flutter\\bin\\cache\\artifacts\\material_fonts\\materialicons-regular.otf').readAsBytesSync(),
      )));
    await cargador.load();
  });

  for (final tamano in [16, 24, 32, 48, 64, 256]) {
    testWidgets('icono $tamano', (tester) async {
      tester.view.physicalSize = Size(tamano.toDouble(), tamano.toDouble());
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            decoration: BoxDecoration(
              color: ColoresSacor.verde,
              borderRadius: BorderRadius.circular(tamano * 0.22),
            ),
            child: Center(child: Icon(Icons.eco_outlined, color: ColoresSacor.blanco, size: tamano * 0.66)),
          ),
        ),
      );
      await expectLater(find.byType(Container), matchesGoldenFile('icono/icono_$tamano.png'));
    });
  }
}
