import 'dart:convert';

import '../cliente_api.dart';
import '../fuente_datos.dart';
import '../modelos/auditoria.dart';
import '../modelos/json.dart';
import '../recurso.dart';

class FuenteMemoria implements FuenteDatos {
  FuenteMemoria([Map<Recurso, List<Json>> datos = const {}]) {
    for (final recurso in Recurso.values) {
      final filas = [for (final f in datos[recurso] ?? const <Json>[]) _copiar(f)];
      _tablas[recurso] = filas;
      final campo = recurso.campoId;
      _siguiente[recurso] = campo == null
          ? 1
          : filas.fold<int>(0, (maximo, f) => (f[campo] as int) > maximo ? f[campo] as int : maximo) + 1;
    }
  }

  final Map<Recurso, List<Json>> _tablas = {};
  final Map<Recurso, int> _siguiente = {};
  final List<Json> _auditoria = [];

  final List<String> registro = [];

  static const _referencias = <Recurso, List<(Recurso, String)>>{
    Recurso.empleados: [
      (Recurso.pagos, 'idEmpleado'),
      (Recurso.anticipos, 'idEmpleado'),
      (Recurso.rutasEmpleado, 'idEmpleado'),
      (Recurso.pesajes, 'idEmpleadoSubio'),
      (Recurso.pesajes, 'idTecnicoTransporte'),
      (Recurso.viajeExtraEmpleados, 'idEmpleado'),
      (Recurso.serviciosExternos, 'idAdministrador'),
      (Recurso.rutas, 'idAdministrador'),
      (Recurso.viajesExtra, 'idAdministrador'),
      (Recurso.clientes, 'idAdministradorRegistro'),
      (Recurso.empleados, 'idAdministradorRegistro'),
      (Recurso.cotizaciones, 'idAdministradorAnalista'),
      (Recurso.solicitudesPuesto, 'idAdministradorAnalista'),
    ],
    Recurso.usuariosWeb: [(Recurso.cotizaciones, 'idUsuarioWeb'), (Recurso.solicitudesPuesto, 'idUsuarioWeb')],
    Recurso.clientes: [(Recurso.contratos, 'idCliente'), (Recurso.viajesExtra, 'idCliente')],
    Recurso.precios: [(Recurso.contratos, 'idPrecioLugar'), (Recurso.pesajes, 'idPrecioLugar')],
    Recurso.contratos: [(Recurso.pesajes, 'idServicioContrato'), (Recurso.rutas, 'idServicioContrato')],
    Recurso.rutas: [
      (Recurso.contratos, 'idRutaTrabajo'),
      (Recurso.rutasEmpleado, 'idRutaTrabajo'),
      (Recurso.gastosViaje, 'idRutaTrabajo'),
      (Recurso.pesajes, 'idRutaTrabajo'),
    ],
    Recurso.cotizaciones: [(Recurso.contratos, 'idCotizacion')],
    Recurso.camiones: [(Recurso.viajesExtra, 'idCamion'), (Recurso.rutas, 'idCamion')],
    Recurso.viajesExtra: [(Recurso.viajeExtraEmpleados, 'idViajeExtra')],
  };

  static Json _copiar(Json fila) => jsonDecode(jsonEncode(fila)) as Json;

  Json _buscar(Recurso recurso, int id) {
    final campo = recurso.campoId!;
    return _tablas[recurso]!.firstWhere(
      (f) => f[campo] == id,
      orElse: () => throw const ApiExcepcion(404, 'El registro no existe.'),
    );
  }

  @override
  Future<List<Json>> listar(Recurso recurso) async {
    registro.add('GET ${recurso.ruta}');
    return [for (final f in _tablas[recurso]!) _copiar(f)];
  }

  @override
  Future<Json> obtener(Recurso recurso, int id) async => _copiar(_buscar(recurso, id));

  @override
  Future<Json> crear(Recurso recurso, Json datos) async {
    registro.add('POST ${recurso.ruta}');
    final nuevo = _copiar(datos)..remove('id');
    final campo = recurso.campoId;
    if (campo != null) {
      final id = _siguiente[recurso]!;
      _siguiente[recurso] = id + 1;
      nuevo[campo] = id;
    } else if (_tablas[recurso]!.any(
        (f) => f['idViajeExtra'] == nuevo['idViajeExtra'] && f['idEmpleado'] == nuevo['idEmpleado'])) {
      throw const ApiExcepcion(409, 'El empleado ya esta asignado a ese viaje.');
    }
    nuevo.removeWhere((_, valor) => valor == null);
    _tablas[recurso]!.add(nuevo);
    return _copiar(nuevo);
  }

  @override
  Future<void> actualizar(Recurso recurso, int id, Json datos) async {
    registro.add('PUT ${recurso.ruta}/$id');
    final existente = _buscar(recurso, id);
    final campo = recurso.campoId!;
    final nuevo = _copiar(datos)
      ..remove('id')
      ..[campo] = id
      ..removeWhere((_, valor) => valor == null);
    final filas = _tablas[recurso]!;
    filas[filas.indexOf(existente)] = nuevo;
  }

  @override
  Future<void> eliminar(Recurso recurso, int id) async {
    registro.add('DELETE ${recurso.ruta}/$id');
    final existente = _buscar(recurso, id);
    for (final (hija, campo) in _referencias[recurso] ?? const <(Recurso, String)>[]) {
      if (_tablas[hija]!.any((f) => f[campo] == id && !identical(f, existente))) {
        throw const ApiExcepcion(409, 'No se puede eliminar: el registro tiene datos relacionados.');
      }
    }
    _tablas[recurso]!.remove(existente);
  }

  @override
  Future<void> quitarPersonalDeViaje(int idViajeExtra, int idEmpleado) async {
    registro.add('DELETE viaje-extra-empleados/$idViajeExtra/$idEmpleado');
    _tablas[Recurso.viajeExtraEmpleados]!
        .removeWhere((f) => f['idViajeExtra'] == idViajeExtra && f['idEmpleado'] == idEmpleado);
  }

  @override
  Future<Json> generarViajesCotizacion(int idCotizacion, Json datos) async {
    registro.add('POST cotizaciones/$idCotizacion/generar-viajes');
    final cotizacion = _buscar(Recurso.cotizaciones, idCotizacion);
    if (cotizacion['estado'] != 'Aprobada') {
      throw const ApiExcepcion(409, 'Solo se pueden generar viajes de una cotización aprobada.');
    }
    if (_tablas[Recurso.contratos]!.any((c) => c['idCotizacion'] == idCotizacion)) {
      throw const ApiExcepcion(409, 'Esta cotización ya tiene su contrato y viajes.');
    }

    final usuario = _buscar(Recurso.usuariosWeb, cotizacion['idUsuarioWeb'] as int);
    final tipoServicio = (cotizacion['tipoServicio'] as String?) ?? 'Servicio';
    final lugar = (datos['lugar'] as String?) ?? 'Sin lugar';
    final destino = datos['destino'] as String?;
    final texto = destino == null || destino == lugar ? lugar : '$lugar → $destino';
    final cantidad = datos['cantidad'] as int;
    final inicio = DateTime.parse(datos['fechaInicio'] as String);
    final frecuencia = datos['frecuencia'] as String;

    final clientes = _tablas[Recurso.clientes]!;
    final existente = clientes.where((c) => c['dui'] == usuario['dui']).firstOrNull;
    final cliente = existente ??
        await crear(Recurso.clientes, {
          'nombre': usuario['nombre'],
          'tipo': 'Natural',
          'dui': usuario['dui'],
          'telefono': usuario['telefono'],
          'correo': usuario['email'],
          'idAdministradorRegistro': datos['idAdministrador'],
        });

    final precios = _tablas[Recurso.precios]!;
    final precioExistente =
        precios.where((p) => p['tipo'] == tipoServicio && p['lugar'] == lugar).firstOrNull;
    final precio = precioExistente ??
        await crear(Recurso.precios, {'tipo': tipoServicio, 'lugar': lugar, 'precio': datos['precio']});

    final viajes = <Json>[];
    for (var i = 0; i < cantidad; i++) {
      final fecha = switch (frecuencia) {
        'Diaria' => inicio.add(Duration(days: i)),
        'Semanal' => inicio.add(Duration(days: 7 * i)),
        'Quincenal' => inicio.add(Duration(days: 14 * i)),
        'Mensual' => DateTime(inicio.year, inicio.month + i, inicio.day),
        _ => inicio,
      };
      final dia = fecha.toIso8601String().substring(0, 10);
      viajes.add(await crear(Recurso.rutas, {
        'idAdministrador': datos['idAdministrador'],
        'destino': '[$dia] $texto',
        'tipo': '$tipoServicio ${i + 1}/$cantidad',
      }));
    }

    final contrato = await crear(Recurso.contratos, {
      'idRutaTrabajo': viajes.first['idRutaTrabajo'],
      'idCliente': cliente['idCliente'],
      'idPrecioLugar': precio['idPrecioLugar'],
      'fecha': inicio.toIso8601String().substring(0, 10),
      'tipoTransportaje': tipoServicio,
      'idCotizacion': idCotizacion,
      'observacion': 'Cotización web #$idCotizacion: $cantidad viaje(s).',
    });
    for (final viaje in viajes) {
      final fila = _buscar(Recurso.rutas, viaje['idRutaTrabajo'] as int);
      fila['idServicioContrato'] = contrato['idServicioContrato'];
      viaje['idServicioContrato'] = contrato['idServicioContrato'];
    }

    return {
      'idCotizacion': idCotizacion,
      'idCliente': cliente['idCliente'],
      'clienteNuevo': existente == null,
      'idPrecioLugar': precio['idPrecioLugar'],
      'precioExistente': precioExistente != null,
      'precioUsado': precio['precio'],
      'idServicioContrato': contrato['idServicioContrato'],
      'viajes': viajes,
      'mensaje': 'Se generaron $cantidad viaje(s).',
    };
  }

  @override
  Future<void> registrarAuditoria(NuevaAuditoria registro) async {
    _auditoria.add({
      ...registro.aJson(),
      'idAuditoria': _auditoria.length + 1,
      'fechaHora': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<PaginaAuditoria> consultarAuditoria({required int pagina, required int tamano, String? tabla}) async {
    final filtrados = _auditoria.reversed.where((a) => tabla == null || a['tablaAfectada'] == tabla).toList();
    return PaginaAuditoria.desdeJson({
      'pagina': pagina,
      'tamano': tamano,
      'total': filtrados.length,
      'datos': filtrados.skip((pagina - 1) * tamano).take(tamano).toList(),
    });
  }

  List<Json> get auditoria => List.unmodifiable(_auditoria);
}
