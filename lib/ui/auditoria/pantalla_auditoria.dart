import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../datos/cliente_api.dart';
import '../../datos/modelos/auditoria.dart';
import '../../datos/recurso.dart';
import '../../estado/almacen.dart';
import '../../nucleo/formatos.dart';
import '../comunes/controles.dart';
import '../comunes/estado_vista.dart';
import '../comunes/insignia.dart';
import '../comunes/tabla.dart';
import '../comunes/tarjeta.dart';

class PantallaAuditoria extends StatefulWidget {
  const PantallaAuditoria({super.key});

  @override
  State<PantallaAuditoria> createState() => _PantallaAuditoriaState();
}

class _PantallaAuditoriaState extends State<PantallaAuditoria> {
  static const _tamano = 50;

  int _pagina = 1;
  String? _tabla;
  PaginaAuditoria? _datos;
  String? _error;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final datos = await context
          .read<AlmacenSacor>()
          .fuente
          .consultarAuditoria(pagina: _pagina, tamano: _tamano, tabla: _tabla);
      if (mounted) setState(() => _datos = datos);
    } on ApiExcepcion catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final almacen = context.watch<AlmacenSacor>();
    final datos = _datos;

    if (datos == null && _error != null) return ErrorDeCarga(mensaje: _error!, alReintentar: _cargar);

    return Tarjeta(
      titulo: 'Historial de cambios',
      subtitulo: 'Toque un registro para ver los valores antes y después del cambio.',
      acciones: [
        IconButton(tooltip: 'Actualizar', onPressed: _cargando ? null : _cargar, icon: const Icon(Icons.refresh)),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilaFiltros(filtros: [
            SelectorFiltro<String?>(
              etiqueta: 'Tabla',
              valor: _tabla,
              ancho: 240,
              opciones: [(null, 'Todas'), for (final r in Recurso.values) (r.tabla, '${r.nombre} (${r.tabla})')],
              alCambiar: (t) {
                _tabla = t;
                _pagina = 1;
                _cargar();
              },
            ),
          ]),
          const SizedBox(height: 12),
          if (_error != null) ...[Aviso(tono: TonoInsignia.error, mensaje: _error!), const SizedBox(height: 12)],
          if (datos == null)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else ...[
            Opacity(
              opacity: _cargando ? 0.55 : 1,
              child: TablaDatos<RegistroAuditoria>(
                filas: datos.datos,
                mensajeVacio: 'No hay cambios registrados.',
                alTocar: (r) => _detalle(context, r, almacen),
                columnas: [
                  ColumnaTabla(titulo: 'Fecha y hora', celda: (r) => Text(Formatos.fechaHora(r.fechaHora))),
                  ColumnaTabla(
                    titulo: 'Usuario',
                    flex: 3,
                    celda: (r) => Text(r.idEmpleado == null ? 'Sin usuario' : almacen.nombreEmpleado(r.idEmpleado!)),
                  ),
                  ColumnaTabla(titulo: 'Tabla', celda: (r) => Text(r.tabla)),
                  ColumnaTabla(titulo: 'Acción', anchoMinimo: 110, celda: (r) => _InsigniaAccion(r.accion)),
                  ColumnaTabla(titulo: 'Registro', celda: (r) => Text('#${r.idRegistro}')),
                  ColumnaTabla(titulo: 'Detalle', flex: 4, celda: (r) => Text(r.detalle ?? '—')),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Paginador(
              pagina: datos.pagina,
              tamano: datos.tamano,
              total: datos.total,
              alCambiar: (p) {
                _pagina = p;
                _cargar();
              },
            ),
          ],
        ],
      ),
    );
  }

  void _detalle(BuildContext context, RegistroAuditoria r, AlmacenSacor almacen) {
    String bonito(String? texto) {
      if (texto == null) return '—';
      try {
        return const JsonEncoder.withIndent('  ').convert(jsonDecode(texto));
      } on FormatException {
        return texto;
      }
    }

    Widget bloque(String titulo, String? valor) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(titulo, style: Estilos.negrita),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)),
                child: SelectableText(bonito(valor), style: const TextStyle(fontFamily: 'Consolas', fontSize: 12.5)),
              ),
            ],
          ),
        );

    showDialog<void>(
      context: context,
      builder: (contexto) => DialogoFormulario(
        titulo: '${r.accion} en ${r.tabla} #${r.idRegistro}',
        subtitulo:
            '${Formatos.fechaHora(r.fechaHora)} · ${r.idEmpleado == null ? 'Sin usuario' : almacen.nombreEmpleado(r.idEmpleado!)}'
            '${r.detalle == null ? '' : ' · ${r.detalle}'}',
        ancho: 900,
        contenido: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [bloque('Antes', r.valorAnterior), const SizedBox(width: 16), bloque('Después', r.valorNuevo)],
        ),
        acciones: [FilledButton(onPressed: () => Navigator.of(contexto).pop(), child: const Text('Cerrar'))],
      ),
    );
  }
}

class _InsigniaAccion extends StatelessWidget {
  const _InsigniaAccion(this.accion);

  final String accion;

  @override
  Widget build(BuildContext context) => switch (accion) {
        'INSERT' => const Insignia('Alta', tono: TonoInsignia.exito, icono: Icons.add_circle_outline),
        'UPDATE' => const Insignia('Edición', tono: TonoInsignia.info, icono: Icons.edit_outlined),
        'DELETE' => const Insignia('Baja', tono: TonoInsignia.error, icono: Icons.delete_outline),
        _ => Insignia(accion),
      };
}
