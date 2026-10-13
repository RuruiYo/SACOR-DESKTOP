@Tags(['api'])
@Timeout(Duration(minutes: 3))
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sacor_desktop/datos/cliente_api.dart';
import 'package:sacor_desktop/datos/fuente_datos.dart';
import 'package:sacor_desktop/datos/modelos/auditoria.dart';
import 'package:sacor_desktop/datos/modelos/entidades.dart';
import 'package:sacor_desktop/datos/modelos/json.dart';
import 'package:sacor_desktop/datos/recurso.dart';
import 'package:sacor_desktop/estado/almacen.dart';
import 'package:sacor_desktop/nucleo/texto_fechado.dart';

void main() {
  final archivoLlave = File('herramientas/llave_local.txt');
  final llave = archivoLlave.existsSync() ? archivoLlave.readAsStringSync().trim() : '';
  final url = Uri.parse(Platform.environment['SACOR_API_URL'] ?? 'http://localhost:5084');

  late AlmacenSacor almacen;
  late FuenteDatos fuente;

  Future<void> esperarCupo() async {
    for (var intento = 0; intento < 20; intento++) {
      try {
        await fuente.obtener(Recurso.empleados, 1);
        return;
      } on ApiExcepcion catch (e) {
        if (e.estado != 429) rethrow;
        await Future<void>.delayed(const Duration(seconds: 5));
      }
    }
  }

  setUpAll(() async {
    if (llave.isEmpty) fail('Falta herramientas/llave_local.txt: corra api_local.ps1 primero.');
    if (url.host != 'localhost' && url.host != '127.0.0.1') fail('Esta prueba solo corre contra una API local.');
    fuente = _ConReintento(FuenteApi(ClienteApi(url, llave)));
    almacen = AlmacenSacor(fuente)..idUsuario = 1;
    await esperarCupo();
    await almacen.cargarTodo();
    if (almacen.error != null) fail('No se pudo cargar la API local: ${almacen.error}');
  });

  final hoy = DateTime.now();

  setUp(esperarCupo);

  Future<T> ciclo<T extends Entidad>({
    required Recurso recurso,
    required Json alta,
    required Json Function(T actual) cambios,
    required List<T> Function() lista,
    required void Function(T editado) verificar,
  }) async {
    final creado = await almacen.crear(recurso, alta, detalle: 'Prueba de integración');
    final id = creado[recurso.campoId] as int;
    final actual = lista().firstWhere((e) => e.id == id);

    await almacen.actualizar(recurso, actual, actual.con(cambios(actual)), detalle: 'Prueba de integración');
    final editado = lista().firstWhere((e) => e.id == id);
    verificar(editado);
    return editado;
  }

  Future<void> borrar(Recurso recurso, Entidad registro) async {
    await almacen.eliminar(recurso, registro, detalle: 'Prueba de integración');
    expect(almacen.auditoriasPendientes, 0, reason: 'la API debió recibir la auditoría');
  }

  test('cliente', () async {
    final c = await ciclo<Cliente>(
      recurso: Recurso.clientes,
      alta: {'nombre': 'Cliente de prueba', 'tipo': 'Juridico', 'nit': '0614-123456-123-1', 'idAdministradorRegistro': 1},
      cambios: (_) => {'telefono': '7444-5555', 'nombreComercial': 'Prueba'},
      lista: () => almacen.clientes,
      verificar: (c) {
        expect(c.telefono, '7444-5555');
        expect(c.nit, '0614-123456-123-1');
      },
    );
    await borrar(Recurso.clientes, c);
  });

  test('empleado: la edición conserva el código de acceso', () async {
    final codigo = '${9000 + hoy.millisecondsSinceEpoch % 1000}';
    final e = await ciclo<Empleado>(
      recurso: Recurso.empleados,
      alta: {
        'codigoEmpleado': codigo,
        'nombre': 'Empleado de prueba',
        'dui': '99887766-5',
        'sueldo': 400,
        'fechaIngreso': fechaJson(DateTime(2026, 1, 5)),
        'estado': 'Activo',
        'tipo': 'Motorista',
        'idAdministradorRegistro': 1,
      },
      cambios: (_) => {'telefono': '7333-2222', 'estado': 'Suspendido'},
      lista: () => almacen.empleados,
      verificar: (e) {
        expect(e.estado, 'Suspendido');
        expect(e.codigo, codigo);
      },
    );
    await borrar(Recurso.empleados, e);
  });

  test('pago y anticipo', () async {
    final p = await ciclo<Pago>(
      recurso: Recurso.pagos,
      alta: {'idEmpleado': 4, 'fecha': fechaJson(DateTime(2026, 10, 10)), 'cantidad': 270, 'descuento': 0},
      cambios: (_) => {'descuento': 20, 'observacion': 'Prueba'},
      lista: () => almacen.pagos,
      verificar: (p) => expect(p.neto.comoDouble, 250),
    );
    await borrar(Recurso.pagos, p);

    final a = await ciclo<Anticipo>(
      recurso: Recurso.anticipos,
      alta: {'idEmpleado': 4, 'fecha': fechaJson(DateTime(2026, 10, 10)), 'cantidad': 30},
      cambios: (_) => {'cantidad': 35},
      lista: () => almacen.anticipos,
      verificar: (a) => expect(a.cantidad.comoDouble, 35),
    );
    await borrar(Recurso.anticipos, a);
  });

  test('servicio externo con el mes en el nombre', () async {
    final s = await ciclo<ServicioExterno>(
      recurso: Recurso.serviciosExternos,
      alta: {
        'idAdministrador': 1,
        'nombre': TextoFechado.escribir(DateTime(2026, 10), 'Góndola de prueba', soloMes: true),
        'cantidadPago': 150,
      },
      cambios: (_) => {'cantidadPago': 165.5, 'direccion': 'Góndola municipal'},
      lista: () => almacen.serviciosExternos,
      verificar: (s) {
        expect(s.fecha, DateTime(2026, 10));
        expect(s.nombre, 'Góndola de prueba');
        expect(s.monto.comoDouble, 165.5);
      },
    );
    await borrar(Recurso.serviciosExternos, s);
  });

  test('precio, salida con personal, contrato y pesaje', () async {
    final precio = await ciclo<PrecioLugar>(
      recurso: Recurso.precios,
      alta: {'tipo': 'Orgánico', 'lugar': 'Lugar de prueba', 'precio': 50},
      cambios: (_) => {'precio': 52.25},
      lista: () => almacen.precios,
      verificar: (p) => expect(p.precio.comoDouble, 52.25),
    );

    final ruta = await ciclo<Ruta>(
      recurso: Recurso.rutas,
      alta: {'idAdministrador': 1, 'destino': TextoFechado.escribir(DateTime(2026, 10, 10), 'Lugar de prueba'), 'dineroGasolina': 20},
      cambios: (_) => {'dineroGasolina': 25, 'tipo': 'Recolección'},
      lista: () => almacen.rutas,
      verificar: (r) {
        expect(r.fecha, DateTime(2026, 10, 10));
        expect(r.gasolina.comoDouble, 25);
      },
    );
    await almacen.asignarPersonalRuta(ruta.id, {2, 3});
    expect(almacen.personalDeRuta(ruta.id).toSet(), {2, 3});

    final contrato = await ciclo<Contrato>(
      recurso: Recurso.contratos,
      alta: {'idCliente': 1, 'idPrecioLugar': precio.id, 'idRutaTrabajo': ruta.id, 'fecha': fechaJson(DateTime(2026, 10, 1))},
      cambios: (_) => {'tipoTransportaje': 'Camión volteo'},
      lista: () => almacen.contratos,
      verificar: (c) => expect(c.tipoTransportaje, 'Camión volteo'),
    );

    final pesaje = await ciclo<Pesaje>(
      recurso: Recurso.pesajes,
      alta: {
        'idServicioContrato': contrato.id,
        'idEmpleadoSubio': 1,
        'idTecnicoTransporte': 2,
        'idPrecioLugar': precio.id,
        'fecha': fechaJson(DateTime(2026, 10, 10)),
        'pesoTotal': 1100,
        'etapa': '4ta Etapa',
      },
      cambios: (_) => {'pesoTotal': 1210.4},
      lista: () => almacen.pesajes,
      verificar: (p) {
        expect(p.libras, 1210.4);
        expect(p.etapa, '4ta Etapa');
      },
    );

    await expectLater(
      almacen.eliminar(Recurso.contratos, contrato),
      throwsA(isA<ApiExcepcion>().having((e) => e.estado, 'estado', 409)),
    );

    await borrar(Recurso.pesajes, pesaje);
    await borrar(Recurso.contratos, contrato);
    await almacen.asignarPersonalRuta(ruta.id, {});
    await borrar(Recurso.rutas, ruta);
    await borrar(Recurso.precios, precio);
  });

  test('camión y viaje extra con personal', () async {
    final camion = await ciclo<Camion>(
      recurso: Recurso.camiones,
      alta: {'placa': 'PRB-${hoy.millisecondsSinceEpoch % 10000}', 'nombre': 'Camión de prueba'},
      cambios: (_) => {'estado': 'En taller', 'dueno': 'SACOR'},
      lista: () => almacen.camiones,
      verificar: (c) => expect(c.dueno, 'SACOR'),
    );

    final viaje = await ciclo<ViajeExtra>(
      recurso: Recurso.viajesExtra,
      alta: {
        'idCliente': 1,
        'idAdministrador': 1,
        'idCamion': camion.id,
        'tipo': TextoFechado.escribir(DateTime(2026, 10), 'Viaje de prueba', soloMes: true),
        'precio': 40,
        'cantidad': 2,
        'pagoMonto': 80,
      },
      cambios: (_) => {'cantidad': 3, 'pagoMonto': 120},
      lista: () => almacen.viajesExtra,
      verificar: (v) {
        expect(v.total.comoDouble, 120);
        expect(v.fecha, DateTime(2026, 10));
      },
    );
    await almacen.asignarPersonalViaje(viaje.id, {3, 4});
    await almacen.asignarPersonalViaje(viaje.id, {4});
    expect(almacen.personalDeViaje(viaje.id), [4]);

    await almacen.asignarPersonalViaje(viaje.id, {});
    await borrar(Recurso.viajesExtra, viaje);
    await borrar(Recurso.camiones, camion);
  });

  test('cotización y postulación web: estado, atención y baja', () async {
    final persona = await almacen.crear(Recurso.usuariosWeb, {
      'nombre': 'Persona web de prueba',
      'dui': '01928374-6',
      'telefono': '7555-6666',
    }, detalle: 'Prueba de integración');
    final idPersona = persona['idUsuarioWeb'] as int;

    final cotizacion = await ciclo<Cotizacion>(
      recurso: Recurso.cotizaciones,
      alta: {
        'idUsuarioWeb': idPersona,
        'fecha': fechaJson(DateTime(2026, 10, 10)),
        'estado': 'Pendiente',
        'tipoServicio': 'Transporte de ripio',
        'descripcion': 'Modalidad: servicio puntual | Volumen: 1 viaje',
      },
      cambios: (_) => {'estado': 'EnRevision', 'idAdministradorAnalista': 1},
      lista: () => almacen.cotizaciones,
      verificar: (c) {
        expect(c.estado, 'EnRevision');
        expect(c.idAnalista, 1);
        expect(c.detalles, ['Modalidad: servicio puntual', 'Volumen: 1 viaje']);
      },
    );

    final solicitud = await ciclo<SolicitudPuesto>(
      recurso: Recurso.solicitudesPuesto,
      alta: {'idUsuarioWeb': idPersona, 'tipoPuesto': 'Motorista de volqueta', 'fecha': fechaJson(DateTime(2026, 10, 10))},
      cambios: (_) => {'idAdministradorAnalista': 1},
      lista: () => almacen.solicitudesPuesto,
      verificar: (s) => expect(s.atendida, isTrue),
    );
    await almacen.actualizar(Recurso.solicitudesPuesto, solicitud, solicitud.con({'idAdministradorAnalista': null}));
    final releida = await fuente.obtener(Recurso.solicitudesPuesto, solicitud.id);
    expect(releida['idAdministradorAnalista'], isNull);

    await borrar(Recurso.cotizaciones, cotizacion);
    await borrar(Recurso.solicitudesPuesto, almacen.solicitudesPuesto.firstWhere((s) => s.id == solicitud.id));
    await borrar(Recurso.usuariosWeb, almacen.usuarioWeb(idPersona)!);
  });

  test('lo creado en las pruebas ya no está en la base', () async {
    final clientes = await fuente.listar(Recurso.clientes);
    final camiones = await fuente.listar(Recurso.camiones);
    expect(clientes.where((c) => c['nombre'] == 'Cliente de prueba'), isEmpty);
    expect(camiones.where((c) => '${c['placa']}'.startsWith('PRB-')), isEmpty);
  });

  test('la auditoría quedó registrada sin el código de empleado', () async {
    final pagina = await fuente.consultarAuditoria(pagina: 1, tamano: 200);
    final mias = pagina.datos.where((a) => (a.detalle ?? '').contains('Prueba de integración')).toList();
    expect(mias, isNotEmpty);
    expect(mias.every((a) => a.idEmpleado == 1), isTrue);
    expect(mias.any((a) => (a.valorNuevo ?? '').contains('codigoEmpleado')), isFalse);
  });
}

class _ConReintento implements FuenteDatos {
  _ConReintento(this._fuente);

  final FuenteDatos _fuente;

  Future<T> _intentar<T>(Future<T> Function() operacion) async {
    for (var intento = 0;; intento++) {
      try {
        return await operacion();
      } on ApiExcepcion catch (e) {
        if (e.estado != 429 || intento >= 20) rethrow;
        await Future<void>.delayed(const Duration(seconds: 5));
      }
    }
  }

  @override
  Future<List<Json>> listar(Recurso recurso) => _intentar(() => _fuente.listar(recurso));

  @override
  Future<Json> obtener(Recurso recurso, int id) => _intentar(() => _fuente.obtener(recurso, id));

  @override
  Future<Json> crear(Recurso recurso, Json datos) => _intentar(() => _fuente.crear(recurso, datos));

  @override
  Future<void> actualizar(Recurso recurso, int id, Json datos) => _intentar(() => _fuente.actualizar(recurso, id, datos));

  @override
  Future<void> eliminar(Recurso recurso, int id) => _intentar(() => _fuente.eliminar(recurso, id));

  @override
  Future<void> quitarPersonalDeViaje(int idViajeExtra, int idEmpleado) =>
      _intentar(() => _fuente.quitarPersonalDeViaje(idViajeExtra, idEmpleado));

  @override
  Future<Json> generarViajesCotizacion(int idCotizacion, Json datos) =>
      _intentar(() => _fuente.generarViajesCotizacion(idCotizacion, datos));

  @override
  Future<void> registrarAuditoria(NuevaAuditoria registro) => _intentar(() => _fuente.registrarAuditoria(registro));

  @override
  Future<PaginaAuditoria> consultarAuditoria({required int pagina, required int tamano, String? tabla}) =>
      _intentar(() => _fuente.consultarAuditoria(pagina: pagina, tamano: tamano, tabla: tabla));
}
