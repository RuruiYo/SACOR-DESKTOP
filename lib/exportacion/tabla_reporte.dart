import '../nucleo/dinero.dart';
import '../nucleo/formatos.dart';

enum TipoColumna { texto, dinero, entero, decimal, porcentaje, fecha }

class ColumnaReporte {
  const ColumnaReporte(this.titulo, this.tipo, {this.flex = 2});

  final String titulo;
  final TipoColumna tipo;
  final int flex;

  bool get numerica => tipo != TipoColumna.texto && tipo != TipoColumna.fecha;
}

class TablaReporte {
  const TablaReporte({
    required this.titulo,
    required this.subtitulo,
    required this.columnas,
    required this.filas,
    this.totales,
    this.notas = const [],
    this.esDemo = false,
  });

  final String titulo;
  final String subtitulo;
  final List<ColumnaReporte> columnas;
  final List<List<Object?>> filas;
  final List<Object?>? totales;
  final List<String> notas;

  final bool esDemo;

  static const avisoDemo = 'DATOS DE DEMOSTRACIÓN: las cifras de este informe son ficticias.';

  static String texto(Object? valor, TipoColumna tipo) {
    if (valor == null) return '—';
    return switch (tipo) {
      TipoColumna.dinero => valor is Dinero ? Formatos.usd(valor) : '$valor',
      TipoColumna.entero => valor is int ? Formatos.entero(valor) : '$valor',
      TipoColumna.decimal => valor is num ? Formatos.decimal(valor) : '$valor',
      TipoColumna.porcentaje => valor is num ? Formatos.porcentaje(valor.toDouble()) : '$valor',
      TipoColumna.fecha => valor is DateTime ? Formatos.fecha(valor) : '$valor',
      TipoColumna.texto => '$valor',
    };
  }

  String nombreArchivo(String extension, DateTime fecha) {
    final base = titulo
        .toLowerCase()
        .replaceAll(RegExp('[áàä]'), 'a')
        .replaceAll(RegExp('[éèë]'), 'e')
        .replaceAll(RegExp('[íìï]'), 'i')
        .replaceAll(RegExp('[óòö]'), 'o')
        .replaceAll(RegExp('[úùü]'), 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp('[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return 'SACOR_${base}_${Formatos.fechaIso(fecha)}.$extension';
  }
}
