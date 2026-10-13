import 'package:flutter/material.dart';

import '../../nucleo/colores.dart';

class Tarjeta extends StatelessWidget {
  const Tarjeta({
    super.key,
    required this.child,
    this.titulo,
    this.subtitulo,
    this.acciones = const [],
    this.padding = const EdgeInsets.all(20),
    this.expandir = false,
  });

  final Widget child;
  final String? titulo;
  final String? subtitulo;
  final List<Widget> acciones;
  final EdgeInsetsGeometry padding;

  final bool expandir;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColoresSacor.blanco,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColoresSacor.borde),
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: expandir ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (titulo != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo!, style: Estilos.tituloTarjeta),
                      if (subtitulo != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitulo!, style: Estilos.secundario),
                      ],
                    ],
                  ),
                ),
                ...acciones,
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (expandir) Expanded(child: child) else child,
        ],
      ),
    );
  }
}

abstract final class Estilos {
  static const tituloPantalla = TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: ColoresSacor.texto);
  static const tituloTarjeta = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ColoresSacor.texto);
  static const secundario = TextStyle(fontSize: 12.5, color: ColoresSacor.textoSecundario);
  static const tenue = TextStyle(fontSize: 12, color: ColoresSacor.textoTenue);
  static const etiqueta = TextStyle(fontSize: 13, color: ColoresSacor.textoSecundario);
  static const cuerpo = TextStyle(fontSize: 13.5, color: ColoresSacor.texto);
  static const negrita = TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: ColoresSacor.texto);
  static const numeroGrande = TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: ColoresSacor.texto);
  static const encabezadoTabla = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    color: ColoresSacor.textoTenue,
    letterSpacing: 0.4,
  );
  static const cifraTabla = TextStyle(
    fontSize: 13.5,
    color: ColoresSacor.texto,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
