import 'cliente_api.dart';
import 'modelos/auditoria.dart';
import 'modelos/json.dart';
import 'recurso.dart';

abstract class FuenteDatos {
  Future<List<Json>> listar(Recurso recurso);

  Future<Json> obtener(Recurso recurso, int id);

  Future<Json> crear(Recurso recurso, Json datos);

  Future<void> actualizar(Recurso recurso, int id, Json datos);

  Future<void> eliminar(Recurso recurso, int id);

  Future<void> quitarPersonalDeViaje(int idViajeExtra, int idEmpleado);

  Future<Json> generarViajesCotizacion(int idCotizacion, Json datos);

  Future<void> registrarAuditoria(NuevaAuditoria registro);

  Future<PaginaAuditoria> consultarAuditoria({required int pagina, required int tamano, String? tabla});
}

class FuenteApi implements FuenteDatos {
  FuenteApi(this._api);

  final ClienteApi _api;

  static const tamanoPagina = 200;

  @override
  Future<List<Json>> listar(Recurso recurso) async {
    final todos = <Json>[];
    var pagina = 1;
    while (true) {
      final respuesta = await _api.get('/api/${recurso.ruta}', consulta: {'pagina': pagina, 'tamano': tamanoPagina});
      final datos = (respuesta['datos'] as List).cast<Json>();
      todos.addAll(datos);
      final total = respuesta['total'] as int;
      if (datos.isEmpty || todos.length >= total) return todos;
      pagina++;
    }
  }

  @override
  Future<Json> obtener(Recurso recurso, int id) async =>
      (await _api.get('/api/${recurso.ruta}/$id')) as Json;

  @override
  Future<Json> crear(Recurso recurso, Json datos) async =>
      (await _api.post('/api/${recurso.ruta}', _limpiar(datos))) as Json;

  @override
  Future<void> actualizar(Recurso recurso, int id, Json datos) => _api.put('/api/${recurso.ruta}/$id', _limpiar(datos));

  @override
  Future<void> eliminar(Recurso recurso, int id) => _api.delete('/api/${recurso.ruta}/$id');

  @override
  Future<void> quitarPersonalDeViaje(int idViajeExtra, int idEmpleado) =>
      _api.delete('/api/${Recurso.viajeExtraEmpleados.ruta}/$idViajeExtra/$idEmpleado');

  @override
  Future<Json> generarViajesCotizacion(int idCotizacion, Json datos) async =>
      (await _api.post('/api/cotizaciones/$idCotizacion/generar-viajes', datos)) as Json;

  @override
  Future<void> registrarAuditoria(NuevaAuditoria registro) => _api.post('/api/auditoria', registro.aJson());

  @override
  Future<PaginaAuditoria> consultarAuditoria({required int pagina, required int tamano, String? tabla}) async {
    final respuesta = await _api.get('/api/auditoria', consulta: {'pagina': pagina, 'tamano': tamano, 'tabla': tabla});
    return PaginaAuditoria.desdeJson(respuesta as Json);
  }

  static Json _limpiar(Json datos) => {...datos}..remove('id');
}
