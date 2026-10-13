import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sacor_desktop/nucleo/texto_fechado.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  test('lee un mes al inicio del texto', () {
    final t = TextoFechado.leer('[2026-08] Góndola 1-15 agosto');
    expect(t.fecha, DateTime(2026, 8));
    expect(t.soloMes, isTrue);
    expect(t.texto, 'Góndola 1-15 agosto');
    expect(t.fechaVisible, 'Agosto 2026');
  });

  test('lee un día al inicio del texto', () {
    final t = TextoFechado.leer('[2026-08-14] Plaza Mundo Apopa');
    expect(t.fecha, DateTime(2026, 8, 14));
    expect(t.soloMes, isFalse);
    expect(t.texto, 'Plaza Mundo Apopa');
    expect(t.fechaVisible, '14/08/2026');
  });

  test('sin prefijo o con fecha imposible queda sin fecha', () {
    for (final texto in ['Mantenimiento de báscula', '[2026-13] Raro', '[2026-02-30] Raro', 'Góndola [2026-08]', '']) {
      final t = TextoFechado.leer(texto);
      expect(t.fecha, isNull, reason: texto);
      expect(t.texto, texto.trim());
    }
  });

  test('escribe el prefijo de mes o de día', () {
    expect(TextoFechado.escribir(DateTime(2026, 8, 20), ' Góndola ', soloMes: true), '[2026-08] Góndola');
    expect(TextoFechado.escribir(DateTime(2026, 8, 2), 'Plaza Mundo Apopa'), '[2026-08-02] Plaza Mundo Apopa');
    expect(TextoFechado.escribir(null, 'Viaje extra'), 'Viaje extra');
  });

  test('ida y vuelta', () {
    final texto = TextoFechado.escribir(DateTime(2026, 10, 1), 'Retiro de poda', soloMes: true);
    final leido = TextoFechado.leer(texto);
    expect((leido.fecha, leido.texto, leido.soloMes), (DateTime(2026, 10), 'Retiro de poda', true));
  });
}
