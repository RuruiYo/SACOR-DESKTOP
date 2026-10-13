import 'dinero.dart';
import 'formatos.dart';

enum Tendencia { sube, baja, igual, sinBase }

class Variacion {
  const Variacion._(this.porcentaje, this.tendencia);

  factory Variacion.calcular(num actual, num anterior) {
    if (anterior == 0) return const Variacion._(null, Tendencia.sinBase);

    final porcentaje = (actual - anterior) / anterior.abs() * 100;

    if (porcentaje.abs() < 0.05) return Variacion._(porcentaje, Tendencia.igual);
    return Variacion._(porcentaje, porcentaje > 0 ? Tendencia.sube : Tendencia.baja);
  }

  factory Variacion.dinero(Dinero actual, Dinero anterior) =>
      Variacion.calcular(actual.centavos, anterior.centavos);

  final double? porcentaje;
  final Tendencia tendencia;

  bool get calculable => tendencia != Tendencia.sinBase;

  String get descripcion {
    switch (tendencia) {
      case Tendencia.sinBase:
        return 'Sin datos del período anterior para comparar';
      case Tendencia.igual:
        return 'Sin cambio vs. período anterior';
      case Tendencia.sube:
      case Tendencia.baja:
        return '${Formatos.porcentaje(porcentaje!.abs())} vs. período anterior';
    }
  }

  String get corta {
    if (!calculable) return 'N/D';
    final signo = porcentaje! > 0.05 ? '+' : (porcentaje! < -0.05 ? '-' : '');
    return '$signo${Formatos.porcentaje(porcentaje!.abs())}';
  }

  bool? esFavorable({required bool subirEsBueno}) {
    switch (tendencia) {
      case Tendencia.sube:
        return subirEsBueno;
      case Tendencia.baja:
        return !subirEsBueno;
      case Tendencia.igual:
      case Tendencia.sinBase:
        return null;
    }
  }
}
