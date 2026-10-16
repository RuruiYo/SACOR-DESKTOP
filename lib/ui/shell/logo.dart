import 'package:flutter/material.dart';

import '../../nucleo/colores.dart';

class LogoSacor extends StatelessWidget {
  const LogoSacor({super.key, this.tamano = 36, this.mostrarTexto = true});

  final double tamano;
  final bool mostrarTexto;

  @override
  Widget build(BuildContext context) {
    final icono = Image.asset(
      'assets/logo_sacor.png',
      width: tamano,
      height: tamano,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
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
