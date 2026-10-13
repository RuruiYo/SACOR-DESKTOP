import 'package:flutter/material.dart';

import '../../nucleo/colores.dart';

class LogoSacor extends StatelessWidget {
  const LogoSacor({super.key, this.tamano = 36, this.mostrarTexto = true});

  final double tamano;
  final bool mostrarTexto;

  @override
  Widget build(BuildContext context) {
    final icono = Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        color: ColoresSacor.verde,
        borderRadius: BorderRadius.circular(tamano * 0.28),
      ),
      child: Icon(Icons.eco_outlined, color: ColoresSacor.blanco, size: tamano * 0.58),
    );

    if (!mostrarTexto) return icono;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icono,
        SizedBox(width: tamano * 0.3),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SACOR',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: tamano * 0.46,
                  fontWeight: FontWeight.w700,
                  color: ColoresSacor.texto,
                  letterSpacing: 0.5,
                  height: 1.1,
                ),
              ),
              Text(
                'Administración contable',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: tamano * 0.3, color: ColoresSacor.textoTenue, height: 1.2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
