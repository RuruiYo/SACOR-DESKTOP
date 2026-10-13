import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../nucleo/colores.dart';
import '../../nucleo/dinero.dart';
import '../../nucleo/formatos.dart';
import 'tarjeta.dart';

class CampoBusqueda extends StatefulWidget {
  const CampoBusqueda({super.key, required this.alCambiar, this.sugerencia = 'Buscar', this.ancho = 260});

  final ValueChanged<String> alCambiar;
  final String sugerencia;
  final double ancho;

  @override
  State<CampoBusqueda> createState() => _CampoBusquedaState();
}

class _CampoBusquedaState extends State<CampoBusqueda> {
  final _controlador = TextEditingController();
  Timer? _espera;

  @override
  void dispose() {
    _espera?.cancel();
    _controlador.dispose();
    super.dispose();
  }

  void _programar(String texto) {
    _espera?.cancel();
    _espera = Timer(const Duration(milliseconds: 350), () => widget.alCambiar(texto.trim()));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.ancho,
      child: TextField(
        controller: _controlador,
        onChanged: _programar,
        decoration: InputDecoration(
          hintText: widget.sugerencia,
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _controlador.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Limpiar búsqueda',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _controlador.clear();
                    _programar('');
                  },
                ),
        ),
      ),
    );
  }
}

class SelectorFiltro<T> extends StatelessWidget {
  const SelectorFiltro({
    super.key,
    required this.valor,
    required this.opciones,
    required this.alCambiar,
    this.ancho = 200,
    this.etiqueta,
  });

  final T valor;
  final List<(T, String)> opciones;
  final ValueChanged<T> alCambiar;
  final double ancho;
  final String? etiqueta;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancho,
      child: DropdownButtonFormField<T>(
        key: ValueKey<T>(valor),
        initialValue: valor,
        isExpanded: true,
        decoration: InputDecoration(labelText: etiqueta),
        borderRadius: BorderRadius.circular(8),
        dropdownColor: ColoresSacor.blanco,
        items: [
          for (final (opcion, texto) in opciones)
            DropdownMenuItem(value: opcion, child: Text(texto, overflow: TextOverflow.ellipsis)),
        ],
        onChanged: (nuevo) {
          if (nuevo != null || null is T) alCambiar(nuevo as T);
        },
      ),
    );
  }
}

class FilaFiltros extends StatelessWidget {
  const FilaFiltros({super.key, required this.filtros, this.acciones = const []});

  final List<Widget> filtros;
  final List<Widget> acciones;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: filtros)),
        if (acciones.isNotEmpty) ...[
          const SizedBox(width: 12),
          Wrap(spacing: 8, runSpacing: 8, children: acciones),
        ],
      ],
    );
  }
}

class Paginador extends StatelessWidget {
  const Paginador({super.key, required this.pagina, required this.tamano, required this.total, required this.alCambiar});

  final int pagina;
  final int tamano;
  final int total;
  final ValueChanged<int> alCambiar;

  @override
  Widget build(BuildContext context) {
    final paginas = total == 0 ? 1 : (total + tamano - 1) ~/ tamano;
    final desde = total == 0 ? 0 : (pagina - 1) * tamano + 1;
    final hasta = (pagina * tamano).clamp(0, total);

    return Row(
      children: [
        Text(
          total == 0 ? 'Sin registros' : 'Mostrando ${Formatos.entero(desde)}–${Formatos.entero(hasta)} de ${Formatos.entero(total)}',
          style: Estilos.secundario,
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Página anterior',
          onPressed: pagina > 1 ? () => alCambiar(pagina - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('Página $pagina de $paginas', style: Estilos.secundario),
        IconButton(
          tooltip: 'Página siguiente',
          onPressed: pagina < paginas ? () => alCambiar(pagina + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class ResumenCifras extends StatelessWidget {
  const ResumenCifras({super.key, required this.cifras});

  final List<(String, String)> cifras;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 28,
      runSpacing: 8,
      children: [
        for (final (etiqueta, valor) in cifras)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(etiqueta, style: Estilos.tenue),
              const SizedBox(height: 2),
              Text(valor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ColoresSacor.texto)),
            ],
          ),
      ],
    );
  }
}

class CampoMonto extends StatelessWidget {
  const CampoMonto({
    super.key,
    required this.controlador,
    required this.etiqueta,
    this.ayuda,
    this.permitirCero = false,
    this.obligatorio = true,
    this.alCambiar,
    this.validacionExtra,
    this.autofocus = false,
  });

  final TextEditingController controlador;
  final String etiqueta;
  final String? ayuda;
  final bool permitirCero;
  final bool obligatorio;
  final ValueChanged<String>? alCambiar;
  final String? Function(Dinero monto)? validacionExtra;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controlador,
      autofocus: autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      onChanged: alCambiar,
      decoration: InputDecoration(labelText: etiqueta, prefixText: r'$ ', helperText: ayuda, helperMaxLines: 2),
      validator: (texto) {
        final valor = texto?.trim() ?? '';
        if (valor.isEmpty) return obligatorio ? 'Ingrese el monto.' : null;
        final monto = Dinero.interpretar(valor);
        if (monto == null) return 'Monto inválido (máximo dos decimales).';
        if (!permitirCero && monto.esCero) return 'El monto debe ser mayor que cero.';
        return validacionExtra?.call(monto);
      },
    );
  }
}

class DialogoFormulario extends StatelessWidget {
  const DialogoFormulario({
    super.key,
    required this.titulo,
    required this.contenido,
    required this.acciones,
    this.subtitulo,
    this.ancho = 560,
  });

  final String titulo;
  final String? subtitulo;
  final Widget contenido;
  final List<Widget> acciones;
  final double ancho;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: ancho, maxHeight: MediaQuery.sizeOf(context).height - 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        if (subtitulo != null) ...[
                          const SizedBox(height: 4),
                          Text(subtitulo!, style: Estilos.secundario),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
                child: contenido,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 10,
                runSpacing: 8,
                children: acciones,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BotonOcupado extends StatelessWidget {
  const BotonOcupado({super.key, required this.texto, required this.ocupado, required this.alPresionar, this.peligro = false});

  final String texto;
  final bool ocupado;
  final VoidCallback? alPresionar;
  final bool peligro;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: peligro ? FilledButton.styleFrom(backgroundColor: ColoresSacor.rojo) : null,
      onPressed: ocupado ? null : alPresionar,
      child: ocupado
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: ColoresSacor.blanco))
          : Text(texto),
    );
  }
}

void notificar(BuildContext context, String mensaje, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      backgroundColor: error ? ColoresSacor.rojoTexto : ColoresSacor.texto,
      content: Row(
        children: [
          Icon(error ? Icons.error_outline : Icons.check_circle_outline, color: ColoresSacor.blanco, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(mensaje)),
        ],
      ),
    ));
}
