import 'package:intl/intl.dart';

import 'dinero.dart';

abstract final class Formatos {
  static final _usd = NumberFormat.currency(locale: 'en_US', symbol: r'$', decimalDigits: 2);
  static final _entero = NumberFormat('#,##0', 'en_US');
  static final _decimal = NumberFormat('#,##0.0', 'en_US');
  static final _dosDecimales = NumberFormat('#,##0.00', 'en_US');
  static final _fecha = DateFormat('dd/MM/yyyy');
  static final _fechaHora = DateFormat('dd/MM/yyyy HH:mm');
  static final _iso = DateFormat('yyyy-MM-dd');

  static String usd(Dinero monto) => _usd.format(monto.comoDouble);

  static String usdConSigno(Dinero monto) =>
      monto.esPositivo ? '+${usd(monto)}' : usd(monto);

  static String usdCompacto(num valor) {
    final absoluto = valor.abs();
    final signo = valor < 0 ? '-' : '';
    if (absoluto >= 1000000) return '$signo\$${_recortar(absoluto / 1000000)} M';
    if (absoluto >= 1000) return '$signo\$${_recortar(absoluto / 1000)} k';
    return '$signo\$${_entero.format(absoluto)}';
  }

  static String _recortar(num valor) {
    final texto = valor >= 100 ? _entero.format(valor) : _decimal.format(valor);
    return texto.endsWith('.0') ? texto.substring(0, texto.length - 2) : texto;
  }

  static String entero(int valor) => _entero.format(valor);

  static String decimal(num valor) => _dosDecimales.format(valor);

  static String porcentaje(double valor) => '${_decimal.format(valor)}%';

  static String peso(num kilogramos) => '${_entero.format(kilogramos)} kg';

  static String fecha(DateTime? valor) => valor == null ? 'Sin fecha' : _fecha.format(valor);

  static String fechaHora(DateTime valor) => _fechaHora.format(valor);

  static String fechaIso(DateTime valor) => _iso.format(valor);

  static String mesCorto(int anio, int mes) =>
      _capitalizar(DateFormat('MMM yy', 'es').format(DateTime(anio, mes)).replaceAll('.', ''));

  static String mesLargo(int anio, int mes) =>
      _capitalizar(DateFormat('MMMM yyyy', 'es').format(DateTime(anio, mes)));

  static String nombreMes(int mes) => _capitalizar(DateFormat('MMMM', 'es').format(DateTime(2000, mes)));

  static String _capitalizar(String texto) =>
      texto.isEmpty ? texto : texto[0].toUpperCase() + texto.substring(1);

  static String iniciales(String nombre) {
    final partes = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes.first[0] + partes.last[0]).toUpperCase();
  }
}
