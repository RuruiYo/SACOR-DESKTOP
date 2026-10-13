import 'dart:convert';

import '../nucleo/dinero.dart';
import '../nucleo/formatos.dart';
import 'tabla_reporte.dart';

List<int> generarCsv(TablaReporte tabla) {
  final lineas = <String>[
    _fila(tabla.columnas.map((c) => _texto(c.titulo))),
    for (final fila in tabla.filas) _fila(_valores(tabla, fila)),
    if (tabla.totales != null) _fila(_valores(tabla, tabla.totales!)),
  ];
  return [0xEF, 0xBB, 0xBF, ...utf8.encode('${lineas.join('\r\n')}\r\n')];
}

Iterable<String> _valores(TablaReporte tabla, List<Object?> fila) sync* {
  for (var i = 0; i < tabla.columnas.length; i++) {
    final valor = i < fila.length ? fila[i] : null;
    yield _valor(valor, tabla.columnas[i].tipo);
  }
}

String _fila(Iterable<String> celdas) => celdas.join(',');

String _valor(Object? valor, TipoColumna tipo) {
  if (valor == null) return '';
  return switch (tipo) {
    TipoColumna.dinero when valor is Dinero => _decimal(valor),
    TipoColumna.entero when valor is int => '$valor',
    TipoColumna.decimal when valor is num => valor.toStringAsFixed(2),
    TipoColumna.porcentaje when valor is num => valor.toStringAsFixed(1),
    TipoColumna.fecha when valor is DateTime => Formatos.fechaIso(valor),
    _ => _texto('$valor'),
  };
}

String _decimal(Dinero monto) {
  final signo = monto.esNegativo ? '-' : '';
  final absoluto = monto.centavos.abs();
  return '$signo${absoluto ~/ 100}.${(absoluto % 100).toString().padLeft(2, '0')}';
}

String _texto(String valor) {
  var limpio = valor;
  if (limpio.isNotEmpty && '=+-@\t\r'.contains(limpio[0])) limpio = "'$limpio";
  final requiereComillas = limpio.contains(RegExp('[",\r\n]'));
  return requiereComillas ? '"${limpio.replaceAll('"', '""')}"' : limpio;
}
