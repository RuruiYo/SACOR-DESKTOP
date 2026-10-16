import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../estado/almacen.dart';
import '../../estado/navegacion_estado.dart';
import '../../estado/sesion_estado.dart';
import '../auditoria/pantalla_auditoria.dart';
import '../clientes/pantalla_clientes.dart';
import '../comunes/estado_vista.dart';
import '../empleados/pantalla_empleados.dart';
import '../movimiento/pantalla_movimiento.dart';
import '../pesaje/pantalla_pesaje.dart';
import '../salidas/pantalla_salidas.dart';
import '../servicios_externos/pantalla_servicios_externos.dart';
import '../solicitudes_web/pantalla_solicitudes_web.dart';
import '../viajes/pantalla_viajes.dart';
import 'barra_lateral.dart';
import 'encabezado.dart';

class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    final sesion = context.read<SesionEstado>();
    return Listener(
      onPointerDown: (_) => sesion.registrarActividad(),
      child: Focus(
        onKeyEvent: (_, _) {
          sesion.registrarActividad();
          return KeyEventResult.ignored;
        },
        child: Scaffold(
          body: LayoutBuilder(
            builder: (context, restricciones) {
              final compacta = restricciones.maxWidth < 1180;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BarraLateral(compacta: compacta),
                  const VerticalDivider(width: 1),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Encabezado(),
                        Divider(),
                        Expanded(child: _Contenido()),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido();

  @override
  Widget build(BuildContext context) {
    final seccion = context.select<NavegacionEstado, Seccion>((n) => n.seccion);
    final almacen = context.watch<AlmacenSacor>();

    if (!almacen.listo) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: almacen.error != null
              ? ErrorDeCarga(mensaje: almacen.error!, alReintentar: almacen.cargarTodo)
              : const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Cargando datos de SACOR…'),
                  ],
                ),
        ),
      );
    }

    final pantalla = switch (seccion) {
      Seccion.empleados => const PantallaEmpleados(),
      Seccion.pesaje => const PantallaPesaje(),
      Seccion.movimiento => const PantallaMovimiento(),
      Seccion.clientes => const PantallaClientes(),
      Seccion.serviciosExternos => const PantallaServiciosExternos(),
      Seccion.salidas => const PantallaSalidas(),
      Seccion.viajesExtra => const PantallaViajes(),
      Seccion.solicitudesWeb => const PantallaSolicitudesWeb(),
      Seccion.auditoria => const PantallaAuditoria(),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      layoutBuilder: (actual, anteriores) => Stack(
        fit: StackFit.expand,
        alignment: Alignment.topCenter,
        children: [...anteriores, ?actual],
      ),
      child: SingleChildScrollView(
        key: ValueKey(seccion),
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1600), child: pantalla),
        ),
      ),
    );
  }
}
