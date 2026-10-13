import 'json.dart';

class RegistroAuditoria {
  const RegistroAuditoria({
    required this.id,
    required this.fechaHora,
    required this.idEmpleado,
    required this.tabla,
    required this.idRegistro,
    required this.accion,
    this.valorAnterior,
    this.valorNuevo,
    this.detalle,
  });

  factory RegistroAuditoria.desdeJson(Json json) => RegistroAuditoria(
        id: leerEntero(json['idAuditoria']),
        fechaHora: DateTime.tryParse(leerTexto(json['fechaHora'])) ?? DateTime(2000),
        idEmpleado: leerEnteroOpcional(json['idEmpleado']),
        tabla: leerTexto(json['tablaAfectada']),
        idRegistro: leerTexto(json['idRegistro']),
        accion: leerTexto(json['accion']),
        valorAnterior: leerTextoOpcional(json['valorAnterior']),
        valorNuevo: leerTextoOpcional(json['valorNuevo']),
        detalle: leerTextoOpcional(json['detalle']),
      );

  final int id;
  final DateTime fechaHora;
  final int? idEmpleado;
  final String tabla;
  final String idRegistro;
  final String accion;
  final String? valorAnterior;
  final String? valorNuevo;
  final String? detalle;
}

class NuevaAuditoria {
  const NuevaAuditoria({
    required this.idEmpleado,
    required this.tabla,
    required this.idRegistro,
    required this.accion,
    this.valorAnterior,
    this.valorNuevo,
    this.detalle,
  });

  final int? idEmpleado;
  final String tabla;
  final String idRegistro;
  final String accion;
  final String? valorAnterior;
  final String? valorNuevo;
  final String? detalle;

  Json aJson() => {
        'idEmpleado': idEmpleado,
        'tablaAfectada': tabla,
        'idRegistro': idRegistro,
        'accion': accion,
        'valorAnterior': valorAnterior,
        'valorNuevo': valorNuevo,
        'detalle': detalle,
      };
}

class PaginaAuditoria {
  const PaginaAuditoria({required this.pagina, required this.tamano, required this.total, required this.datos});

  factory PaginaAuditoria.desdeJson(Json json) => PaginaAuditoria(
        pagina: leerEntero(json['pagina']),
        tamano: leerEntero(json['tamano']),
        total: leerEntero(json['total']),
        datos: (json['datos'] as List? ?? const []).cast<Json>().map(RegistroAuditoria.desdeJson).toList(),
      );

  final int pagina;
  final int tamano;
  final int total;
  final List<RegistroAuditoria> datos;
}
