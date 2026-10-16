@Tags(['capturas'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:sacor_desktop/app.dart';
import 'package:sacor_desktop/configuracion/configuracion.dart';
import 'package:sacor_desktop/datos/memoria/fuente_memoria.dart';
import 'package:sacor_desktop/datos/memoria/semilla_demo.dart';

Future<void> _cargarFuente(String familia, List<String> rutas) async {
  final cargador = FontLoader(familia);
  for (final ruta in rutas) {
    final archivo = File(ruta);
    if (archivo.existsSync()) {
      cargador.addFont(Future.value(ByteData.sublistView(Uint8List.fromList(archivo.readAsBytesSync()))));
    }
  }
  await cargador.load();
}

void main() {
  setUpAll(() async {
    Intl.defaultLocale = 'es';
    await initializeDateFormatting('es');
    final fuentes = Platform.environment['WINDIR'] ?? r'C:\Windows';
    await _cargarFuente('Segoe UI', [
      '$fuentes\\Fonts\\segoeui.ttf',
      '$fuentes\\Fonts\\seguisb.ttf',
      '$fuentes\\Fonts\\segoeuib.ttf',
    ]);
    final flutter = Platform.environment['FLUTTER_ROOT'] ??
        File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.parent.path;
    await _cargarFuente('MaterialIcons', ['$flutter\\bin\\cache\\artifacts\\material_fonts\\materialicons-regular.otf']);
  });

  final hoy = DateTime(2026, 10, 11);

  Future<void> abrir(WidgetTester tester, {Size tamano = const Size(1440, 900), bool entrar = true}) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(SacorApp(
      configuracion: Configuracion(
        urlApi: Uri.parse('http://servidor-sacor:5084'),
        llaveApi: '',
        modoDemo: true,
        origen: 'captura',
      ),
      fuente: FuenteMemoria(semillaDemo(hoy)),
      reloj: () => hoy,
    ));
    await tester.pumpAndSettle();
    if (entrar) {
      await tester.enterText(find.byKey(const Key('campo-codigo')), '482913');
      await tester.tap(find.byKey(const Key('boton-ingresar')));
      await tester.pumpAndSettle();
    }
  }

  Future<void> capturar(WidgetTester tester, String nombre) =>
      expectLater(find.byType(MaterialApp), matchesGoldenFile('pantallas/$nombre.png'));

  Future<void> ir(WidgetTester tester, String menu) async {
    final texto = find.text(menu);
    await tester.tap(texto.evaluate().isEmpty ? find.byTooltip(menu) : texto.first);
    await tester.pumpAndSettle();
  }

  testWidgets('login', (tester) async {
    await abrir(tester, entrar: false);
    await capturar(tester, '01_login');
  });

  testWidgets('empleados con detalle', (tester) async {
    await abrir(tester, tamano: const Size(1440, 1400));
    await tester.tap(find.text('Kevin Alexander Flores').first);
    await tester.pumpAndSettle();
    await capturar(tester, '02_empleados');
  });

  testWidgets('nuevo empleado', (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Nuevo empleado'));
    await tester.pumpAndSettle();
    await capturar(tester, '03_nuevo_empleado');
  });

  testWidgets('pesaje', (tester) async {
    await abrir(tester, tamano: const Size(1440, 1700));
    await ir(tester, 'Pesaje');
    await capturar(tester, '04_pesaje');
  });

  testWidgets('pesaje por etapas', (tester) async {
    await abrir(tester, tamano: const Size(1600, 1000));
    await ir(tester, 'Pesaje');
    await tester.tap(find.text('Plaza Mundo Apopa').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plaza Mundo Soyapango').last);
    await tester.pumpAndSettle();
    await capturar(tester, '05_pesaje_etapas');
  });

  testWidgets('movimiento contable', (tester) async {
    await abrir(tester, tamano: const Size(1440, 1500));
    await ir(tester, 'Movimiento contable');
    await capturar(tester, '06_movimiento');
  });

  testWidgets('movimiento en ventana angosta', (tester) async {
    await abrir(tester, tamano: const Size(1100, 2000));
    await ir(tester, 'Movimiento contable');
    await capturar(tester, '07_movimiento_angosto');
  });

  testWidgets('clientes, contratos y precios', (tester) async {
    await abrir(tester, tamano: const Size(1440, 900));
    await ir(tester, 'Clientes y contratos');
    await capturar(tester, '08_clientes');
    await tester.tap(find.text('Contratos'));
    await tester.pumpAndSettle();
    await capturar(tester, '09_contratos');
  });

  testWidgets('servicios externos', (tester) async {
    await abrir(tester, tamano: const Size(1440, 1000));
    await ir(tester, 'Servicios externos');
    await capturar(tester, '10_servicios_externos');
  });

  testWidgets('salidas', (tester) async {
    await abrir(tester, tamano: const Size(1440, 1300));
    await ir(tester, 'Salidas y camiones');
    await capturar(tester, '11_salidas');
  });

  testWidgets('viajes extra', (tester) async {
    await abrir(tester, tamano: const Size(1440, 900));
    await ir(tester, 'Viajes extra');
    await capturar(tester, '12_viajes');
  });

  testWidgets('solicitudes web', (tester) async {
    await abrir(tester, tamano: const Size(1440, 1000));
    await ir(tester, 'Solicitudes web');
    await capturar(tester, '14_solicitudes_web');
  });
}
