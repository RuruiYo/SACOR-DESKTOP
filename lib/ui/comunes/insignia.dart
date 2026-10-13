import 'package:flutter/material.dart';

import '../../nucleo/colores.dart';

enum TonoInsignia { exito, alerta, error, info, neutro }

class Insignia extends StatelessWidget {
  const Insignia(this.texto, {super.key, this.tono = TonoInsignia.neutro, this.icono});

  final String texto;
  final TonoInsignia tono;
  final IconData? icono;

  static (Color fondo, Color frente) colores(TonoInsignia tono) => switch (tono) {
        TonoInsignia.exito => (ColoresSacor.verdeSuave, ColoresSacor.verdeOscuro),
        TonoInsignia.alerta => (ColoresSacor.ambarSuave, ColoresSacor.ambarTexto),
        TonoInsignia.error => (ColoresSacor.rojoSuave, ColoresSacor.rojoTexto),
        TonoInsignia.info => (ColoresSacor.azulSuave, ColoresSacor.azulTexto),
        TonoInsignia.neutro => (ColoresSacor.fondo, ColoresSacor.textoSecundario),
      };

  @override
  Widget build(BuildContext context) {
    final (fondo, frente) = colores(tono);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 13, color: frente),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              texto,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: frente),
            ),
          ),
        ],
      ),
    );
  }
}

class Aviso extends StatelessWidget {
  const Aviso({super.key, required this.mensaje, this.titulo, this.tono = TonoInsignia.info, this.accion});

  final String mensaje;
  final String? titulo;
  final TonoInsignia tono;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final (fondo, frente) = Insignia.colores(tono);
    final icono = switch (tono) {
      TonoInsignia.exito => Icons.check_circle_outline,
      TonoInsignia.alerta => Icons.warning_amber_rounded,
      TonoInsignia.error => Icons.error_outline,
      TonoInsignia.info || TonoInsignia.neutro => Icons.info_outline,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: frente),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (titulo != null) ...[
                  Text(titulo!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: frente)),
                  const SizedBox(height: 2),
                ],
                Text(mensaje, style: TextStyle(fontSize: 13, color: frente, height: 1.35)),
              ],
            ),
          ),
          if (accion != null) ...[const SizedBox(width: 12), accion!],
        ],
      ),
    );
  }
}
