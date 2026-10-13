import '../../nucleo/dinero.dart';
import '../../nucleo/texto_fechado.dart';
import 'json.dart';

abstract class Entidad {
  const Entidad(this.json);

  final Json json;

  int get id;

  Json con(Json cambios) => {...json, ...cambios};
}

String conTildes(String valor) => switch (valor) {
      'AdministradorOperativo' => 'Administrador operativo',
      'AdministradorTecnico' => 'Administrador técnico',
      'Tecnico' => 'Técnico',
      'Mecanico' => 'Mecánico',
      'Juridico' => 'Jurídico',
      _ => valor,
    };

class Empleado extends Entidad {
  const Empleado(super.json);

  static const administradorOperativo = 'AdministradorOperativo';
  static const tipos = [administradorOperativo, 'AdministradorTecnico', 'Tecnico', 'Motorista'];
  static const tiposAnteriores = ['Ayudante', 'Mecanico', 'Coordinador'];
  static const estados = ['Activo', 'Inactivo', 'Suspendido'];

  @override
  int get id => leerEntero(json['idEmpleado']);

  String get codigo => leerTexto(json['codigoEmpleado']);
  String get nombre => leerTexto(json['nombre']);
  String get dui => leerTexto(json['dui']);
  String? get telefono => leerTextoOpcional(json['telefono']);
  Dinero get sueldo => leerDinero(json['sueldo']);
  DateTime? get fechaIngreso => leerFecha(json['fechaIngreso']);
  String? get codigoAf => leerTextoOpcional(json['codigoAf']);
  String get estado => leerTexto(json['estado']);
  String get tipo => leerTexto(json['tipo']);

  bool get activo => estado.toLowerCase() == 'activo';
  bool get esAdministrador => tipo == administradorOperativo;
  bool get tipoAnterior => tiposAnteriores.contains(tipo);
  String get tipoVisible => conTildes(tipo);
}

class Cliente extends Entidad {
  const Cliente(super.json);

  static const tipos = ['Natural', 'Juridico'];

  @override
  int get id => leerEntero(json['idCliente']);
  String get nombre => leerTexto(json['nombre']);
  String get tipo => leerTexto(json['tipo']);
  String? get direccion => leerTextoOpcional(json['direccion']);
  String? get correo => leerTextoOpcional(json['correo']);
  String? get telefono => leerTextoOpcional(json['telefono']);
  String? get nit => leerTextoOpcional(json['nit']);
  String? get dui => leerTextoOpcional(json['dui']);
  String? get giro => leerTextoOpcional(json['giro']);
  String? get nrc => leerTextoOpcional(json['nrc']);
  String? get nombreComercial => leerTextoOpcional(json['nombreComercial']);

  String get tipoVisible => conTildes(tipo);

  String? get documento => nit ?? dui;
}

class Pago extends Entidad {
  const Pago(super.json);

  @override
  int get id => leerEntero(json['idPago']);
  int get idEmpleado => leerEntero(json['idEmpleado']);
  DateTime? get fecha => leerFecha(json['fecha']);
  Dinero get cantidad => leerDinero(json['cantidad']);
  Dinero get descuento => leerDinero(json['descuento']);
  String? get observacion => leerTextoOpcional(json['observacion']);

  Dinero get neto => cantidad - descuento;
}

class Anticipo extends Entidad {
  const Anticipo(super.json);

  @override
  int get id => leerEntero(json['idAnticipo']);
  int get idEmpleado => leerEntero(json['idEmpleado']);
  DateTime? get fecha => leerFecha(json['fecha']);
  Dinero get cantidad => leerDinero(json['cantidad']);
  String? get observacion => leerTextoOpcional(json['observacion']);
}

class ServicioExterno extends Entidad {
  const ServicioExterno(super.json);

  @override
  int get id => leerEntero(json['idServicioExt']);
  String get nombreGuardado => leerTexto(json['nombre']);
  TextoFechado get nombreFechado => TextoFechado.leer(nombreGuardado);
  String get nombre => nombreFechado.texto;
  DateTime? get fecha => nombreFechado.fecha;
  Dinero get monto => leerDinero(json['cantidadPago']);
  String? get direccion => leerTextoOpcional(json['direccion']);
}

class PrecioLugar extends Entidad {
  const PrecioLugar(super.json);

  @override
  int get id => leerEntero(json['idPrecioLugar']);
  String get tipo => leerTexto(json['tipo']);
  String get lugar => leerTexto(json['lugar']);
  Dinero get precio => leerDinero(json['precio']);
  DateTime? get fechaModificacion => leerFecha(json['fechaModificacion']);

  String get descripcion => '$tipo · $lugar';
}

class Contrato extends Entidad {
  const Contrato(super.json);

  @override
  int get id => leerEntero(json['idServicioContrato']);
  int get idCliente => leerEntero(json['idCliente']);
  int get idRutaTrabajo => leerEntero(json['idRutaTrabajo']);
  int get idPrecioLugar => leerEntero(json['idPrecioLugar']);
  DateTime? get fecha => leerFecha(json['fecha']);
  String? get tipoTransportaje => leerTextoOpcional(json['tipoTransportaje']);
  String? get observacion => leerTextoOpcional(json['observacion']);
  int? get idCotizacion => leerEnteroOpcional(json['idCotizacion']);
}

class Pesaje extends Entidad {
  const Pesaje(super.json);

  @override
  int get id => leerEntero(json['idPesaje']);
  int get idContrato => leerEntero(json['idServicioContrato']);
  int get idEmpleadoSubio => leerEntero(json['idEmpleadoSubio']);
  int get idTecnico => leerEntero(json['idTecnicoTransporte']);
  int get idPrecioLugar => leerEntero(json['idPrecioLugar']);
  DateTime? get fecha => leerFecha(json['fecha']);

  double get libras => leerDecimal(json['pesoTotal']);
  String? get etapa => leerTextoOpcional(json['etapa']);
  Dinero? get precioTonelada => leerDineroOpcional(json['precioTonelada']);
  int? get idRutaTrabajo => leerEnteroOpcional(json['idRutaTrabajo']);
}

class Ruta extends Entidad {
  const Ruta(super.json);

  @override
  int get id => leerEntero(json['idRutaTrabajo']);
  String get destinoGuardado => leerTexto(json['destino']);
  TextoFechado get destinoFechado => TextoFechado.leer(destinoGuardado);
  String get destino => destinoFechado.texto;
  DateTime? get fecha => destinoFechado.fecha;
  Dinero get gasolina => leerDinero(json['dineroGasolina']);
  String? get tipo => leerTextoOpcional(json['tipo']);
  int? get idContrato => leerEnteroOpcional(json['idServicioContrato']);
  int? get idCamion => leerEnteroOpcional(json['idCamion']);
}

class RutaEmpleado extends Entidad {
  const RutaEmpleado(super.json);

  @override
  int get id => leerEntero(json['idRutaEmpleado']);
  int get idRuta => leerEntero(json['idRutaTrabajo']);
  int get idEmpleado => leerEntero(json['idEmpleado']);
}

class Camion extends Entidad {
  const Camion(super.json);

  @override
  int get id => leerEntero(json['idCamion']);
  String get placa => leerTexto(json['placa']);
  String? get nombre => leerTextoOpcional(json['nombre']);
  String? get tipo => leerTextoOpcional(json['tipo']);
  String? get estado => leerTextoOpcional(json['estado']);
  String? get dueno => leerTextoOpcional(json['dueno']);
  String? get observacion => leerTextoOpcional(json['observacion']);

  String get descripcion => nombre == null ? placa : '$nombre ($placa)';
}

class ViajeExtra extends Entidad {
  const ViajeExtra(super.json);

  @override
  int get id => leerEntero(json['idViajeExtra']);
  int get idCliente => leerEntero(json['idCliente']);
  int get idCamion => leerEntero(json['idCamion']);
  String get tipoGuardado => leerTexto(json['tipo']);
  TextoFechado get tipoFechado => TextoFechado.leer(tipoGuardado);
  String get tipo => tipoFechado.texto;
  DateTime? get fecha => tipoFechado.fecha;

  Dinero get precio => leerDinero(json['precio']);
  Dinero? get pago => leerDineroOpcional(json['pagoMonto']);
  int get cantidad {
    final valor = leerEnteroOpcional(json['cantidad']);
    return valor == null || valor < 1 ? 1 : valor;
  }

  Dinero get total => precio.multiplicar(cantidad);
}

class UsuarioWeb extends Entidad {
  const UsuarioWeb(super.json);

  @override
  int get id => leerEntero(json['idUsuarioWeb']);
  String get nombre => leerTexto(json['nombre']);
  String get dui => leerTexto(json['dui']);
  String? get telefono => leerTextoOpcional(json['telefono']);
  String? get correo => leerTextoOpcional(json['email']);
}

class Cotizacion extends Entidad {
  const Cotizacion(super.json);

  static const estados = ['Pendiente', 'EnRevision', 'Cotizada', 'Aprobada', 'Rechazada', 'Cerrada'];

  static String estadoVisible(String estado) => estado == 'EnRevision' ? 'En revisión' : estado;

  @override
  int get id => leerEntero(json['idCotizacion']);
  int get idUsuarioWeb => leerEntero(json['idUsuarioWeb']);
  int? get idAnalista => leerEnteroOpcional(json['idAdministradorAnalista']);
  DateTime? get fecha => leerFecha(json['fecha']);
  String get estado => leerTexto(json['estado']);
  String? get tipoServicio => leerTextoOpcional(json['tipoServicio']);
  String? get descripcion => leerTextoOpcional(json['descripcion']);

  List<String> get detalles =>
      (descripcion ?? '').split(' | ').map((d) => d.trim()).where((d) => d.isNotEmpty).toList();
}

class SolicitudPuesto extends Entidad {
  const SolicitudPuesto(super.json);

  @override
  int get id => leerEntero(json['idSolicitud']);
  int get idUsuarioWeb => leerEntero(json['idUsuarioWeb']);
  int? get idAnalista => leerEnteroOpcional(json['idAdministradorAnalista']);
  String get puesto => leerTexto(json['tipoPuesto']);
  DateTime? get fecha => leerFecha(json['fecha']);

  bool get atendida => idAnalista != null;
}

class GastoViaje extends Entidad {
  const GastoViaje(super.json);

  @override
  int get id => leerEntero(json['idGastoViaje']);
  int get idRuta => leerEntero(json['idRutaTrabajo']);
  int get idEmpleado => leerEntero(json['idEmpleado']);
  DateTime? get fecha => leerFecha(json['fecha']);
  String get concepto => leerTexto(json['concepto']);
  Dinero get monto => leerDinero(json['monto']);
  String? get descripcion => leerTextoOpcional(json['descripcion']);

  String get conceptoVisible => concepto == 'Alimentacion' ? 'Alimentación' : concepto;
}

class ViajeExtraEmpleado {
  const ViajeExtraEmpleado(this.idViajeExtra, this.idEmpleado);

  factory ViajeExtraEmpleado.desdeJson(Json json) =>
      ViajeExtraEmpleado(leerEntero(json['idViajeExtra']), leerEntero(json['idEmpleado']));

  final int idViajeExtra;
  final int idEmpleado;
}
