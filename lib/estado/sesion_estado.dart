import 'dart:async';

import 'package:flutter/foundation.dart';

import '../datos/cliente_api.dart';
import '../datos/modelos/entidades.dart';
import 'almacen.dart';

class SesionEstado extends ChangeNotifier {
  SesionEstado(this._almacen, {DateTime Function()? reloj, this.inactividadMaxima = const Duration(minutes: 30)})
      : _reloj = reloj ?? DateTime.now;

  final AlmacenSacor _almacen;
  final DateTime Function() _reloj;
  final Duration inactividadMaxima;

  static const intentosMaximos = 5;
  static const bloqueo = Duration(minutes: 1);

  Empleado? _usuario;
  bool _cargando = false;
  String? _error;
  String? _aviso;
  int _fallidos = 0;
  DateTime? _bloqueadoHasta;
  Timer? _temporizador;

  Empleado? get usuario => _usuario;
  bool get autenticado => _usuario != null;
  bool get cargando => _cargando;

  String? get error => _error;

  String? get aviso => _aviso;

  Future<bool> iniciarSesion(String codigo) async {
    if (_cargando) return false;

    final bloqueado = _bloqueadoHasta;
    if (bloqueado != null && _reloj().isBefore(bloqueado)) {
      _error = 'Demasiados intentos fallidos. Espere un minuto e intente de nuevo.';
      notifyListeners();
      return false;
    }

    final limpio = codigo.trim().toUpperCase();
    if (limpio.isEmpty) {
      _error = 'Ingrese su código de empleado.';
      notifyListeners();
      return false;
    }

    _cargando = true;
    _error = null;
    _aviso = null;
    notifyListeners();

    try {
      final empleados = await _almacen.cargarEmpleados();
      final encontrado = empleados.where((e) => e.codigo.trim().toUpperCase() == limpio).firstOrNull;

      if (encontrado == null || !encontrado.esAdministrador || !encontrado.activo) {
        _fallidos++;
        if (_fallidos >= intentosMaximos) {
          _fallidos = 0;
          _bloqueadoHasta = _reloj().add(bloqueo);
        }
        _error = 'Código incorrecto, o el empleado no es un administrador activo.';
        return false;
      }

      _fallidos = 0;
      _usuario = encontrado;
      _almacen.idUsuario = encontrado.id;
      registrarActividad();
      unawaited(_almacen.cargarTodo());
      return true;
    } on ApiExcepcion catch (e) {
      _error = e.mensaje;
      return false;
    } on Object catch (e) {
      debugPrint('Error inesperado al iniciar sesión: $e');
      _error = 'No se pudo iniciar sesión. Intente de nuevo.';
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  void registrarActividad() {
    if (_usuario == null) return;
    _temporizador?.cancel();
    _temporizador = Timer(inactividadMaxima, _porInactividad);
  }

  void _porInactividad() {
    if (_usuario == null) return;
    _salir('La sesión se cerró por inactividad. Ingrese su código nuevamente.');
  }

  void cerrarSesion() => _salir('Sesión cerrada correctamente.');

  void _salir(String aviso) {
    _temporizador?.cancel();
    _usuario = null;
    _error = null;
    _aviso = aviso;
    _almacen.limpiar();
    notifyListeners();
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }
}
