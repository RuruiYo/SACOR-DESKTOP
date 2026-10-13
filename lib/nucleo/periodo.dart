import 'formatos.dart';

enum PresetPeriodo {
  mesActual('Mes actual'),
  mesAnterior('Mes anterior'),
  ultimos3Meses('Últimos 3 meses'),
  ultimos6Meses('Últimos 6 meses'),
  anioActual('Año actual'),
  anioAnterior('Año anterior'),
  personalizado('Personalizado');

  const PresetPeriodo(this.etiqueta);

  final String etiqueta;
}

class Periodo {
  const Periodo({
    required this.preset,
    required this.desde,
    required this.hasta,
    required this.desdeAnterior,
    required this.hastaAnterior,
  });

  factory Periodo.desdePreset(PresetPeriodo preset, DateTime hoy) {
    final dia = soloFecha(hoy);
    final inicioMes = DateTime(dia.year, dia.month, 1);

    switch (preset) {
      case PresetPeriodo.mesActual:
        return Periodo(
          preset: preset,
          desde: inicioMes,
          hasta: dia,
          desdeAnterior: restarMeses(inicioMes, 1),
          hastaAnterior: restarMeses(dia, 1),
        );
      case PresetPeriodo.mesAnterior:
        final desde = restarMeses(inicioMes, 1);
        final desdeAnterior = restarMeses(inicioMes, 2);
        return Periodo(
          preset: preset,
          desde: desde,
          hasta: ultimoDiaDelMes(desde),
          desdeAnterior: desdeAnterior,
          hastaAnterior: ultimoDiaDelMes(desdeAnterior),
        );
      case PresetPeriodo.ultimos3Meses:
      case PresetPeriodo.ultimos6Meses:
        final meses = preset == PresetPeriodo.ultimos3Meses ? 3 : 6;
        final desde = restarMeses(inicioMes, meses - 1);
        return Periodo(
          preset: preset,
          desde: desde,
          hasta: dia,
          desdeAnterior: restarMeses(desde, meses),
          hastaAnterior: restarMeses(dia, meses),
        );
      case PresetPeriodo.anioActual:
        final desde = DateTime(dia.year, 1, 1);
        return Periodo(
          preset: preset,
          desde: desde,
          hasta: dia,
          desdeAnterior: DateTime(dia.year - 1, 1, 1),
          hastaAnterior: restarMeses(dia, 12),
        );
      case PresetPeriodo.anioAnterior:
        return Periodo(
          preset: preset,
          desde: DateTime(dia.year - 1, 1, 1),
          hasta: DateTime(dia.year - 1, 12, 31),
          desdeAnterior: DateTime(dia.year - 2, 1, 1),
          hastaAnterior: DateTime(dia.year - 2, 12, 31),
        );
      case PresetPeriodo.personalizado:
        return Periodo.personalizado(inicioMes, dia);
    }
  }

  factory Periodo.personalizado(DateTime desde, DateTime hasta) {
    final inicio = soloFecha(desde);
    final fin = soloFecha(hasta);
    final dias = diasEntre(inicio, fin);
    return Periodo(
      preset: PresetPeriodo.personalizado,
      desde: inicio,
      hasta: fin,
      desdeAnterior: DateTime(inicio.year, inicio.month, inicio.day - dias),
      hastaAnterior: DateTime(inicio.year, inicio.month, inicio.day - 1),
    );
  }

  final PresetPeriodo preset;
  final DateTime desde;
  final DateTime hasta;
  final DateTime desdeAnterior;
  final DateTime hastaAnterior;

  int get dias => diasEntre(desde, hasta);

  String get etiqueta => preset.etiqueta;

  String get rango => '${Formatos.fecha(desde)} – ${Formatos.fecha(hasta)}';

  String get rangoAnterior => '${Formatos.fecha(desdeAnterior)} – ${Formatos.fecha(hastaAnterior)}';

  bool contiene(DateTime fecha) {
    final dia = soloFecha(fecha);
    return !dia.isBefore(desde) && !dia.isAfter(hasta);
  }

  bool contieneAnterior(DateTime fecha) {
    final dia = soloFecha(fecha);
    return !dia.isBefore(desdeAnterior) && !dia.isAfter(hastaAnterior);
  }

  @override
  bool operator ==(Object other) =>
      other is Periodo &&
      other.preset == preset &&
      other.desde == desde &&
      other.hasta == hasta &&
      other.desdeAnterior == desdeAnterior &&
      other.hastaAnterior == hastaAnterior;

  @override
  int get hashCode => Object.hash(preset, desde, hasta, desdeAnterior, hastaAnterior);

  static DateTime soloFecha(DateTime fecha) => DateTime(fecha.year, fecha.month, fecha.day);

  static DateTime ultimoDiaDelMes(DateTime fecha) => DateTime(fecha.year, fecha.month + 1, 0);

  static DateTime restarMeses(DateTime fecha, int meses) {
    final destino = DateTime(fecha.year, fecha.month - meses, 1);
    final ultimo = ultimoDiaDelMes(destino).day;
    return DateTime(destino.year, destino.month, fecha.day > ultimo ? ultimo : fecha.day);
  }

  static int diasEntre(DateTime desde, DateTime hasta) =>
      DateTime.utc(hasta.year, hasta.month, hasta.day)
          .difference(DateTime.utc(desde.year, desde.month, desde.day))
          .inDays +
      1;
}
