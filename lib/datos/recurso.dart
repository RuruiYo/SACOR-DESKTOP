enum Recurso {
  empleados('empleados', 'idEmpleado', 'empleado', 'Empleado'),
  clientes('clientes', 'idCliente', 'cliente', 'Cliente'),
  pagos('pagos', 'idPago', 'pago', 'Pago'),
  anticipos('anticipos-sueldo', 'idAnticipo', 'anticipo_sueldo', 'Anticipo'),
  serviciosExternos('servicios-externos', 'idServicioExt', 'servicio_externo', 'Servicio externo'),
  precios('precios-lugar', 'idPrecioLugar', 'precio_lugar', 'Precio'),
  contratos('servicios-contrato', 'idServicioContrato', 'servicio_contrato', 'Contrato'),
  pesajes('pesajes', 'idPesaje', 'pesaje', 'Pesaje'),
  rutas('rutas-trabajo', 'idRutaTrabajo', 'ruta_trabajo', 'Salida'),
  rutasEmpleado('rutas-empleado', 'idRutaEmpleado', 'ruta_empleado', 'Asignación de ruta'),
  camiones('camiones', 'idCamion', 'camion', 'Camión'),
  viajesExtra('viajes-extra', 'idViajeExtra', 'viaje_extra', 'Viaje extra'),
  usuariosWeb('usuarios-web', 'idUsuarioWeb', 'usuario_web', 'Usuario web'),
  cotizaciones('cotizaciones', 'idCotizacion', 'cotizacion', 'Cotización'),
  solicitudesPuesto('solicitudes-puesto', 'idSolicitud', 'solicitud_puesto_trabajo', 'Postulación'),
  gastosViaje('gastos-viaje', 'idGastoViaje', 'gasto_viaje', 'Gasto de viaje'),

  viajeExtraEmpleados('viaje-extra-empleados', null, 'viaje_extra_empleado', 'Personal de viaje');

  const Recurso(this.ruta, this.campoId, this.tabla, this.nombre);

  final String ruta;

  final String? campoId;

  final String tabla;

  final String nombre;
}
