import 'formatos.dart';

class TextoFechado {
  const TextoFechado(this.fecha, this.texto, {this.soloMes = false});

  final DateTime? fecha;
  final String texto;
  final bool soloMes;

  bool get tieneFecha => fecha != null;

  static final _patron = RegExp(r'^\s*\[(\d{4})-(\d{2})(?:-(\d{2}))?\]\s*(.*)$', dotAll: true);

  static TextoFechado leer(String? original) {
    final valor = original ?? '';
    final coincidencia = _patron.firstMatch(valor);
    if (coincidencia == null) return TextoFechado(null, valor.trim());

    final anio = int.parse(coincidencia.group(1)!);
    final mes = int.parse(coincidencia.group(2)!);
    final diaTexto = coincidencia.group(3);
    final dia = diaTexto == null ? 1 : int.parse(diaTexto);
    final fecha = DateTime(anio, mes, dia);

    if (mes < 1 || mes > 12 || fecha.month != mes || fecha.day != dia) return TextoFechado(null, valor.trim());

    return TextoFechado(fecha, coincidencia.group(4)!.trim(), soloMes: diaTexto == null);
  }

  static String escribir(DateTime? fecha, String texto, {bool soloMes = false}) {
    final limpio = texto.trim();
    if (fecha == null) return limpio;
    final prefijo = soloMes
        ? '${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}'
        : Formatos.fechaIso(fecha);
    return '[$prefijo] $limpio';
  }

  String get fechaVisible {
    final f = fecha;
    if (f == null) return 'Sin fecha';
    return soloMes ? Formatos.mesLargo(f.year, f.month) : Formatos.fecha(f);
  }
}
