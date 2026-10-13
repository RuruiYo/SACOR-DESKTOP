import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sacor_desktop/datos/cliente_api.dart';
import 'package:sacor_desktop/datos/memoria/fuente_memoria.dart';
import 'package:sacor_desktop/datos/memoria/semilla_demo.dart';
import 'package:sacor_desktop/datos/modelos/auditoria.dart';
import 'package:sacor_desktop/datos/recurso.dart';
import 'package:sacor_desktop/estado/almacen.dart';
import 'package:sacor_desktop/estado/sesion_estado.dart';

void main() {
  final hoy = DateTime(2026, 10, 11);

  late FuenteMemoria fuente;
  late AlmacenSacor almacen;

  setUp(() async {
    fuente = FuenteMemoria(semillaDemo(hoy));
    almacen = AlmacenSacor(fuente)..idUsuario = 1;
    await almacen.cargarTodo();
  });

  group('almacén', () {
    test('carga todas las tablas', () {
      expect(almacen.listo, isTrue);
      expect(almacen.empleados, isNotEmpty);
      expect(almacen.pesajes, isNotEmpty);
      expect(almacen.contratos, hasLength(6));
    });

    test('crear agrega el registro con su id y deja auditoría', () async {
      final creado = await almacen.crear(Recurso.camiones, {'placa': 'C555-555', 'nombre': 'Camión 3'});
      expect(almacen.camion(creado['idCamion'] as int)?.placa, 'C555-555');
      final ultimo = fuente.auditoria.last;
      expect(ultimo['tablaAfectada'], 'camion');
      expect(ultimo['accion'], 'INSERT');
      expect(ultimo['idEmpleado'], 1);
    });

    test('editar conserva las columnas que la pantalla no toca (código del empleado)', () async {
      final empleado = almacen.empleado(2)!;
      await almacen.actualizar(Recurso.empleados, empleado, empleado.con({'telefono': '7999-0000'}));

      final guardado = (await fuente.listar(Recurso.empleados)).firstWhere((e) => e['idEmpleado'] == 2);
      expect(guardado['telefono'], '7999-0000');
      expect(guardado['codigoEmpleado'], '3851');
      expect(almacen.empleado(2)!.telefono, '7999-0000');
    });

    test('la auditoría no copia el código del empleado', () async {
      final empleado = almacen.empleado(3)!;
      await almacen.actualizar(Recurso.empleados, empleado, empleado.con({'nombre': 'Mario López'}));
      final registro = fuente.auditoria.last;
      expect(registro['accion'], 'UPDATE');
      expect(jsonDecode(registro['valorAnterior'] as String), isNot(contains('codigoEmpleado')));
      expect(jsonDecode(registro['valorNuevo'] as String), isNot(contains('codigoEmpleado')));
    });

    test('eliminar algo con datos relacionados responde 409 y no lo quita', () async {
      final plazaMundo = almacen.cliente(1)!;
      await expectLater(
        almacen.eliminar(Recurso.clientes, plazaMundo),
        throwsA(isA<ApiExcepcion>().having((e) => e.estado, 'estado', 409)),
      );
      expect(almacen.cliente(1), isNotNull);
    });

    test('eliminar un registro libre lo quita', () async {
      final pago = almacen.pagos.first;
      await almacen.eliminar(Recurso.pagos, pago);
      expect(almacen.pagos.any((p) => p.id == pago.id), isFalse);
      expect(fuente.auditoria.last['accion'], 'DELETE');
    });

    test('asignar personal agrega y quita solo lo necesario', () async {
      expect(almacen.personalDeViaje(1).toSet(), {3, 4});
      fuente.registro.clear();

      await almacen.asignarPersonalViaje(1, {4, 6});

      expect(almacen.personalDeViaje(1).toSet(), {4, 6});
      expect(fuente.registro, ['DELETE viaje-extra-empleados/1/3', 'POST viaje-extra-empleados']);
    });

    test('si la API rechaza la auditoría (429), queda en cola y se reenvía después', () async {
      final caprichosa = _FuenteConFallos(semillaDemo(hoy));
      final otro = AlmacenSacor(caprichosa)..idUsuario = 1;
      await otro.cargarTodo();

      caprichosa.fallosRestantes = 1;
      await otro.crear(Recurso.camiones, {'placa': 'C111-111'});
      expect(otro.auditoriasPendientes, 1);
      expect(caprichosa.auditoria, isEmpty);

      await otro.crear(Recurso.camiones, {'placa': 'C222-222'});
      expect(otro.auditoriasPendientes, 0);
      expect(caprichosa.auditoria.map((a) => a['accion']), ['INSERT', 'INSERT']);
    });

    test('limpiar al cerrar sesión borra los datos en memoria', () {
      almacen.limpiar();
      expect(almacen.listo, isFalse);
      expect(almacen.empleados, isEmpty);
    });
  });

  group('sesión', () {
    late SesionEstado sesion;
    late DateTime ahora;

    setUp(() {
      ahora = DateTime(2026, 10, 11, 9);
      sesion = SesionEstado(AlmacenSacor(fuente), reloj: () => ahora);
    });

    test('entra con el código de un administrador activo', () async {
      expect(await sesion.iniciarSesion(' 482913 '), isTrue);
      expect(sesion.usuario?.nombre, 'Carlos Alberto Ramírez');
    });

    test('rechaza códigos de empleados que no son administradores', () async {
      expect(await sesion.iniciarSesion('3851'), isFalse);
      expect(sesion.error, contains('administrador activo'));
      expect(sesion.autenticado, isFalse);
    });

    test('rechaza un código inexistente o vacío', () async {
      expect(await sesion.iniciarSesion('000000'), isFalse);
      expect(await sesion.iniciarSesion('   '), isFalse);
      expect(sesion.error, 'Ingrese su código de empleado.');
    });

    test('bloquea un minuto después de 5 intentos fallidos', () async {
      for (var i = 0; i < SesionEstado.intentosMaximos; i++) {
        await sesion.iniciarSesion('111111');
      }
      expect(await sesion.iniciarSesion('482913'), isFalse);
      expect(sesion.error, contains('Demasiados intentos'));

      ahora = ahora.add(const Duration(minutes: 2));
      expect(await sesion.iniciarSesion('482913'), isTrue);
    });

    test('cerrar sesión vuelve a la pantalla de acceso con aviso', () async {
      await sesion.iniciarSesion('482913');
      sesion.cerrarSesion();
      expect(sesion.autenticado, isFalse);
      expect(sesion.aviso, 'Sesión cerrada correctamente.');
    });
  });
}

class _FuenteConFallos extends FuenteMemoria {
  _FuenteConFallos(super.datos);

  int fallosRestantes = 0;

  @override
  Future<void> registrarAuditoria(NuevaAuditoria registro) async {
    if (fallosRestantes > 0) {
      fallosRestantes--;
      throw const ApiExcepcion(429, 'Demasiadas peticiones. Intenta de nuevo en un minuto.');
    }
    await super.registrarAuditoria(registro);
  }
}
