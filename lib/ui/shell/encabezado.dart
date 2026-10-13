import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../configuracion/configuracion.dart';
import '../../estado/almacen.dart';
import '../../estado/navegacion_estado.dart';
import '../../estado/periodo_estado.dart';
import '../../estado/sesion_estado.dart';
import '../../nucleo/colores.dart';
import '../../nucleo/formatos.dart';
import '../../nucleo/periodo.dart';
import '../comunes/controles.dart';
import '../comunes/tarjeta.dart';

class Encabezado extends StatelessWidget {
  const Encabezado({super.key});

  @override
  Widget build(BuildContext context) {
    final seccion = context.select<NavegacionEstado, Seccion>((n) => n.seccion);
    final almacen = context.watch<AlmacenSacor>();
    final demo = context.read<Configuracion>().modoDemo;
    final actualizado = almacen.actualizado;

    final subtitulo = almacen.cargando
        ? 'Actualizando datos…'
        : actualizado == null
            ? ''
            : '${demo ? 'Datos de demostración' : 'Datos'} al ${Formatos.fechaHora(actualizado)}';

    return Container(
      color: ColoresSacor.blanco,
      padding: const EdgeInsets.fromLTRB(28, 16, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(seccion.titulo, style: Estilos.tituloPantalla, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(subtitulo, style: Estilos.secundario, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (seccion.usaPeriodo) ...[const Flexible(child: SelectorPeriodo()), const SizedBox(width: 4)],
          IconButton(
            tooltip: 'Actualizar datos',
            onPressed: almacen.cargando
                ? null
                : () async {
                    await almacen.cargarTodo();
                    if (context.mounted && almacen.error != null) notificar(context, almacen.error!, error: true);
                  },
            icon: almacen.cargando
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
          const _MenuUsuario(),
        ],
      ),
    );
  }
}

class SelectorPeriodo extends StatelessWidget {
  const SelectorPeriodo({super.key});

  Future<void> _elegirRango(BuildContext context) async {
    final estado = context.read<PeriodoEstado>();
    final actual = estado.periodo;
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(estado.hoy.year + 1, 12, 31),
      initialDateRange: DateTimeRange(start: actual.desde, end: actual.hasta),
      helpText: 'Período a consultar',
      saveText: 'Aplicar',
      builder: (context, hijo) => Center(
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640), child: hijo),
      ),
    );
    if (rango != null) estado.seleccionarRango(rango.start, rango.end);
  }

  @override
  Widget build(BuildContext context) {
    final periodo = context.watch<PeriodoEstado>().periodo;

    return MenuAnchor(
      alignmentOffset: const Offset(0, 6),
      menuChildren: [
        for (final preset in PresetPeriodo.values.where((p) => p != PresetPeriodo.personalizado))
          MenuItemButton(
            leadingIcon: SizedBox(
              width: 18,
              child: periodo.preset == preset ? const Icon(Icons.check, size: 16, color: ColoresSacor.verde) : null,
            ),
            onPressed: () => context.read<PeriodoEstado>().seleccionarPreset(preset),
            child: Text(preset.etiqueta),
          ),
        const Divider(),
        MenuItemButton(
          leadingIcon: SizedBox(
            width: 18,
            child: periodo.preset == PresetPeriodo.personalizado
                ? const Icon(Icons.check, size: 16, color: ColoresSacor.verde)
                : null,
          ),
          onPressed: () => _elegirRango(context),
          child: const Text('Rango personalizado…'),
        ),
      ],
      builder: (context, controlador, _) => OutlinedButton.icon(
        onPressed: () => controlador.isOpen ? controlador.close() : controlador.open(),
        icon: const Icon(Icons.calendar_month_outlined, size: 18),
        label: Text(
          '${periodo.etiqueta} · ${Formatos.fecha(periodo.desde)} – ${Formatos.fecha(periodo.hasta)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _MenuUsuario extends StatelessWidget {
  const _MenuUsuario();

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<SesionEstado>().usuario;
    if (usuario == null) return const SizedBox.shrink();

    return MenuAnchor(
      alignmentOffset: const Offset(0, 6),
      menuChildren: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(usuario.nombre, style: Estilos.negrita),
              const Text('Administrador operativo', style: Estilos.tenue),
            ],
          ),
        ),
        const Divider(),
        MenuItemButton(
          leadingIcon: const Icon(Icons.logout, size: 18),
          onPressed: () => context.read<SesionEstado>().cerrarSesion(),
          child: const Text('Cerrar sesión'),
        ),
      ],
      builder: (context, controlador, _) => InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => controlador.isOpen ? controlador.close() : controlador.open(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: ColoresSacor.verdeSuave,
                child: Text(
                  Formatos.iniciales(usuario.nombre),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ColoresSacor.verdeOscuro),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(usuario.nombre, style: Estilos.negrita.copyWith(fontSize: 13)),
                  const Text('Administrador operativo', style: Estilos.tenue),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more, size: 18, color: ColoresSacor.textoTenue),
            ],
          ),
        ),
      ),
    );
  }
}
