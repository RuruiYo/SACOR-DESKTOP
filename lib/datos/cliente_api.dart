import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiExcepcion implements Exception {
  const ApiExcepcion(this.estado, this.mensaje);

  final int estado;
  final String mensaje;

  bool get sinConexion => estado == 0;

  @override
  String toString() => mensaje;
}

class ClienteApi {
  ClienteApi(this.base, this.llave, {http.Client? cliente}) : _http = cliente ?? http.Client();

  static const tiempoLimite = Duration(seconds: 40);

  final Uri base;
  final String llave;
  final http.Client _http;

  Future<dynamic> get(String ruta, {Map<String, Object?> consulta = const {}}) =>
      _enviar('GET', ruta, consulta: consulta);

  Future<dynamic> post(String ruta, Object cuerpo) => _enviar('POST', ruta, cuerpo: cuerpo);

  Future<dynamic> put(String ruta, Object cuerpo) => _enviar('PUT', ruta, cuerpo: cuerpo);

  Future<dynamic> delete(String ruta) => _enviar('DELETE', ruta);

  Future<dynamic> _enviar(
    String metodo,
    String ruta, {
    Map<String, Object?> consulta = const {},
    Object? cuerpo,
  }) async {
    final parametros = <String, String>{
      for (final entrada in consulta.entries)
        if (entrada.value != null && '${entrada.value}'.isNotEmpty) entrada.key: '${entrada.value}',
    };

    final uri = base.replace(
      path: '${base.path}$ruta',
      queryParameters: parametros.isEmpty ? null : parametros,
    );

    final solicitud = http.Request(metodo, uri)
      ..headers['Accept'] = 'application/json'
      ..headers['X-Api-Key'] = llave;

    if (cuerpo != null) {
      solicitud.headers['Content-Type'] = 'application/json; charset=utf-8';
      solicitud.body = jsonEncode(cuerpo);
    }

    final http.Response respuesta;
    try {
      final enviada = await _http.send(solicitud).timeout(tiempoLimite);
      respuesta = await http.Response.fromStream(enviada).timeout(tiempoLimite);
    } on TimeoutException {
      throw const ApiExcepcion(
        0,
        'El servidor de SACOR no respondió a tiempo. Verifique la conexión e intente de nuevo.',
      );
    } on Object {
      throw const ApiExcepcion(
        0,
        'No se pudo conectar con el servidor de SACOR. Verifique que el servicio esté disponible.',
      );
    }

    final texto = utf8.decode(respuesta.bodyBytes, allowMalformed: true);

    if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) {
      return texto.isEmpty ? null : jsonDecode(texto);
    }

    throw ApiExcepcion(respuesta.statusCode, mensajeDeError(respuesta.statusCode, texto));
  }

  static String mensajeDeError(int estado, String texto) {
    Object? cuerpo;
    try {
      cuerpo = jsonDecode(texto);
    } on FormatException {
      cuerpo = null;
    }
    if (cuerpo is Map<String, dynamic>) {
      final mensaje = cuerpo['mensaje'];
      if (mensaje is String && mensaje.isNotEmpty) return mensaje;

      final errores = cuerpo['errors'] ?? cuerpo['errores'];
      if (errores is Map && errores.isNotEmpty) {
        final primero = errores.values.first;
        if (primero is List && primero.isNotEmpty && primero.first is String) return primero.first as String;
      }
    }

    switch (estado) {
      case 400:
        return 'Los datos enviados no son válidos.';
      case 401:
      case 403:
        return 'La API rechazó la llave de la app de escritorio. Revise "apiKey" en sacor_config.json.';
      case 404:
        return 'El registro ya no existe. Actualice los datos.';
      case 409:
        return 'No se puede completar: el registro tiene datos relacionados.';
      case 429:
        return 'Demasiadas solicitudes seguidas. Espere un minuto e intente de nuevo.';
      default:
        return 'Ocurrió un error en el servidor. Intente de nuevo; si persiste, avise a soporte técnico.';
    }
  }
}
