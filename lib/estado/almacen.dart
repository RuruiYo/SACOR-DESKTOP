import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../datos/cliente_api.dart';
import '../datos/fuente_datos.dart';
import '../datos/modelos/auditoria.dart';
import '../datos/modelos/entidades.dart';
import '../datos/modelos/json.dart';
import '../datos/recurso.dart';
import '../nucleo/dinero.dart';

class AlmacenSacor extends ChangeNotifier {
  AlmacenSacor(this.fuente);

  final FuenteDatos fuente;

  final Map<Recurso, List<Json>> _tablas = {};
  final Map<Recurso, Object> _vistas = {};
  final Map<Recurso, Map<int, Object>> _indices = {};

  bool _cargando = false;
  String? _error;
  DateTime? _actualizado;

  final List<NuevaAuditoria> _auditoriasPendientes = [];
  bool _enviandoAuditorias = false;

  int? idUsuario;

  bool get cargando => _cargando;
  String? get error => _error;
  DateTime? get actualizado => _actualizado;
  bool get listo => _actualizado != null;
  int get auditoriasPendientes => _auditoriasPendientes.length;

  List<T> _vista<T>(Recurso recurso, T Function(Json) crear) =>
      (_vistas[recurso] ??= List<T>.unmodifiable((_tablas[recurso] ?? const []).map(crear))) as List<T>;

  T? _buscar<T extends Entidad>(Recurso recurso, List<T> lista, int id) {
    final indice = _indices[recurso] ??= {for (final e in lista) e.id: e};
    return indice[id] as T?;
  }

  List<Empleado> get empleados => _vista(Recurso.empleados, Empleado.new);
  List<Cliente> get clientes => _vista(Recurso.clientes, Cliente.new);
  List<Pago> get pagos => _vista(Recurso.pagos, Pago.new);
  List<Anticipo> get anticipos => _vista(Recurso.anticipos, Anticipo.new);
  List<ServicioExterno> get serviciosExternos => _vista(Recurso.serviciosExternos, ServicioExterno.new);
  List<PrecioLugar> get precios => _vista(Recurso.precios, PrecioLugar.new);
  List<Contrato> get contratos => _vista(Recurso.contratos, Contrato.new);
  List<Pesaje> get pesajes => _vista(Recurso.pesajes, Pesaje.new);
  List<Ruta> get rutas => _vista(Recurso.rutas, Ruta.new);
  List<RutaEmpleado> get rutasEmpleado => _vista(Recurso.rutasEmpleado, RutaEmpleado.new);
  List<Camion> get camiones => _vista(Recurso.camiones, Camion.new);
  List<ViajeExtra> get viajesExtra => _vista(Recurso.viajesExtra, ViajeExtra.new);
  List<UsuarioWeb> get usuariosWeb => _vista(Recurso.usuariosWeb, UsuarioWeb.new);
  List<Cotizacion> get cotizaciones => _vista(Recurso.cotizaciones, Cotizacion.new);
  List<SolicitudPuesto> get solicitudesPuesto => _vista(Recurso.solicitudesPuesto, SolicitudPuesto.new);
  List<GastoViaje> get gastosViaje => _vista(Recurso.gastosViaje, GastoViaje.new);
  List<ViajeExtraEmpleado> get personalViajes =>
      _vista(Recurso.viajeExtraEmpleados, ViajeExtraEmpleado.desdeJson);

  Empleado? empleado(int id) => _buscar(Recurso.empleados, empleados, id);
  Cliente? cliente(int id) => _buscar(Recurso.clientes, clientes, id);
  PrecioLugar? precio(int id) => _buscar(Recurso.precios, precios, id);
  Contrato? contrato(int id) => _buscar(Recurso.contratos, contratos, id);
  Ruta? ruta(int id) => _buscar(Recurso.rutas, rutas, id);
  Camion? camion(int id) => _buscar(Recurso.camiones, camiones, id);
  UsuarioWeb? usuarioWeb(int id) => _buscar(Recurso.usuariosWeb, usuariosWeb, id);

  String nombreEmpleado(int id) => empleado(id)?.nombre ?? 'Empleado #$id';
  String nombreCliente(int id) => cliente(id)?.nombre ?? 'Cliente #$id';

  List<int> personalDeViaje(int idViaje) =>
      [for (final p in personalViajes) if (p.idViajeExtra == idViaje) p.idEmpleado];

  Dinero gastosDeRuta(int idRuta) =>
      Dinero.sumar([for (final g in gastosViaje) if (g.idRuta == idRuta) g.monto]);

  List<int> personalDeRuta(int idRuta) => [for (final r in rutasEmpleado) if (r.idRuta == idRuta) r.idEmpleado];

  Future<List<Empleado>> cargarEmpleados() async {
    _poner(Recurso.empleados, await fuente.listar(Recurso.empleados));
    return empleados;
  }

  Future<void> cargarTodo() async {
    if (_cargando) return;
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final recursos = Recurso.values;
      final resultados = await Future.wait(recursos.map(fuente.listar));
      for (var i = 0; i < recursos.length; i++) {
        _poner(recursos[i], resultados[i]);
      }
      _actualizado = DateTime.now();
      await _enviarAuditorias();
    } on ApiExcepcion catch (e) {
      _error = e.mensaje;
    } on Object catch (e) {
      debugPrint('Error al cargar datos: $e');
      _error = 'No se pudieron cargar los datos. Intente de nuevo.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  void limpiar() {
    _tablas.clear();
    _vistas.clear();
    _indices.clear();
    _actualizado = null;
    _error = null;
    idUsuario = null;
    notifyListeners();
  }

  void _poner(Recurso recurso, List<Json> filas) {
    _tablas[recurso] = filas;
    _vistas.remove(recurso);
    _indices.remove(recurso);
  }

  void _modificar(Recurso recurso, void Function(List<Json> filas) cambio) {
    final filas = [...?_tablas[recurso]];
    cambio(filas);
    _poner(recurso, filas);
    notifyListeners();
  }

  Future<Json> crear(Recurso recurso, Json datos, {String? detalle}) async {
    final creado = await fuente.crear(recurso, datos);
    _modificar(recurso, (filas) => filas.add(creado));
    await _auditar(recurso, _idDe(recurso, creado), 'INSERT', null, creado, detalle);
    return creado;
  }

  Future<void> actualizar(Recurso recurso, Entidad anterior, Json datos, {String? detalle}) async {
    await fuente.actualizar(recurso, anterior.id, datos);

    final guardado = datos;

    _modificar(recurso, (filas) {
      final i = filas.indexWhere((f) => _idDe(recurso, f) == '${anterior.id}');
      if (i >= 0) filas[i] = guardado;
    });
    await _auditar(recurso, '${anterior.id}', 'UPDATE', anterior.json, guardado, detalle);
  }

  Future<void> eliminar(Recurso recurso, Entidad registro, {String? detalle}) async {
    await fuente.eliminar(recurso, registro.id);
    _modificar(recurso, (filas) => filas.removeWhere((f) => _idDe(recurso, f) == '${registro.id}'));
    await _auditar(recurso, '${registro.id}', 'DELETE', registro.json, null, detalle);
  }

  Future<void> asignarPersonalViaje(int idViaje, Set<int> empleados) async {
    final actuales = personalDeViaje(idViaje).toSet();
    const recurso = Recurso.viajeExtraEmpleados;

    for (final idEmpleado in actuales.difference(empleados)) {
      await fuente.quitarPersonalDeViaje(idViaje, idEmpleado);
      _modificar(recurso, (filas) => filas.removeWhere(
          (f) => f['idViajeExtra'] == idViaje && f['idEmpleado'] == idEmpleado));
      await _auditar(recurso, '$idViaje-$idEmpleado', 'DELETE',
          {'idViajeExtra': idViaje, 'idEmpleado': idEmpleado}, null, 'Personal quitado del viaje');
    }
    for (final idEmpleado in empleados.difference(actuales)) {
      final datos = {'idViajeExtra': idViaje, 'idEmpleado': idEmpleado};
      final creado = await fuente.crear(recurso, datos);
      _modificar(recurso, (filas) => filas.add(creado));
      await _auditar(recurso, '$idViaje-$idEmpleado', 'INSERT', null, datos, 'Personal asignado al viaje');
    }
  }

  Contrato? contratoDeCotizacion(int idCotizacion) =>
      contratos.where((c) => c.idCotizacion == idCotizacion).firstOrNull;

  List<Ruta> viajesDeContrato(int idContrato) =>
      [for (final r in rutas) if (r.idContrato == idContrato) r]
        ..sort((a, b) => (a.fecha ?? DateTime(1900)).compareTo(b.fecha ?? DateTime(1900)));

  List<Ruta> viajesDeCotizacion(int idCotizacion) {
    final contrato = contratoDeCotizacion(idCotizacion);
    return contrato == null ? [] : viajesDeContrato(contrato.id);
  }

  Future<Json> generarViajesCotizacion(int idCotizacion, Json datos) async {
    final resultado = await fuente.generarViajesCotizacion(idCotizacion, {...datos, 'idAdministrador': idUsuario});
    const recargar = [Recurso.rutas, Recurso.clientes, Recurso.precios, Recurso.contratos];
    final tablas = await Future.wait(recargar.map(fuente.listar));
    for (var i = 0; i < recargar.length; i++) {
      _poner(recargar[i], tablas[i]);
    }
    notifyListeners();
    return resultado;
  }

  Future<void> asignarPersonalRuta(int idRuta, Set<int> empleados) async {
    final actuales = [for (final r in rutasEmpleado) if (r.idRuta == idRuta) r];
    for (final asignacion in actuales.where((a) => !empleados.contains(a.idEmpleado))) {
      await eliminar(Recurso.rutasEmpleado, asignacion, detalle: 'Personal quitado de la salida');
    }
    final yaAsignados = actuales.map((a) => a.idEmpleado).toSet();
    for (final idEmpleado in empleados.difference(yaAsignados)) {
      await crear(Recurso.rutasEmpleado, {'idRutaTrabajo': idRuta, 'idEmpleado': idEmpleado},
          detalle: 'Personal asignado a la salida');
    }
  }

  String _idDe(Recurso recurso, Json fila) {
    final campo = recurso.campoId;
    if (campo == null) return '${fila['idViajeExtra']}-${fila['idEmpleado']}';
    return '${fila[campo]}';
  }

  Future<void> _auditar(Recurso recurso, String id, String accion, Json? antes, Json? despues, String? detalle) async {
    _auditoriasPendientes.add(NuevaAuditoria(
      idEmpleado: idUsuario,
      tabla: recurso.tabla,
      idRegistro: id,
      accion: accion,
      valorAnterior: _paraAuditoria(antes),
      valorNuevo: _paraAuditoria(despues),
      detalle: 'SACOR Desktop${detalle == null ? '' : ': $detalle'}',
    ));
    await _enviarAuditorias();
  }

  Future<void> _enviarAuditorias() async {
    if (_enviandoAuditorias) return;
    _enviandoAuditorias = true;
    try {
      while (_auditoriasPendientes.isNotEmpty) {
        await fuente.registrarAuditoria(_auditoriasPendientes.first);
        _auditoriasPendientes.removeAt(0);
      }
    } on Object catch (e) {
      debugPrint('Auditoría pendiente (${_auditoriasPendientes.length}): $e');
    } finally {
      _enviandoAuditorias = false;
    }
  }

  static String? _paraAuditoria(Json? valores) {
    if (valores == null) return null;
    final copia = {...valores}
      ..remove('codigoEmpleado')
      ..remove('id');
    return jsonEncode(copia);
  }
}
