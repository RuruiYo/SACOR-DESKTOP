import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sacor_desktop/datos/cliente_api.dart';
import 'package:sacor_desktop/datos/fuente_datos.dart';
import 'package:sacor_desktop/datos/modelos/auditoria.dart';
import 'package:sacor_desktop/datos/recurso.dart';

void main() {
  final base = Uri.parse('http://servidor:5084');

  test('lista todas las páginas con la llave en X-Api-Key', () async {
    final pedidas = <Uri>[];
    final cliente = MockClient((solicitud) async {
      pedidas.add(solicitud.url);
      expect(solicitud.headers['X-Api-Key'], 'llave-de-prueba');
      final pagina = int.parse(solicitud.url.queryParameters['pagina']!);
      final datos = pagina == 1
          ? List.generate(200, (i) => {'idPesaje': i + 1})
          : List.generate(50, (i) => {'idPesaje': 201 + i});
      return http.Response(jsonEncode({'pagina': pagina, 'tamano': 200, 'total': 250, 'datos': datos}), 200);
    });

    final fuente = FuenteApi(ClienteApi(base, 'llave-de-prueba', cliente: cliente));
    final pesajes = await fuente.listar(Recurso.pesajes);

    expect(pesajes, hasLength(250));
    expect(pedidas.map((u) => u.path).toSet(), {'/api/pesajes'});
    expect(pedidas.map((u) => u.queryParameters['tamano']).toSet(), {'200'});
  });

  test('PUT envía el registro completo, sin la propiedad calculada "id"', () async {
    late Map<String, dynamic> cuerpo;
    final cliente = MockClient((solicitud) async {
      expect(solicitud.method, 'PUT');
      expect(solicitud.url.path, '/api/empleados/7');
      cuerpo = jsonDecode(solicitud.body) as Map<String, dynamic>;
      return http.Response('', 204);
    });
    final fuente = FuenteApi(ClienteApi(base, 'k', cliente: cliente));

    await fuente.actualizar(Recurso.empleados, 7, {'id': 7, 'idEmpleado': 7, 'codigoEmpleado': '1234', 'nombre': 'Ana'});

    expect(cuerpo, {'idEmpleado': 7, 'codigoEmpleado': '1234', 'nombre': 'Ana'});
  });

  test('baja del personal de un viaje usa la ruta de clave compuesta', () async {
    final cliente = MockClient((solicitud) async {
      expect(solicitud.method, 'DELETE');
      expect(solicitud.url.path, '/api/viaje-extra-empleados/3/9');
      return http.Response('', 204);
    });
    await FuenteApi(ClienteApi(base, 'k', cliente: cliente)).quitarPersonalDeViaje(3, 9);
  });

  test('registra auditoría con los nombres de la API', () async {
    late Map<String, dynamic> cuerpo;
    final cliente = MockClient((solicitud) async {
      expect(solicitud.url.path, '/api/auditoria');
      cuerpo = jsonDecode(solicitud.body) as Map<String, dynamic>;
      return http.Response('{}', 201);
    });
    await FuenteApi(ClienteApi(base, 'k', cliente: cliente)).registrarAuditoria(const NuevaAuditoria(
      idEmpleado: 1,
      tabla: 'pesaje',
      idRegistro: '10',
      accion: 'INSERT',
      valorNuevo: '{}',
      detalle: 'SACOR Desktop',
    ));
    expect(cuerpo['tablaAfectada'], 'pesaje');
    expect(cuerpo['idRegistro'], '10');
    expect(cuerpo['accion'], 'INSERT');
  });

  group('mensajes de error', () {
    Future<ApiExcepcion> error(int estado, String cuerpo) async {
      final cliente = MockClient((_) async => http.Response(cuerpo, estado));
      try {
        await ClienteApi(base, 'k', cliente: cliente).get('/api/clientes');
      } on ApiExcepcion catch (e) {
        return e;
      }
      fail('Se esperaba un error');
    }

    test('usa el mensaje de la API', () async {
      final e = await error(409, '{"estado":409,"mensaje":"No se puede eliminar: el registro tiene datos relacionados."}');
      expect(e.estado, 409);
      expect(e.mensaje, contains('datos relacionados'));
    });

    test('usa la validación de ASP.NET (errors)', () async {
      final e = await error(400, '{"title":"One or more validation errors occurred.","errors":{"Nombre":["El nombre es obligatorio."]}}');
      expect(e.mensaje, 'El nombre es obligatorio.');
    });

    test('explica una llave rechazada', () async {
      final e = await error(403, '{"estado":403}');
      expect(e.mensaje, contains('apiKey'));
    });

    test('sin conexión', () async {
      final cliente = MockClient((_) async => throw http.ClientException('sin red'));
      expect(
        () => ClienteApi(base, 'k', cliente: cliente).get('/api/clientes'),
        throwsA(isA<ApiExcepcion>().having((e) => e.sinConexion, 'sinConexion', isTrue)),
      );
    });
  });
}
