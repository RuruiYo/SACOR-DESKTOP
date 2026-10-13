import 'dart:math';

import 'package:flutter/material.dart';

import '../../nucleo/colores.dart';
import 'tarjeta.dart';

class ColumnaTabla<T> {
  const ColumnaTabla({
    required this.titulo,
    required this.celda,
    this.flex = 2,
    this.anchoMinimo = 110,
    this.numerica = false,
  });

  final String titulo;
  final Widget Function(T fila) celda;
  final int flex;
  final double anchoMinimo;

  final bool numerica;
}

class TablaDatos<T> extends StatefulWidget {
  const TablaDatos({
    super.key,
    required this.columnas,
    required this.filas,
    this.alTocar,
    this.esSeleccionada,
    this.mensajeVacio = 'No hay registros para mostrar.',
    this.pie,
  });

  final List<ColumnaTabla<T>> columnas;
  final List<T> filas;
  final void Function(T fila)? alTocar;
  final bool Function(T fila)? esSeleccionada;
  final String mensajeVacio;

  final List<Widget>? pie;

  @override
  State<TablaDatos<T>> createState() => _TablaDatosState<T>();
}

class _TablaDatosState<T> extends State<TablaDatos<T>> {
  final _desplazamiento = ScrollController();

  @override
  void dispose() {
    _desplazamiento.dispose();
    super.dispose();
  }

  Widget _celda(ColumnaTabla<T> columna, Widget hijo, {TextStyle? estilo}) => Expanded(
        flex: columna.flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Align(
            alignment: columna.numerica ? Alignment.centerRight : Alignment.centerLeft,
            child: DefaultTextStyle.merge(
              style: estilo ?? (columna.numerica ? Estilos.cifraTabla : Estilos.cuerpo),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              child: hijo,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, restricciones) {
      final minimo = widget.columnas.fold<double>(0, (suma, c) => suma + c.anchoMinimo) + 16;
      final ancho = restricciones.maxWidth.isFinite ? max(restricciones.maxWidth, minimo) : minimo;

      final contenido = SizedBox(
        width: ancho,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  for (final columna in widget.columnas)
                    _celda(columna, Text(columna.titulo.toUpperCase()), estilo: Estilos.encabezadoTabla),
                ],
              ),
            ),
            const Divider(),
            if (widget.filas.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Column(
                  children: [
                    const Icon(Icons.inbox_outlined, size: 28, color: ColoresSacor.textoTenue),
                    const SizedBox(height: 8),
                    Text(widget.mensajeVacio, style: Estilos.secundario, textAlign: TextAlign.center),
                  ],
                ),
              )
            else
              for (var i = 0; i < widget.filas.length; i++) ...[
                _FilaTabla(
                  seleccionada: widget.esSeleccionada?.call(widget.filas[i]) ?? false,
                  alTocar: widget.alTocar == null ? null : () => widget.alTocar!(widget.filas[i]),
                  child: Row(
                    children: [
                      for (final columna in widget.columnas) _celda(columna, columna.celda(widget.filas[i])),
                    ],
                  ),
                ),
                if (i < widget.filas.length - 1) const Divider(),
              ],
            if (widget.pie != null && widget.filas.isNotEmpty) ...[
              const Divider(color: ColoresSacor.bordeFuerte),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  children: [
                    for (var i = 0; i < widget.columnas.length; i++)
                      _celda(
                        widget.columnas[i],
                        i < widget.pie!.length ? widget.pie![i] : const SizedBox.shrink(),
                        estilo: Estilos.cifraTabla.copyWith(fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );

      if (ancho <= restricciones.maxWidth) return contenido;

      return Scrollbar(
        controller: _desplazamiento,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _desplazamiento,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 12),
          child: contenido,
        ),
      );
    });
  }
}

class _FilaTabla extends StatefulWidget {
  const _FilaTabla({required this.child, required this.seleccionada, this.alTocar});

  final Widget child;
  final bool seleccionada;
  final VoidCallback? alTocar;

  @override
  State<_FilaTabla> createState() => _FilaTablaState();
}

class _FilaTablaState extends State<_FilaTabla> {
  bool _encima = false;

  @override
  Widget build(BuildContext context) {
    final fondo = widget.seleccionada
        ? ColoresSacor.verdeSuave.withValues(alpha: 0.7)
        : (_encima && widget.alTocar != null ? ColoresSacor.hover : Colors.transparent);

    return MouseRegion(
      cursor: widget.alTocar == null ? MouseCursor.defer : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _encima = true),
      onExit: (_) => setState(() => _encima = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.alTocar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: fondo,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
          child: widget.child,
        ),
      ),
    );
  }
}

class CeldaDoble extends StatelessWidget {
  const CeldaDoble(this.principal, this.secundario, {super.key});

  final String principal;
  final String? secundario;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(principal, maxLines: 1, overflow: TextOverflow.ellipsis),
        if (secundario != null && secundario!.isNotEmpty)
          Text(secundario!, maxLines: 1, overflow: TextOverflow.ellipsis, style: Estilos.tenue),
      ],
    );
  }
}

class AccionesFila extends StatelessWidget {
  const AccionesFila({super.key, this.alEditar, this.alEliminar, this.extras = const []});

  final VoidCallback? alEditar;
  final VoidCallback? alEliminar;
  final List<Widget> extras;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...extras,
          if (alEditar != null)
            BotonFila(tooltip: 'Editar', icono: Icons.edit_outlined, alPresionar: alEditar!),
          if (alEliminar != null)
            BotonFila(tooltip: 'Eliminar', icono: Icons.delete_outline, color: ColoresSacor.rojo, alPresionar: alEliminar!),
          ],
        ),
      ),
    );
  }
}

class BotonFila extends StatelessWidget {
  const BotonFila({super.key, required this.tooltip, required this.icono, required this.alPresionar, this.color});

  final String tooltip;
  final IconData icono;
  final VoidCallback alPresionar;
  final Color? color;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        onPressed: alPresionar,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 32, height: 32),
        icon: Icon(icono, size: 18, color: color),
      );
}
