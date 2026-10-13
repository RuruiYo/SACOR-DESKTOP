import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:sacor_desktop/app.dart';
import 'package:sacor_desktop/configuracion/configuracion.dart';
import 'package:sacor_desktop/datos/memoria/fuente_memoria.dart';
import 'package:sacor_desktop/datos/memoria/semilla_demo.dart';
import 'package:sacor_desktop/datos/recurso.dart';
import 'package:sacor_desktop/estado/navegacion_estado.dart';

void main() {
  final hoy = DateTime(2026, 10, 11);
  late Directory carpetaDte;

  setUpAll(() async {
    Intl.defaultLocale = 'es';
    await initializeDateFormatting('es');
    carpetaDte = await Directory.systemTemp.createTemp('sacor_dte_');
  });

  tearDownAll(() => carpetaDte.delete(recursive: true));

  Future<FuenteMemoria> abrirApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final fuente = FuenteMemoria(semillaDemo(hoy));
    await tester.pumpWidget(SacorApp(
      configuracion: Configuracion(
        urlApi: Uri.parse('http://localhost:5084'),
        llaveApi: '',
        modoDemo: true,
        origen: 'prueba',
        carpetaDte: carpetaDte.path,
      ),
      fuente: fuente,
      reloj: () => hoy,
    ));
    await tester.pumpAndSettle();
    return fuente;
  }

  Future<void> ingresar(WidgetTester tester, String codigo) async {
    await tester.enterText(find.byKey(const Key('campo-codigo')), codigo);
    await tester.tap(find.byKey(const Key('boton-ingresar')));
    await tester.pumpAndSettle();
  }

  testWidgets('un código que no es de administrador no entra', (tester) async {
    await abrirApp(tester);
    await ingresar(tester, '3851');
    expect(find.textContaining('no es un administrador activo'), findsOneWidget);
    expect(find.text('Planilla de empleados'), findsNothing);
  });

  testWidgets('entra con el código y recorre todas las secciones sin errores', (tester) async {
    await abrirApp(tester);
    await ingresar(tester, '482913');

    expect(find.text('Planilla de empleados'), findsWidgets);
    expect(find.text('Ana Gabriela Castillo'), findsOneWidget);

    for (final seccion in Seccion.values.skip(1)) {
      await tester.tap(find.text(seccion.menu).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: seccion.menu);
      expect(find.text(seccion.titulo), findsWidgets, reason: seccion.menu);
    }
  });

  testWidgets('el cuadro de pesaje arma una fila por día y abre el detalle del día', (tester) async {
    await abrirApp(tester);
    await ingresar(tester, '482913');
    await tester.tap(find.text('Pesaje').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('Detalle de Plaza Mundo Apopa · Octubre 2026'), findsOneWidget);
    await tester.tap(find.text('sáb 03/10'));
    await tester.pumpAndSettle();
    expect(find.text('Pesajes del 03/10/2026'), findsOneWidget);
  });

  testWidgets('registra un empleado nuevo con código de 4 dígitos y deja auditoría', (tester) async {
    final fuente = await abrirApp(tester);
    await ingresar(tester, '482913');

    await tester.tap(find.text('Nuevo empleado'));
    await tester.pumpAndSettle();

    Finder campo(String etiqueta) => find.widgetWithText(TextFormField, etiqueta);
    await tester.enterText(campo('Nombre completo *'), 'Sofía Beatriz Navarro');
    await tester.enterText(campo('DUI *'), '01020304-5');
    await tester.enterText(campo('Teléfono'), '7111-2222');
    await tester.enterText(campo(r'Sueldo mensual *'), '540');
    await tester.tap(find.text('Tipo *'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Motorista').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Empleado registrado'), findsOneWidget);
    final empleados = await fuente.listar(Recurso.empleados);
    final nuevo = empleados.firstWhere((e) => e['nombre'] == 'Sofía Beatriz Navarro');
    expect(nuevo['codigoEmpleado'], matches(RegExp(r'^\d{4}$')));
    expect(nuevo['estado'], 'Activo');
    expect(nuevo['idAdministradorRegistro'], 1);
    expect(fuente.auditoria.last['tablaAfectada'], 'empleado');

    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();
    expect(find.text('Sofía Beatriz Navarro'), findsOneWidget);
  });

  testWidgets('el formulario no guarda datos inválidos', (tester) async {
    final fuente = await abrirApp(tester);
    await ingresar(tester, '482913');
    final antes = fuente.registro.length;

    await tester.tap(find.text('Nuevo empleado'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'DUI *'), '123');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Formato 00000000-0.'), findsOneWidget);
    expect(find.text('Este dato es obligatorio.'), findsWidgets);
    expect(fuente.registro.length, antes);
  });

  testWidgets('solicitudes web: cambia el estado de una cotización y atiende una postulación', (tester) async {
    final fuente = await abrirApp(tester);
    await ingresar(tester, '482913');
    await tester.tap(find.text('Solicitudes web').first);
    await tester.pumpAndSettle();

    expect(find.text('María Elena Gómez'), findsOneWidget);
    await tester.tap(find.text('María Elena Gómez'));
    await tester.pumpAndSettle();
    expect(find.text('Cotización #1'), findsOneWidget);
    await tester.tap(find.text('Cambiar estado'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pendiente').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cotizada').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final cotizacion = (await fuente.listar(Recurso.cotizaciones)).firstWhere((c) => c['idCotizacion'] == 1);
    expect(cotizacion['estado'], 'Cotizada');
    expect(cotizacion['idAdministradorAnalista'], 1);

    await tester.tap(find.textContaining('Postulaciones ('));
    await tester.pumpAndSettle();
    expect(find.text('Motorista de volqueta'), findsOneWidget);
    await tester.tap(find.byTooltip('Marcar como atendida').first);
    await tester.pumpAndSettle();

    final atendidas = (await fuente.listar(Recurso.solicitudesPuesto)).where((s) => s['idAdministradorAnalista'] == 1);
    expect(atendidas, hasLength(2));
    expect(fuente.auditoria.last['tablaAfectada'], 'solicitud_puesto_trabajo');
  });
}
