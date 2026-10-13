import 'package:flutter/material.dart';

import '../../exportacion/exportar_csv.dart';
import '../../exportacion/exportar_excel.dart';
import '../../exportacion/exportar_pdf.dart';
import '../../exportacion/guardar_archivo.dart';
import '../../exportacion/tabla_reporte.dart';
import 'controles.dart';

class BotonExportar extends StatefulWidget {
  const BotonExportar({super.key, required this.generar});

  final TablaReporte Function() generar;

  @override
  State<BotonExportar> createState() => _BotonExportarState();
}

class _BotonExportarState extends State<BotonExportar> {
  bool _ocupado = false;

  Future<void> _exportar(String formato) async {
    setState(() => _ocupado = true);
    try {
      final tabla = widget.generar();
      final ahora = DateTime.now();
      final (bytes, descripcion) = switch (formato) {
        'csv' => (generarCsv(tabla), 'Archivo CSV'),
        'xlsx' => (generarExcel(tabla, generado: ahora), 'Libro de Excel'),
        _ => (await generarPdf(tabla, generado: ahora), 'Documento PDF'),
      };
      final ruta = await guardarArchivo(
        nombreSugerido: tabla.nombreArchivo(formato, ahora),
        bytes: bytes,
        descripcion: descripcion,
        extension: formato,
      );
      if (ruta != null && mounted) notificar(context, 'Archivo guardado: $ruta');
    } on Object catch (e) {
      debugPrint('Error al exportar: $e');
      if (mounted) notificar(context, 'No se pudo exportar el archivo.', error: true);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.grid_on_outlined, size: 18),
          onPressed: () => _exportar('xlsx'),
          child: const Text('Excel (.xlsx)'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
          onPressed: () => _exportar('pdf'),
          child: const Text('PDF'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.description_outlined, size: 18),
          onPressed: () => _exportar('csv'),
          child: const Text('CSV'),
        ),
      ],
      builder: (context, controlador, _) => OutlinedButton.icon(
        onPressed: _ocupado ? null : () => controlador.isOpen ? controlador.close() : controlador.open(),
        icon: _ocupado
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.download_outlined, size: 18),
        label: const Text('Exportar'),
      ),
    );
  }
}
