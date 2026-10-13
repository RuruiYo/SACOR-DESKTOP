import 'dart:math';

import '../../nucleo/texto_fechado.dart';
import '../modelos/json.dart';
import '../recurso.dart';

Map<Recurso, List<Json>> semillaDemo(DateTime hoy, {int semilla = 11}) {
  final azar = Random(semilla);
  final datos = {for (final r in Recurso.values) r: <Json>[]};

  final empleados = [
    (1, '482913', 'Carlos Alberto Ramírez', '01234567-8', '7012-3456', 900, 'AdministradorOperativo', 'Activo'),
    (2, '3851', 'José Luis Martínez', '02345678-9', '7123-4567', 630, 'Tecnico', 'Activo'),
    (3, '4172', 'Mario Ernesto López', '03456789-0', '7234-5678', 750, 'Motorista', 'Activo'),
    (4, '5293', 'Kevin Alexander Flores', '04567891-2', '7345-6789', 540, 'Motorista', 'Activo'),
    (5, '6314', 'Luis Fernando Hernández', '05678912-3', '7456-7890', 540, 'Tecnico', 'Activo'),
    (6, '7435', 'Ana Gabriela Castillo', '06789123-4', '7567-8901', 750, 'Motorista', 'Activo'),
    (7, '8556', 'Roberto Carlos Mejía', '07891234-5', '7678-9012', 630, 'Tecnico', 'Activo'),
    (8, '9677', 'Daniel Antonio Pérez', '08912345-6', '7789-0123', 300, 'Ayudante', 'Inactivo'),
  ];
  for (final (id, codigo, nombre, dui, telefono, sueldo, tipo, estado) in empleados) {
    datos[Recurso.empleados]!.add({
      'idEmpleado': id,
      'codigoEmpleado': codigo,
      'nombre': nombre,
      'dui': dui,
      'telefono': telefono,
      'sueldo': sueldo,
      'fechaIngreso': fechaJson(DateTime(2021 + id % 4, 1 + id, 10)),
      'estado': estado,
      'tipo': tipo,
      if (id != 1) 'idAdministradorRegistro': 1,
    });
  }

  datos[Recurso.clientes]!.addAll([
    {
      'idCliente': 1,
      'nombre': 'Plaza Mundo',
      'tipo': 'Juridico',
      'nit': '0614-010101-101-1',
      'nrc': '123456-7',
      'telefono': '2277-1000',
      'correo': 'administracion@plazamundo.test',
      'nombreComercial': 'Plaza Mundo',
      'giro': 'Arrendamiento de locales comerciales',
      'idAdministradorRegistro': 1,
    },
    {
      'idCliente': 2,
      'nombre': 'Metrocentro',
      'tipo': 'Juridico',
      'nit': '0614-020202-102-2',
      'telefono': '2257-2000',
      'idAdministradorRegistro': 1,
    },
    {'idCliente': 3, 'nombre': 'Juan Antonio Pérez', 'tipo': 'Natural', 'dui': '04567890-1', 'idAdministradorRegistro': 1},
  ]);

  final precios = [
    (1, 'Orgánico', 'Plaza Mundo Apopa', 45.5, 850.0),
    (2, 'Sólido', 'Plaza Mundo Apopa', 70.0, 3300.0),
    (3, 'Orgánico', 'Plaza Mundo Soyapango', 45.5, 1200.0),
    (4, 'Sólido', 'Plaza Mundo Soyapango', 70.0, 4500.0),
    (5, 'Orgánico', 'Plaza Mundo Usulután', 60.5, 1900.0),
    (6, 'Sólido', 'Plaza Mundo Usulután', 80.0, 6000.0),
  ];
  for (final (id, tipo, lugar, precio, _) in precios) {
    datos[Recurso.precios]!.add({
      'idPrecioLugar': id,
      'tipo': tipo,
      'lugar': lugar,
      'precio': precio,
      'fechaModificacion': fechaJson(DateTime(hoy.year, 1, 2)),
    });
  }

  datos[Recurso.camiones]!.addAll([
    {'idCamion': 1, 'placa': 'C123-456', 'nombre': 'Camión 1', 'tipo': 'Volteo', 'estado': 'Activo', 'dueno': 'SACOR'},
    {'idCamion': 2, 'placa': 'C987-654', 'nombre': 'Camión 2', 'tipo': 'Compactador', 'estado': 'Activo', 'dueno': 'SACOR'},
  ]);

  final inicio = DateTime(hoy.year, hoy.month - 4, 1);
  final dias = [
    for (var d = inicio; !d.isAfter(hoy); d = DateTime(d.year, d.month, d.day + 1)) d,
  ];

  final primeraSalida = <String, int>{};
  void salida(DateTime dia, String lugar, double gasolina, List<int> personal) {
    final id = datos[Recurso.rutas]!.length + 1;
    datos[Recurso.rutas]!.add({
      'idRutaTrabajo': id,
      'idAdministrador': 1,
      'destino': TextoFechado.escribir(dia, lugar),
      'dineroGasolina': gasolina,
      'tipo': 'Recolección',
    });
    for (final e in personal) {
      datos[Recurso.rutasEmpleado]!.add(
          {'idRutaEmpleado': datos[Recurso.rutasEmpleado]!.length + 1, 'idRutaTrabajo': id, 'idEmpleado': e});
    }
    primeraSalida.putIfAbsent(lugar, () => id);
  }

  for (final dia in dias) {
    if (azar.nextDouble() < 0.5) salida(dia, 'Plaza Mundo Apopa', [22.0, 25.0, 27.0][azar.nextInt(3)], [2, 3, 4]);
    if (azar.nextDouble() < 0.8) salida(dia, 'Plaza Mundo Usulután', 30 + azar.nextInt(20).toDouble(), [7, 6, 5]);
    if (dia.day == 1 || dia.day == 15) salida(dia, 'Plaza Mundo Soyapango', 15, [2, 3, 5]);
  }

  for (final (id, _, lugar, _, _) in precios) {
    datos[Recurso.contratos]!.add({
      'idServicioContrato': id,
      'idRutaTrabajo': primeraSalida[lugar] ?? 1,
      'idCliente': 1,
      'idPrecioLugar': id,
      'tipoTransportaje': 'Camión volteo',
      'fecha': fechaJson(DateTime(hoy.year, 1, 15)),
    });
  }

  for (final dia in dias) {
    final crecimiento = 1 + (dia.difference(inicio).inDays / 400);
    for (final (id, _, lugar, _, base) in precios) {
      if (azar.nextDouble() < 0.07) continue;
      final etapas = lugar.contains('Soyapango') ? ['4ta Etapa', '1ra Etapa'] : <String?>[null];
      for (final etapa in etapas) {
        final libras = (base / etapas.length * crecimiento * (0.85 + azar.nextDouble() * 0.3) * 5).round() / 5;
        datos[Recurso.pesajes]!.add({
          'idPesaje': datos[Recurso.pesajes]!.length + 1,
          'idServicioContrato': id,
          'idEmpleadoSubio': 1,
          'idTecnicoTransporte': lugar.contains('Usulután') ? 7 : 2,
          'idPrecioLugar': id,
          'fecha': fechaJson(dia),
          'pesoTotal': libras,
          'etapa': ?etapa,
        });
      }
    }
  }

  for (var mes = DateTime(inicio.year, inicio.month); mes.isBefore(DateTime(hoy.year, hoy.month)); mes = DateTime(mes.year, mes.month + 1)) {
    for (final dia in [15, DateTime(mes.year, mes.month + 1, 0).day]) {
      for (final (id, _, _, _, _, sueldo, _, estado) in empleados) {
        if (estado != 'Activo') continue;
        datos[Recurso.pagos]!.add({
          'idPago': datos[Recurso.pagos]!.length + 1,
          'idEmpleado': id,
          'fecha': fechaJson(DateTime(mes.year, mes.month, dia)),
          'cantidad': sueldo / 2,
          'descuento': id == 4 && dia == 15 ? 40 : 0,
          'observacion': dia == 15 ? 'Primera quincena' : 'Segunda quincena',
        });
      }
    }
    datos[Recurso.anticipos]!.add({
      'idAnticipo': datos[Recurso.anticipos]!.length + 1,
      'idEmpleado': 4,
      'fecha': fechaJson(DateTime(mes.year, mes.month, 5)),
      'cantidad': 40,
      'observacion': 'Anticipo de quincena',
    });

    for (final mitad in ['1-15', '16-fin']) {
      final viajes = 42 + azar.nextInt(10);
      datos[Recurso.serviciosExternos]!.add({
        'idServicioExt': datos[Recurso.serviciosExternos]!.length + 1,
        'idAdministrador': 1,
        'nombre': TextoFechado.escribir(mes, 'Góndola $mitad ($viajes viajes)', soloMes: true),
        'cantidadPago': viajes * 15,
        'direccion': 'Góndola municipal',
      });
    }
  }
  datos[Recurso.serviciosExternos]!.add({
    'idServicioExt': datos[Recurso.serviciosExternos]!.length + 1,
    'idAdministrador': 1,
    'nombre': 'Mantenimiento de báscula',
    'cantidadPago': 85,
  });

  final viajes = [
    (1, 1, 2, TextoFechado.escribir(DateTime(hoy.year, hoy.month - 1), 'Transporte extra andamios', soloMes: true), 45, 1, [3, 4]),
    (2, 3, 1, TextoFechado.escribir(DateTime(hoy.year, hoy.month), 'Retiro de ripio', soloMes: true), 35, 3, [6, 5]),
    (3, 2, 2, 'Viaje extra', 50, 1, [3]),
  ];
  for (final (id, cliente, camion, tipo, precio, cantidad, personal) in viajes) {
    datos[Recurso.viajesExtra]!.add({
      'idViajeExtra': id,
      'idCliente': cliente,
      'idAdministrador': 1,
      'idCamion': camion,
      'tipo': tipo,
      'precio': precio,
      'pagoMonto': precio * cantidad,
      'cantidad': cantidad,
    });
    for (final e in personal) {
      datos[Recurso.viajeExtraEmpleados]!.add({'idViajeExtra': id, 'idEmpleado': e});
    }
  }

  final personasWeb = [
    (1, 'María Elena Gómez', '05432109-8', '7012-9988', 'maria.gomez@correo.test'),
    (2, 'Constructora El Pino', '06543210-9', '2245-1100', 'compras@elpino.test'),
    (3, 'Óscar Armando Ruiz', '07654321-0', '7888-1234', null),
    (4, 'Wendy Carolina Sosa', '08765432-1', null, 'wendy.sosa@correo.test'),
  ];
  for (final (id, nombre, dui, telefono, correo) in personasWeb) {
    datos[Recurso.usuariosWeb]!.add({
      'idUsuarioWeb': id,
      'nombre': nombre,
      'dui': dui,
      'telefono': ?telefono,
      'email': ?correo,
    });
  }
  final cotizaciones = [
    (1, 1, 'Transporte de desecho organico', 'Pendiente', null, 1,
        'Modalidad: servicio puntual | Recoleccion: Colonia Escalón | Destino: Relleno | Volumen: 2 viajes | Poda de árboles'),
    (2, 2, 'Transporte de ripio', 'EnRevision', 1, 3,
        'Modalidad: contrato recurrente | Recoleccion: Santa Tecla | Duracion: 3 meses | Frecuencia: semanal | Viajes: 12'),
    (3, 2, 'Transporte de materiales de construccion', 'Aprobada', 1, 12,
        'Modalidad: servicio puntual | Recoleccion: Antiguo Cuscatlán | Fecha estimada: 2026-10-20'),
    (4, 3, 'Transporte de ripio', 'Rechazada', 1, 20, 'Modalidad: servicio puntual | Volumen: medio viaje'),
  ];
  for (final (id, persona, servicio, estado, analista, diasAtras, descripcion) in cotizaciones) {
    datos[Recurso.cotizaciones]!.add({
      'idCotizacion': id,
      'idUsuarioWeb': persona,
      'idAdministradorAnalista': ?analista,
      'fecha': fechaJson(hoy.subtract(Duration(days: diasAtras))),
      'estado': estado,
      'tipoServicio': servicio,
      'descripcion': descripcion,
    });
  }
  final postulaciones = [
    (1, 3, 'Motorista de volqueta', null, 2),
    (2, 4, 'Tecnico de reciclaje', null, 4),
    (3, 1, 'Personal de clasificacion', 1, 15),
  ];
  for (final (id, persona, puesto, analista, diasAtras) in postulaciones) {
    datos[Recurso.solicitudesPuesto]!.add({
      'idSolicitud': id,
      'idUsuarioWeb': persona,
      'idAdministradorAnalista': ?analista,
      'tipoPuesto': puesto,
      'fecha': fechaJson(hoy.subtract(Duration(days: diasAtras))),
    });
  }

  return datos;
}
