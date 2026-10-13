import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../calculos/contabilidad.dart';
import '../../configuracion/configuracion.dart';
import '../../dte/carpeta_dte.dart';
import '../../dte/documento_dte.dart';
import '../../exportacion/tabla_reporte.dart';
import '../../nucleo/formatos.dart';
import '../comunes/boton_exportar.dart';
import '../comunes/controles.dart';
import '../comunes/insignia.dart';
import '../comunes/tabla.dart';
import '../comunes/tabla_paginada.dart';
import '../comunes/tarjeta.dart';

class PantallaDte extends StatefulWidget {
  const PantallaDte({super.key});

  @override
  State<PantallaDte> createState() => _PantallaDteState();
}

class _PantallaDteState extends State<PantallaDte> {
  String? _carpeta;
  bool _carpetaElegida = false;
  List<DocumentoDte>? _documentos;
  String? _error;
  bool _cargando = false;
  DateTime? _mes;
  String? _tipo;

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
      final configurada = context.read<Configuracion>().carpetaDte;
      final elegida = await carpetaDteElegida();
      final carpeta = elegida ?? configurada ?? await carpetaDtePorDefecto();
      final documentos = await leerCarpetaDte(carpeta);
      if (!mounted) return;
      setState(() {
        _carpeta = carpeta;
        _carpetaElegida = elegida != null;
        _documentos = documentos..sort((a, b) => (b.fecha ?? DateTime(1900)).compareTo(a.fecha ?? DateTime(1900)));
      });
    } on Object catch (e) {
      debugPrint('Error al leer DTE: $e');
      if (mounted) setState(() => _error = 'No se pudo leer la carpeta de DTE.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _cambiarCarpeta() async {
    final ruta = await getDirectoryPath(initialDirectory: _carpeta, confirmButtonText: 'Usar esta carpeta');
    if (ruta == null) return;
    await guardarCarpetaDte(ruta);
    await _cargar();
    if (mounted) notificar(context, 'Carpeta de DTE: $ruta');
  }

  Future<void> _usarPredeterminada() async {
    await guardarCarpetaDte(null);
    await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final configuracion = context.read<Configuracion>();
    final nitEmpresa = configuracion.nitEmpresa;

    if (!carpetaDteDisponible) {
      return const Aviso(
        tono: TonoInsignia.info,
        mensaje: 'Los DTE se leen de una carpeta de la computadora: abra esta sección en la app de escritorio.',
      );
    }

    final todos = _documentos ?? const <DocumentoDte>[];
    final validos = todos.where((d) => d.valido).toList();
    final conError = todos.where((d) => !d.valido).toList();
    final meses = {for (final d in validos) if (d.fecha != null) DateTime(d.fecha!.year, d.fecha!.month)}.toList()
      ..sort((a, b) => b.compareTo(a));
    final tipos = {for (final d in validos) d.tipo}.toList()..sort();

    final filas = validos.where((d) {
      if (_tipo != null && d.tipo != _tipo) return false;
      if (_mes != null && (d.fecha == null || d.fecha!.year != _mes!.year || d.fecha!.month != _mes!.month)) return false;
      return true;
    }).toList();

    final recibidos = filas.where((d) => !d.emitidoPor(nitEmpresa));
    final emitidos = filas.where((d) => d.emitidoPor(nitEmpresa));
    double suma(Iterable<DocumentoDte> lista, double Function(DocumentoDte) valor) =>
        lista.fold(0, (t, d) => t + valor(d));
    final ivaCredito = suma(recibidos, (d) => d.iva);
    final ivaDebito = suma(emitidos, (d) => d.iva);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Tarjeta(
          child: Row(
            children: [
              const Icon(Icons.folder_outlined, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Carpeta de DTE', style: Estilos.negrita),
                    SelectableText(_carpeta ?? '…', style: Estilos.secundario),
                    const SizedBox(height: 2),
                    Text(
                      _carpetaElegida
                          ? 'Carpeta elegida en esta computadora. Guarde aquí los JSON de los DTE.'
                          : 'Guarde aquí los JSON de los DTE (por ejemplo, los que llegan al correo).',
                      style: Estilos.tenue,
                    ),
                    if (_carpetaElegida)
                      TextButton(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                        onPressed: _cargando ? null : _usarPredeterminada,
                        child: const Text('Usar la carpeta predeterminada'),
                      ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _cargando ? null : _cambiarCarpeta,
                icon: const Icon(Icons.drive_folder_upload_outlined, size: 18),
                label: const Text('Cambiar carpeta…'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _carpeta == null ? null : () => abrirCarpeta(_carpeta!),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Abrir carpeta'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _cargando ? null : _cargar,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Leer de nuevo'),
              ),
            ],
          ),
        ),
        if (_error != null) ...[const SizedBox(height: 12), Aviso(tono: TonoInsignia.error, mensaje: _error!)],
        if (nitEmpresa == null) ...[
          const SizedBox(height: 12),
          const Aviso(
            tono: TonoInsignia.info,
            mensaje: 'Todos los documentos se cuentan como recibidos (compras, IVA crédito fiscal).',
          ),
        ],
        if (conError.isNotEmpty) ...[
          const SizedBox(height: 12),
          Aviso(
            tono: TonoInsignia.alerta,
            titulo: '${conError.length} archivo(s) no se pudieron leer',
            mensaje: conError.map((d) => '${d.archivo}: ${d.error}').join('\n'),
          ),
        ],
        const SizedBox(height: 16),
        Tarjeta(
          child: ResumenCifras(cifras: [
            ('Documentos', Formatos.entero(filas.length)),
            ('Compras (recibidos)', Formatos.usd(aDinero(suma(recibidos, (d) => d.total)))),
            ('IVA crédito fiscal', Formatos.usd(aDinero(ivaCredito))),
            if (nitEmpresa != null) ...[
              ('Ventas (emitidos)', Formatos.usd(aDinero(suma(emitidos, (d) => d.total)))),
              ('IVA débito fiscal', Formatos.usd(aDinero(ivaDebito))),
              ('IVA débito − crédito', Formatos.usdConSigno(aDinero(ivaDebito - ivaCredito))),
            ],
          ]),
        ),
        const SizedBox(height: 16),
        Tarjeta(
          titulo: 'Documentos tributarios',
          acciones: [BotonExportar(generar: () => _reporte(context, filas, nitEmpresa))],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilaFiltros(filtros: [
                SelectorFiltro<DateTime?>(
                  etiqueta: 'Mes de emisión',
                  valor: _mes,
                  ancho: 200,
                  opciones: [(null, 'Todos'), for (final m in meses) (m, Formatos.mesLargo(m.year, m.month))],
                  alCambiar: (m) => setState(() => _mes = m),
                ),
                SelectorFiltro<String?>(
                  etiqueta: 'Tipo',
                  valor: _tipo,
                  ancho: 220,
                  opciones: [(null, 'Todos'), for (final t in tipos) (t, t)],
                  alCambiar: (t) => setState(() => _tipo = t),
                ),
              ]),
              const SizedBox(height: 12),
              if (_cargando && _documentos == null)
                const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Leyendo la carpeta…', style: Estilos.secundario)))
              else
                TablaPaginada<DocumentoDte>(
                  filas: filas,
                  mensajeVacio: 'No hay DTE en la carpeta. Copie ahí los archivos .json y pulse "Leer de nuevo".',
                  alTocar: (d) => _detalle(context, d),
                  columnas: [
                    ColumnaTabla(titulo: 'Emisión', celda: (d) => Text(Formatos.fecha(d.fecha))),
                    ColumnaTabla(titulo: 'Tipo', celda: (d) => Text(d.tipo)),
                    ColumnaTabla(titulo: 'Número de control', flex: 3, celda: (d) => Text(d.numeroControl ?? '—')),
                    ColumnaTabla(titulo: 'Emisor', flex: 3, celda: (d) => CeldaDoble(d.emisorNombre ?? '—', d.emisorNit)),
                    ColumnaTabla(titulo: 'Receptor', flex: 3, celda: (d) => CeldaDoble(d.receptorNombre ?? '—', d.receptorNit)),
                    ColumnaTabla(titulo: 'Gravado', numerica: true, celda: (d) => Text(Formatos.usd(aDinero(d.gravado)))),
                    ColumnaTabla(titulo: 'IVA', numerica: true, celda: (d) => Text(Formatos.usd(aDinero(d.iva)))),
                    ColumnaTabla(titulo: 'Total', numerica: true, celda: (d) => Text(Formatos.usd(aDinero(d.total)))),
                    ColumnaTabla(
                      titulo: '',
                      anchoMinimo: 110,
                      celda: (d) => d.emitidoPor(nitEmpresa)
                          ? const Insignia('Emitido', tono: TonoInsignia.exito)
                          : const Insignia('Recibido', tono: TonoInsignia.info),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _detalle(BuildContext context, DocumentoDte d) {
    Widget fila(String etiqueta, String? valor) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 170, child: Text(etiqueta, style: Estilos.secundario)),
              Expanded(child: SelectableText(valor ?? '—', style: Estilos.cuerpo)),
            ],
          ),
        );
    showDialog<void>(
      context: context,
      builder: (contexto) => DialogoFormulario(
        titulo: '${d.tipo} · ${Formatos.fecha(d.fecha)}',
        subtitulo: d.archivo,
        contenido: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            fila('Código de generación', d.codigoGeneracion),
            fila('Número de control', d.numeroControl),
            fila('Emisor', [d.emisorNombre, d.emisorNit, if (d.emisorNrc != null) 'NRC ${d.emisorNrc}'].whereType<String>().join(' · ')),
            fila('Receptor',
                [d.receptorNombre, d.receptorNit, if (d.receptorNrc != null) 'NRC ${d.receptorNrc}'].whereType<String>().join(' · ')),
            const Divider(height: 24),
            fila('Gravado', Formatos.usd(aDinero(d.gravado))),
            fila('Exento / no sujeto', Formatos.usd(aDinero(d.exento))),
            fila('IVA', Formatos.usd(aDinero(d.iva))),
            fila('Total', Formatos.usd(aDinero(d.total))),
          ],
        ),
        acciones: [FilledButton(onPressed: () => Navigator.of(contexto).pop(), child: const Text('Cerrar'))],
      ),
    );
  }

  TablaReporte _reporte(BuildContext context, List<DocumentoDte> filas, String? nitEmpresa) => TablaReporte(
        titulo: 'Documentos tributarios electrónicos',
        subtitulo: 'Carpeta: ${_carpeta ?? ''}',
        esDemo: context.read<Configuracion>().modoDemo,
        columnas: const [
          ColumnaReporte('Emisión', TipoColumna.fecha),
          ColumnaReporte('Tipo', TipoColumna.texto),
          ColumnaReporte('Número de control', TipoColumna.texto, flex: 3),
          ColumnaReporte('Emisor', TipoColumna.texto, flex: 3),
          ColumnaReporte('NIT emisor', TipoColumna.texto),
          ColumnaReporte('Receptor', TipoColumna.texto, flex: 3),
          ColumnaReporte('Gravado', TipoColumna.dinero),
          ColumnaReporte('Exento', TipoColumna.dinero),
          ColumnaReporte('IVA', TipoColumna.dinero),
          ColumnaReporte('Total', TipoColumna.dinero),
          ColumnaReporte('Dirección', TipoColumna.texto),
        ],
        filas: [
          for (final d in filas)
            [
              d.fecha, d.tipo, d.numeroControl, d.emisorNombre, d.emisorNit, d.receptorNombre, aDinero(d.gravado),
              aDinero(d.exento), aDinero(d.iva), aDinero(d.total), d.emitidoPor(nitEmpresa) ? 'Emitido' : 'Recibido',
            ],
        ],
      );
}
