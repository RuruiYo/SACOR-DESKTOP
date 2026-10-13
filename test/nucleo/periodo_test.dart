import 'package:flutter_test/flutter_test.dart';
import 'package:sacor_desktop/nucleo/periodo.dart';

void main() {
  final hoy = DateTime(2026, 10, 9, 15, 30);

  group('Periodo.desdePreset', () {
    test('mes actual se compara con los mismos días del mes anterior', () {
      final p = Periodo.desdePreset(PresetPeriodo.mesActual, hoy);
      expect(p.desde, DateTime(2026, 10, 1));
      expect(p.hasta, DateTime(2026, 10, 9));
      expect(p.desdeAnterior, DateTime(2026, 9, 1));
      expect(p.hastaAnterior, DateTime(2026, 9, 9));
      expect(p.dias, 9);
    });

    test('mes actual al 31 de marzo compara con el último día de febrero', () {
      final p = Periodo.desdePreset(PresetPeriodo.mesActual, DateTime(2027, 3, 31));
      expect(p.desdeAnterior, DateTime(2027, 2, 1));
      expect(p.hastaAnterior, DateTime(2027, 2, 28));
    });

    test('mes anterior completo contra el mes previo completo', () {
      final p = Periodo.desdePreset(PresetPeriodo.mesAnterior, hoy);
      expect(p.desde, DateTime(2026, 9, 1));
      expect(p.hasta, DateTime(2026, 9, 30));
      expect(p.desdeAnterior, DateTime(2026, 8, 1));
      expect(p.hastaAnterior, DateTime(2026, 8, 31));
    });

    test('mes anterior en enero cruza de año', () {
      final p = Periodo.desdePreset(PresetPeriodo.mesAnterior, DateTime(2027, 1, 15));
      expect(p.desde, DateTime(2026, 12, 1));
      expect(p.hasta, DateTime(2026, 12, 31));
      expect(p.desdeAnterior, DateTime(2026, 11, 1));
    });

    test('últimos 3 meses incluye el mes en curso', () {
      final p = Periodo.desdePreset(PresetPeriodo.ultimos3Meses, hoy);
      expect(p.desde, DateTime(2026, 8, 1));
      expect(p.hasta, DateTime(2026, 10, 9));
      expect(p.desdeAnterior, DateTime(2026, 5, 1));
      expect(p.hastaAnterior, DateTime(2026, 7, 9));
    });

    test('año actual se compara con el mismo tramo del año anterior', () {
      final p = Periodo.desdePreset(PresetPeriodo.anioActual, hoy);
      expect(p.desde, DateTime(2026, 1, 1));
      expect(p.desdeAnterior, DateTime(2025, 1, 1));
      expect(p.hastaAnterior, DateTime(2025, 10, 9));
    });

    test('29 de febrero compara con el 28 del año anterior', () {
      final p = Periodo.desdePreset(PresetPeriodo.anioActual, DateTime(2028, 2, 29));
      expect(p.hastaAnterior, DateTime(2027, 2, 28));
    });

    test('año anterior completo', () {
      final p = Periodo.desdePreset(PresetPeriodo.anioAnterior, hoy);
      expect(p.desde, DateTime(2025, 1, 1));
      expect(p.hasta, DateTime(2025, 12, 31));
      expect(p.desdeAnterior, DateTime(2024, 1, 1));
      expect(p.hastaAnterior, DateTime(2024, 12, 31));
    });
  });

  group('Periodo.personalizado', () {
    test('compara con la misma cantidad de días inmediatamente anteriores', () {
      final p = Periodo.personalizado(DateTime(2026, 9, 10), DateTime(2026, 9, 19));
      expect(p.dias, 10);
      expect(p.desdeAnterior, DateTime(2026, 8, 31));
      expect(p.hastaAnterior, DateTime(2026, 9, 9));
      expect(Periodo.diasEntre(p.desdeAnterior, p.hastaAnterior), 10);
    });

    test('ignora la hora de las fechas', () {
      final p = Periodo.personalizado(DateTime(2026, 9, 1, 23, 59), DateTime(2026, 9, 1, 0, 1));
      expect(p.desde, DateTime(2026, 9, 1));
      expect(p.dias, 1);
    });
  });

  test('contiene incluye ambos extremos', () {
    final p = Periodo.personalizado(DateTime(2026, 9, 1), DateTime(2026, 9, 30));
    expect(p.contiene(DateTime(2026, 9, 1)), isTrue);
    expect(p.contiene(DateTime(2026, 9, 30, 18)), isTrue);
    expect(p.contiene(DateTime(2026, 10, 1)), isFalse);
    expect(p.contiene(DateTime(2026, 8, 31)), isFalse);
  });

  test('restarMeses ajusta al último día del mes destino', () {
    expect(Periodo.restarMeses(DateTime(2026, 5, 31), 1), DateTime(2026, 4, 30));
    expect(Periodo.restarMeses(DateTime(2026, 1, 15), 2), DateTime(2025, 11, 15));
  });
}
