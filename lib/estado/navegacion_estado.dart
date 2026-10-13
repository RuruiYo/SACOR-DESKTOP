import 'package:flutter/material.dart';

enum Seccion {
  empleados('Empleados', 'Planilla de empleados', Icons.badge_outlined, Icons.badge, 'Principal'),
  pesaje('Pesaje', 'Cuadro de pesaje', Icons.scale_outlined, Icons.scale, 'Principal'),
  movimiento('Movimiento contable', 'Movimiento contable', Icons.insert_chart_outlined, Icons.insert_chart, 'Principal',
      usaPeriodo: true),
  clientes('Clientes y contratos', 'Clientes, contratos y precios', Icons.storefront_outlined, Icons.storefront,
      'Registros'),
  serviciosExternos('Servicios externos', 'Servicios externos', Icons.delete_outline, Icons.delete, 'Registros'),
  salidas('Salidas y camiones', 'Salidas y camiones', Icons.local_shipping_outlined, Icons.local_shipping,
      'Registros'),
  viajesExtra('Viajes extra', 'Viajes extra', Icons.alt_route_outlined, Icons.alt_route, 'Registros'),
  solicitudesWeb('Solicitudes web', 'Cotizaciones y postulaciones de la web', Icons.language_outlined, Icons.language,
      'Sitio web'),
  dte('DTE', 'Documentos tributarios (DTE)', Icons.receipt_long_outlined, Icons.receipt_long, 'Control'),
  auditoria('Auditoría', 'Auditoría de cambios', Icons.history_outlined, Icons.history, 'Control');

  const Seccion(this.menu, this.titulo, this.icono, this.iconoActivo, this.grupo, {this.usaPeriodo = false});

  final String menu;
  final String titulo;
  final IconData icono;
  final IconData iconoActivo;
  final String grupo;

  final bool usaPeriodo;
}

class NavegacionEstado extends ChangeNotifier {
  Seccion _seccion = Seccion.empleados;

  Seccion get seccion => _seccion;

  int? contratoPendiente;

  void verViajesDeContrato(int idContrato) {
    contratoPendiente = idContrato;
    _seccion = Seccion.salidas;
    notifyListeners();
  }

  void ir(Seccion seccion) {
    if (seccion == _seccion) return;
    _seccion = seccion;
    notifyListeners();
  }

  void reiniciar() {
    _seccion = Seccion.empleados;
    notifyListeners();
  }
}
