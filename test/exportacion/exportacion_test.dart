import 'dart:convert';

import 'package:excel/excel.dart' as xl;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sacor_desktop/exportacion/exportar_csv.dart';
import 'package:sacor_desktop/exportacion/exportar_excel.dart';
import 'package:sacor_desktop/exportacion/exportar_pdf.dart';
import 'package:sacor_desktop/exportacion/tabla_reporte.dart';
import 'package:sacor_desktop/nucleo/dinero.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  final tabla = TablaReporte(
    titulo: 'Información por cliente',
    subtitulo: 'Período: mes actual (01/10/2026 – 09/10/2026)',
    esDemo: true,
    columnas: const [
      ColumnaReporte('Cliente', TipoColumna.texto, flex: 4),
      ColumnaReporte('Contratado', TipoColumna.dinero),
      ColumnaReporte('% cobrado', TipoColumna.porcentaje),
      ColumnaReporte('Servicios', TipoColumna.entero),
      ColumnaReporte('Último cobro', TipoColumna.fecha),
    ],
    filas: [
      ['Constructora Pinar del Valle, S.A. de C.V.', const Dinero(124550), 50.0, 3, DateTime(2026, 10, 5)],
      ['=HYPERLINK("malicioso")', const Dinero(-1000), null, 0, null],
      ['María José "Majo" Hernández', const Dinero(7), 12.345, 1, DateTime(2026, 9, 30)],
    ],
    totales: ['Total', const Dinero(123557), null, 4, null],
    notas: const ['Nota con tilde: período — guion largo'],
  );

  test('CSV con BOM, comas, comillas y protección contra fórmulas', () {
    final bytes = generarCsv(tabla);
    expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
    final texto = utf8.decode(bytes.skip(3).toList());
    final lineas = texto.trim().split('\r\n');
    expect(lineas.first, 'Cliente,Contratado,% cobrado,Servicios,Último cobro');
    expect(lineas[1], '"Constructora Pinar del Valle, S.A. de C.V.",1245.50,50.0,3,2026-10-05');
    expect(lineas[2], startsWith('"\'=HYPERLINK(""malicioso"")",-10.00,,0,'));
    expect(lineas[3], '"María José ""Majo"" Hernández",0.07,12.3,1,2026-09-30');
    expect(lineas.last, 'Total,1235.57,,4,');
  });

  test('Excel: se puede volver a abrir y conserva valores numéricos', () {
    final bytes = generarExcel(tabla, generado: DateTime(2026, 10, 9, 10, 30));
    expect(bytes, isNotEmpty);
    final libro = xl.Excel.decodeBytes(bytes);
    final hoja = libro['Reporte'];
    final textos = hoja.rows.expand((f) => f).whereType<xl.Data>().map((c) => c.value.toString()).toList();
    expect(textos.any((t) => t.contains('Información por cliente')), isTrue);
    expect(textos.any((t) => t.contains('DEMOSTRACIÓN')), isTrue);
    final numeros = hoja.rows.expand((f) => f).whereType<xl.Data>().map((c) => c.value).whereType<xl.DoubleCellValue>();
    expect(numeros.map((n) => n.value), contains(1245.5));
  });

  test('PDF con tildes, eñes y guiones largos sin fallar', () async {
    final bytes = await generarPdf(tabla, generado: DateTime(2026, 10, 9, 10, 30));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(1500));
  });

  test('nombre de archivo sin tildes ni espacios', () {
    expect(tabla.nombreArchivo('xlsx', DateTime(2026, 10, 9)), 'SACOR_informacion_por_cliente_2026-10-09.xlsx');
  });
}
