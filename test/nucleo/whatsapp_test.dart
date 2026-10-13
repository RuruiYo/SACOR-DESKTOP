import 'package:flutter_test/flutter_test.dart';
import 'package:sacor_desktop/nucleo/whatsapp.dart';

void main() {
  test('agrega el 503 a los números de El Salvador', () {
    expect(numeroWhatsapp('7012-9988'), '50370129988');
    expect(numeroWhatsapp('2245 1100'), '50322451100');
    expect(numeroWhatsapp('+503 7888-1234'), '50378881234');
  });

  test('sin teléfono válido no hay enlace', () {
    expect(numeroWhatsapp(null), isNull);
    expect(numeroWhatsapp('123'), isNull);
    expect(enlaceWhatsapp('', 'hola'), isNull);
  });

  test('arma el enlace con el saludo codificado', () {
    final enlace = enlaceWhatsapp('7012-9988', saludoCotizacion('María Elena Gómez', 'Transporte de ripio', 12))!;
    expect(enlace.host, 'wa.me');
    expect(enlace.path, '/50370129988');
    expect(enlace.queryParameters['text'],
        'Hola María, le saluda SACOR sobre su solicitud de transporte de ripio (cotización #12).');
  });

  test('saludo de postulación', () {
    expect(saludoPostulacion('Óscar Ruiz', 'Motorista de volqueta', 3),
        'Hola Óscar, le saluda SACOR sobre su postulación para motorista de volqueta (solicitud #3).');
  });
}
