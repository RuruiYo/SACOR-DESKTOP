import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sacor_desktop/nucleo/dinero.dart';
import 'package:sacor_desktop/nucleo/formatos.dart';
import 'package:sacor_desktop/nucleo/variacion.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  group('Variacion (fórmula del documento)', () {
    test('((actual - anterior) / anterior) x 100', () {
      final v = Variacion.calcular(12500, 11552.68);
      expect(v.porcentaje, closeTo(8.2, 0.01));
      expect(v.tendencia, Tendencia.sube);
    });

    test('baja', () {
      final v = Variacion.calcular(7000, 7200);
      expect(v.porcentaje, closeTo(-2.78, 0.01));
      expect(v.tendencia, Tendencia.baja);
    });

    test('si el anterior es cero no se calcula', () {
      final v = Variacion.calcular(500, 0);
      expect(v.porcentaje, isNull);
      expect(v.calculable, isFalse);
      expect(v.descripcion, contains('Sin datos del período anterior'));
      expect(v.corta, 'N/D');
    });

    test('sin cambio', () {
      expect(Variacion.calcular(100, 100).tendencia, Tendencia.igual);
    });

    test('una base negativa que mejora se lee como subida', () {
      final v = Variacion.dinero(const Dinero(9100), const Dinero(-40750));
      expect(v.tendencia, Tendencia.sube);
      expect(v.porcentaje, closeTo(122.33, 0.01));
    });

    test('para egresos subir es desfavorable', () {
      final v = Variacion.calcular(110, 100);
      expect(v.esFavorable(subirEsBueno: false), isFalse);
      expect(v.esFavorable(subirEsBueno: true), isTrue);
      expect(Variacion.calcular(1, 0).esFavorable(subirEsBueno: true), isNull);
    });
  });

  group('Dinero', () {
    test('las sumas son exactas (sin errores de punto flotante)', () {
      final total = Dinero.sumar(List.filled(10, Dinero.desdeNumero(0.1)));
      expect(total, const Dinero(100));
      expect(Dinero.desdeNumero(0.1) + Dinero.desdeNumero(0.2), Dinero.desdeNumero(0.3));
    });

    test('interpreta lo que escribe el usuario', () {
      expect(Dinero.interpretar('1250'), const Dinero(125000));
      expect(Dinero.interpretar('1,250.5'), const Dinero(125050));
      expect(Dinero.interpretar(r'$ 75.25'), const Dinero(7525));
      expect(Dinero.interpretar('10.555'), isNull);
      expect(Dinero.interpretar('abc'), isNull);
      expect(Dinero.interpretar('-5'), isNull);
      expect(Dinero.interpretar('99999999999'), isNull);
    });

    test('lee el JSON de la API', () {
      expect(Dinero.desdeJson(425.5), const Dinero(42550));
      expect(Dinero.desdeJson(null), const Dinero.cero());
      expect(Dinero.desdeJsonOpcional(null), isNull);
    });

    test('se envía con a lo sumo dos decimales', () {
      expect(const Dinero(7550).toJson(), 75.5);
      expect(const Dinero(10000).toJson(), 100);
      expect(const Dinero(7).toJson(), 0.07);
      expect(const Dinero(7550).comoTextoEditable, '75.50');
    });
  });

  group('Formatos', () {
    test('dólares con formato consistente', () {
      expect(Formatos.usd(const Dinero(1250000)), r'$12,500.00');
      expect(Formatos.usd(const Dinero(-35000)), r'-$350.00');
      expect(Formatos.usdConSigno(const Dinero(530000)), r'+$5,300.00');
    });

    test('etiquetas compactas para ejes', () {
      expect(Formatos.usdCompacto(14000), r'$14 k');
      expect(Formatos.usdCompacto(10500), r'$10.5 k');
      expect(Formatos.usdCompacto(950), r'$950');
      expect(Formatos.usdCompacto(1200000), r'$1.2 M');
    });

    test('fechas día/mes/año y meses en español', () {
      expect(Formatos.fecha(DateTime(2026, 10, 9)), '09/10/2026');
      expect(Formatos.fecha(null), 'Sin fecha');
      expect(Formatos.mesLargo(2026, 10), 'Octubre 2026');
      expect(Formatos.nombreMes(1), 'Enero');
    });

    test('iniciales del usuario', () {
      expect(Formatos.iniciales('Rosa Elena Martínez'), 'RM');
      expect(Formatos.iniciales('Ana'), 'A');
    });
  });
}
