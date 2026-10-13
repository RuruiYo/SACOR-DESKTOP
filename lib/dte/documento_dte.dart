import 'dart:convert';

const tiposDte = {
  '01': 'Factura',
  '03': 'Crédito fiscal',
  '04': 'Nota de remisión',
  '05': 'Nota de crédito',
  '06': 'Nota de débito',
  '07': 'Comprobante de retención',
  '08': 'Comprobante de liquidación',
  '09': 'Documento contable de liquidación',
  '11': 'Factura de exportación',
  '14': 'Sujeto excluido',
  '15': 'Comprobante de donación',
};

class DocumentoDte {
  const DocumentoDte({
    required this.archivo,
    this.codigoTipo,
    this.codigoGeneracion,
    this.numeroControl,
    this.fecha,
    this.emisorNombre,
    this.emisorNit,
    this.emisorNrc,
    this.receptorNombre,
    this.receptorNit,
    this.receptorNrc,
    this.gravado = 0,
    this.exento = 0,
    this.iva = 0,
    this.total = 0,
    this.error,
  });

  final String archivo;
  final String? codigoTipo;
  final String? codigoGeneracion;
  final String? numeroControl;
  final DateTime? fecha;
  final String? emisorNombre;
  final String? emisorNit;
  final String? emisorNrc;
  final String? receptorNombre;
  final String? receptorNit;
  final String? receptorNrc;
  final double gravado;
  final double exento;
  final double iva;
  final double total;

  final String? error;

  bool get valido => error == null;

  String get tipo => tiposDte[codigoTipo] ?? (codigoTipo == null ? 'Desconocido' : 'Tipo $codigoTipo');

  bool emitidoPor(String? nitEmpresa) {
    final empresa = soloDigitos(nitEmpresa);
    return empresa.isNotEmpty && soloDigitos(emisorNit) == empresa;
  }

  static String soloDigitos(String? texto) => (texto ?? '').replaceAll(RegExp(r'\D'), '');

  factory DocumentoDte.interpretar(String archivo, String contenido) {
    final Object? json;
    try {
      json = jsonDecode(contenido.startsWith('\uFEFF') ? contenido.substring(1) : contenido);
    } on FormatException {
      return DocumentoDte(archivo: archivo, error: 'No es un JSON válido.');
    }

    var documento = json is Map<String, dynamic> ? json : null;
    if (documento != null && documento['identificacion'] is! Map && documento['dteJson'] is Map) {
      documento = (documento['dteJson'] as Map).cast<String, dynamic>();
    }
    final identificacion = documento?['identificacion'];
    if (documento == null || identificacion is! Map) {
      return DocumentoDte(archivo: archivo, error: 'No tiene el formato de DTE de Hacienda ("identificacion").');
    }

    Map<String, dynamic> mapa(Object? valor) => valor is Map ? valor.cast<String, dynamic>() : const {};
    String? texto(Object? valor) => valor is String && valor.trim().isNotEmpty ? valor.trim() : null;
    double numero(Object? valor) => valor is num ? valor.toDouble() : double.tryParse('$valor') ?? 0;

    final emisor = mapa(documento['emisor']);
    final receptor = mapa(documento['receptor'] ?? documento['sujetoExcluido']);
    final resumen = mapa(documento['resumen']);

    var iva = numero(resumen['totalIva']);
    if (iva == 0 && resumen['tributos'] is List) {
      for (final tributo in (resumen['tributos'] as List).whereType<Map>()) {
        if ('${tributo['codigo']}' == '20') iva += numero(tributo['valor']);
      }
    }

    final totalPagar = resumen['totalPagar'] ?? resumen['montoTotalOperacion'] ?? resumen['totalCompra'];

    return DocumentoDte(
      archivo: archivo,
      codigoTipo: texto(identificacion['tipoDte']),
      codigoGeneracion: texto(identificacion['codigoGeneracion']),
      numeroControl: texto(identificacion['numeroControl']),
      fecha: DateTime.tryParse(texto(identificacion['fecEmi']) ?? ''),
      emisorNombre: texto(emisor['nombre']),
      emisorNit: texto(emisor['nit']),
      emisorNrc: texto(emisor['nrc']),
      receptorNombre: texto(receptor['nombre']),
      receptorNit: texto(receptor['nit']) ?? texto(receptor['numDocumento']),
      receptorNrc: texto(receptor['nrc']),
      gravado: numero(resumen['totalGravada']),
      exento: numero(resumen['totalExenta']) + numero(resumen['totalNoSuj']),
      iva: iva,
      total: numero(totalPagar),
    );
  }
}
