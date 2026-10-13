import 'package:flutter/material.dart';

import 'controles.dart';
import 'tabla.dart';

class TablaPaginada<T> extends StatefulWidget {
  const TablaPaginada({
    super.key,
    required this.columnas,
    required this.filas,
    this.tamano = 25,
    this.alTocar,
    this.esSeleccionada,
    this.mensajeVacio = 'No hay registros para mostrar.',
    this.pie,
  });

  final List<ColumnaTabla<T>> columnas;
  final List<T> filas;
  final int tamano;
  final void Function(T fila)? alTocar;
  final bool Function(T fila)? esSeleccionada;
  final String mensajeVacio;
  final List<Widget>? pie;

  @override
  State<TablaPaginada<T>> createState() => _TablaPaginadaState<T>();
}

class _TablaPaginadaState<T> extends State<TablaPaginada<T>> {
  int _pagina = 1;

  @override
  Widget build(BuildContext context) {
    final paginas = widget.filas.isEmpty ? 1 : (widget.filas.length + widget.tamano - 1) ~/ widget.tamano;
    final pagina = _pagina.clamp(1, paginas);
    final visibles = widget.filas.skip((pagina - 1) * widget.tamano).take(widget.tamano).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TablaDatos<T>(
          columnas: widget.columnas,
          filas: visibles,
          alTocar: widget.alTocar,
          esSeleccionada: widget.esSeleccionada,
          mensajeVacio: widget.mensajeVacio,
          pie: widget.pie,
        ),
        if (widget.filas.length > widget.tamano) ...[
          const SizedBox(height: 8),
          Paginador(
            pagina: pagina,
            tamano: widget.tamano,
            total: widget.filas.length,
            alCambiar: (nueva) => setState(() => _pagina = nueva),
          ),
        ],
      ],
    );
  }
}
