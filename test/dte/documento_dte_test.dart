import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sacor_desktop/dte/documento_dte.dart';

Map<String, Object?> creditoFiscal() => {
      'identificacion': {
        'version': 3,
        'ambiente': '00',
        'tipoDte': '03',
        'numeroControl': 'DTE-03-M001P001-000000000000123',
        'codigoGeneracion': '6F1A2B3C-0000-4D5E-8F90-ABCDEF123456',
        'fecEmi': '2026-08-15',
      },
      'emisor': {'nit': '0614-111111-111-1', 'nrc': '111111-1', 'nombre': 'Gasolinera El Camino, S.A. de C.V.'},
      'receptor': {'nit': '0614-999999-999-9', 'nrc': '999999-9', 'nombre': 'SACOR, S.A. de C.V.'},
      'resumen': {
        'totalNoSuj': 0,
        'totalExenta': 0,
        'totalGravada': 100.0,
        'tributos': [
          {'codigo': '20', 'descripcion': 'Impuesto al Valor Agregado 13%', 'valor': 13.0},
          {'codigo': 'D1', 'descripcion': 'FOVIAL', 'valor': 2.0},
        ],
        'montoTotalOperacion': 115.0,
        'totalPagar': 115.0,
      },
    };

void main() {
  test('lee un crédito fiscal: IVA desde tributos con código 20', () {
    final d = DocumentoDte.interpretar('ccf.json', jsonEncode(creditoFiscal()));
    expect(d.valido, isTrue);
    expect(d.tipo, 'Crédito fiscal');
    expect(d.numeroControl, 'DTE-03-M001P001-000000000000123');
    expect(d.fecha, DateTime(2026, 8, 15));
    expect(d.emisorNombre, 'Gasolinera El Camino, S.A. de C.V.');
    expect(d.gravado, 100);
    expect(d.iva, 13);
    expect(d.total, 115);
  });

  test('lee una factura con totalIva y receptor por número de documento', () {
    final factura = creditoFiscal()
      ..['identificacion'] = {'tipoDte': '01', 'fecEmi': '2026-08-20', 'numeroControl': 'DTE-01-X'}
      ..['receptor'] = {'tipoDocumento': '13', 'numDocumento': '01234567-8', 'nombre': 'Cliente final'}
      ..['resumen'] = {'totalGravada': 56.5, 'totalIva': 6.5, 'totalPagar': 56.5};
    final d = DocumentoDte.interpretar('factura.json', jsonEncode(factura));
    expect(d.tipo, 'Factura');
    expect(d.receptorNit, '01234567-8');
    expect(d.iva, 6.5);
    expect(d.total, 56.5);
  });

  test('acepta el documento envuelto en "dteJson" y con BOM', () {
    final d = DocumentoDte.interpretar('envuelto.json', '\uFEFF${jsonEncode({'dteJson': creditoFiscal()})}');
    expect(d.valido, isTrue);
    expect(d.codigoGeneracion, '6F1A2B3C-0000-4D5E-8F90-ABCDEF123456');
  });

  test('emitido si el emisor es SACOR (compara solo dígitos del NIT)', () {
    final d = DocumentoDte.interpretar('ccf.json', jsonEncode(creditoFiscal()));
    expect(d.emitidoPor('06141111111111'), isTrue);
    expect(d.emitidoPor('0614-999999-999-9'), isFalse);
    expect(d.emitidoPor(null), isFalse);
  });

  test('un archivo que no es DTE devuelve el motivo', () {
    expect(DocumentoDte.interpretar('a.json', 'no es json').error, contains('JSON'));
    expect(DocumentoDte.interpretar('b.json', '{"hola": 1}').error, contains('identificacion'));
    expect(DocumentoDte.interpretar('c.json', '[1, 2]').valido, isFalse);
  });
}
