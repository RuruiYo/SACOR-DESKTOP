import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../nucleo/formatos.dart';
import 'tabla_reporte.dart';

Future<Uint8List> generarPdf(TablaReporte tabla, {required DateTime generado}) async {
  const verde = PdfColor.fromInt(0xFF15803D);
  const verdeSuave = PdfColor.fromInt(0xFFDCFCE7);
  const gris = PdfColor.fromInt(0xFF6B7280);
  const borde = PdfColor.fromInt(0xFFE5E7EB);
  const texto = PdfColor.fromInt(0xFF111827);
  const ambarSuave = PdfColor.fromInt(0xFFFEF3C7);
  const ambarTexto = PdfColor.fromInt(0xFF92400E);

  final documento = pw.Document(
    title: 'SACOR - ${_latin1(tabla.titulo)}',
    author: 'SACOR Desktop',
    creator: 'SACOR Desktop',
  );

  final horizontal = tabla.columnas.length > 6;
  final tamanoLetra = tabla.columnas.length > 8 ? 7.5 : 9.0;

  pw.Widget celda(String valor, {bool derecha = false, bool negrita = false, PdfColor color = texto}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: pw.Text(
          _latin1(valor),
          textAlign: derecha ? pw.TextAlign.right : pw.TextAlign.left,
          style: pw.TextStyle(
            fontSize: tamanoLetra,
            color: color,
            fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );

  List<pw.Widget> fila(List<Object?> valores, {bool negrita = false}) => [
        for (var i = 0; i < tabla.columnas.length; i++)
          celda(
            TablaReporte.texto(i < valores.length ? valores[i] : null, tabla.columnas[i].tipo),
            derecha: tabla.columnas[i].numerica,
            negrita: negrita,
          ),
      ];

  documento.addPage(
    pw.MultiPage(
      pageFormat: horizontal ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 36),
      header: (contexto) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 10),
        margin: const pw.EdgeInsets.only(bottom: 12),
        decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: borde))),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('SACOR', style: pw.TextStyle(fontSize: 10, color: verde, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 2),
                  pw.Text(_latin1(tabla.titulo), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 2),
                  pw.Text(_latin1(tabla.subtitulo), style: const pw.TextStyle(fontSize: 9, color: gris)),
                ],
              ),
            ),
            pw.Text(
              _latin1('Generado: ${Formatos.fechaHora(generado)}'),
              style: const pw.TextStyle(fontSize: 8, color: gris),
            ),
          ],
        ),
      ),
      footer: (contexto) => pw.Row(
        children: [
          pw.Text('SACOR Desktop - administración contable', style: const pw.TextStyle(fontSize: 8, color: gris)),
          pw.Spacer(),
          pw.Text(
            _latin1('Página ${contexto.pageNumber} de ${contexto.pagesCount}'),
            style: const pw.TextStyle(fontSize: 8, color: gris),
          ),
        ],
      ),
      build: (contexto) => [
        if (tabla.esDemo)
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(8),
            margin: const pw.EdgeInsets.only(bottom: 10),
            decoration: const pw.BoxDecoration(color: ambarSuave),
            child: pw.Text(
              _latin1(TablaReporte.avisoDemo),
              style: pw.TextStyle(fontSize: 9, color: ambarTexto, fontWeight: pw.FontWeight.bold),
            ),
          ),
        pw.Table(
          border: const pw.TableBorder(horizontalInside: pw.BorderSide(color: borde, width: 0.5)),
          columnWidths: {
            for (var i = 0; i < tabla.columnas.length; i++) i: pw.FlexColumnWidth(tabla.columnas[i].flex.toDouble()),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: verdeSuave),
              repeat: true,
              children: [
                for (final columna in tabla.columnas)
                  celda(columna.titulo, derecha: columna.numerica, negrita: true),
              ],
            ),
            for (final valores in tabla.filas) pw.TableRow(children: fila(valores)),
            if (tabla.totales != null)
              pw.TableRow(
                decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: gris))),
                children: fila(tabla.totales!, negrita: true),
              ),
          ],
        ),
        if (tabla.filas.isEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.all(16),
            child: pw.Text('Sin registros para el período.', style: const pw.TextStyle(color: gris)),
          ),
        if (tabla.notas.isNotEmpty) ...[
          pw.SizedBox(height: 14),
          for (final nota in tabla.notas)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text(_latin1(nota), style: const pw.TextStyle(fontSize: 8, color: gris)),
            ),
        ],
      ],
    ),
  );

  return documento.save();
}

String _latin1(String valor) {
  final reemplazado = valor
      .replaceAll('—', '-')
      .replaceAll('–', '-')
      .replaceAll('−', '-')
      .replaceAll('…', '...')
      .replaceAll('“', '"')
      .replaceAll('”', '"')
      .replaceAll('‘', "'")
      .replaceAll('’', "'")
      .replaceAll('━', '-');
  return String.fromCharCodes(reemplazado.runes.map((r) => r <= 0xFF ? r : 0x3F));
}
