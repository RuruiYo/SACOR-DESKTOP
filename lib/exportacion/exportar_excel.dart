import 'package:excel/excel.dart' as xl;

import '../nucleo/dinero.dart';
import '../nucleo/formatos.dart';
import 'tabla_reporte.dart';

List<int> generarExcel(TablaReporte tabla, {required DateTime generado}) {
  final libro = xl.Excel.createExcel();
  final nombreHoja = libro.getDefaultSheet() ?? 'Sheet1';
  libro.rename(nombreHoja, 'Reporte');
  final hoja = libro['Reporte'];

  final verdeSuave = xl.ExcelColor.fromHexString('#FFDCFCE7');
  final verde = xl.ExcelColor.fromHexString('#FF15803D');
  final gris = xl.ExcelColor.fromHexString('#FF6B7280');
  final ambar = xl.ExcelColor.fromHexString('#FF92400E');
  final borde = xl.Border(borderStyle: xl.BorderStyle.Thin, borderColorHex: xl.ExcelColor.fromHexString('#FFD1D5DB'));

  const formatoDinero = xl.CustomNumericNumFormat(formatCode: r'"$"#,##0.00;-"$"#,##0.00');
  const formatoEntero = xl.CustomNumericNumFormat(formatCode: '#,##0');
  const formatoPorcentaje = xl.CustomNumericNumFormat(formatCode: '0.0"%"');
  const formatoDecimal = xl.CustomNumericNumFormat(formatCode: '#,##0.00');
  const formatoFecha = xl.CustomDateTimeNumFormat(formatCode: 'dd/mm/yyyy');

  var fila = 0;
  void escribir(int columna, xl.CellValue? valor, xl.CellStyle estilo) => hoja.updateCell(
        xl.CellIndex.indexByColumnRow(columnIndex: columna, rowIndex: fila),
        valor,
        cellStyle: estilo,
      );

  escribir(0, xl.TextCellValue('SACOR · ${tabla.titulo}'), xl.CellStyle(bold: true, fontSize: 14, fontColorHex: verde));
  fila++;
  escribir(0, xl.TextCellValue(tabla.subtitulo), xl.CellStyle(fontColorHex: gris));
  fila++;
  escribir(0, xl.TextCellValue('Generado: ${Formatos.fechaHora(generado)}'), xl.CellStyle(fontColorHex: gris));
  fila++;
  if (tabla.esDemo) {
    escribir(0, xl.TextCellValue(TablaReporte.avisoDemo), xl.CellStyle(bold: true, fontColorHex: ambar));
    fila++;
  }
  fila++;

  for (var c = 0; c < tabla.columnas.length; c++) {
    final columna = tabla.columnas[c];
    escribir(
      c,
      xl.TextCellValue(columna.titulo),
      xl.CellStyle(
        bold: true,
        backgroundColorHex: verdeSuave,
        bottomBorder: borde,
        horizontalAlign: columna.numerica ? xl.HorizontalAlign.Right : xl.HorizontalAlign.Left,
      ),
    );
  }
  fila++;

  void escribirFila(List<Object?> valores, {bool negrita = false}) {
    for (var c = 0; c < tabla.columnas.length; c++) {
      final columna = tabla.columnas[c];
      final valor = c < valores.length ? valores[c] : null;
      final (celda, formato) = switch (columna.tipo) {
        TipoColumna.dinero when valor is Dinero => (xl.DoubleCellValue(valor.comoDouble), formatoDinero),
        TipoColumna.entero when valor is int => (xl.IntCellValue(valor), formatoEntero),
        TipoColumna.decimal when valor is num => (xl.DoubleCellValue(valor.toDouble()), formatoDecimal),
        TipoColumna.porcentaje when valor is num => (xl.DoubleCellValue(valor.toDouble()), formatoPorcentaje),
        TipoColumna.fecha when valor is DateTime =>
          (xl.DateCellValue(year: valor.year, month: valor.month, day: valor.day), formatoFecha),
        _ => (valor == null ? null : xl.TextCellValue('$valor'), null),
      };
      escribir(
        c,
        celda,
        xl.CellStyle(
          bold: negrita,
          topBorder: negrita ? borde : null,
          numberFormat: formato ?? xl.NumFormat.standard_0,
          horizontalAlign: columna.numerica ? xl.HorizontalAlign.Right : xl.HorizontalAlign.Left,
        ),
      );
    }
    fila++;
  }

  for (final valores in tabla.filas) {
    escribirFila(valores);
  }
  if (tabla.totales != null) escribirFila(tabla.totales!, negrita: true);

  if (tabla.notas.isNotEmpty) {
    fila++;
    for (final nota in tabla.notas) {
      escribir(0, xl.TextCellValue(nota), xl.CellStyle(fontColorHex: gris, italic: true));
      fila++;
    }
  }

  for (var c = 0; c < tabla.columnas.length; c++) {
    final columna = tabla.columnas[c];
    hoja.setColumnWidth(c, columna.numerica ? 18 : (columna.tipo == TipoColumna.fecha ? 13 : 34));
  }

  return libro.encode() ?? const [];
}
