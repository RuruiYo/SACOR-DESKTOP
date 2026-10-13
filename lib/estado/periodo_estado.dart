import 'package:flutter/foundation.dart';

import '../nucleo/periodo.dart';

class PeriodoEstado extends ChangeNotifier {
  PeriodoEstado({DateTime Function()? reloj})
      : _reloj = reloj ?? DateTime.now,
        _periodo = Periodo.desdePreset(PresetPeriodo.mesActual, (reloj ?? DateTime.now)());

  final DateTime Function() _reloj;
  Periodo _periodo;
  int _version = 0;

  Periodo get periodo => _periodo;

  DateTime get hoy => Periodo.soloFecha(_reloj());

  int get version => _version;

  void seleccionarPreset(PresetPeriodo preset) {
    _periodo = Periodo.desdePreset(preset, _reloj());
    _version++;
    notifyListeners();
  }

  void seleccionarRango(DateTime desde, DateTime hasta) {
    _periodo = Periodo.personalizado(desde, hasta);
    _version++;
    notifyListeners();
  }

  void refrescar() {
    if (_periodo.preset != PresetPeriodo.personalizado) {
      _periodo = Periodo.desdePreset(_periodo.preset, _reloj());
    }
    _version++;
    notifyListeners();
  }
}
