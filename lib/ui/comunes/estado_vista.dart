import 'package:flutter/material.dart';

import '../../nucleo/colores.dart';
import 'tarjeta.dart';

class ErrorDeCarga extends StatelessWidget {
  const ErrorDeCarga({super.key, required this.mensaje, required this.alReintentar});

  final String mensaje;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    return Tarjeta(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined, size: 36, color: ColoresSacor.textoTenue),
            const SizedBox(height: 12),
            const Text('No se pudo cargar la información', style: Estilos.tituloTarjeta),
            const SizedBox(height: 6),
            Text(mensaje, style: Estilos.secundario, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: alReintentar,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
