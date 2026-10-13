import 'package:flutter/material.dart';

import '../../nucleo/colores.dart';
import '../../nucleo/variacion.dart';
import '../comunes/tarjeta.dart';

class TarjetaIndicador extends StatelessWidget {
  const TarjetaIndicador({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.icono,
    this.variacion,
    this.subirEsBueno = true,
    this.colorValor,
    this.nota,
  });

  final String etiqueta;
  final String valor;
  final IconData icono;
  final Variacion? variacion;
  final bool subirEsBueno;
  final Color? colorValor;
  final String? nota;

  @override
  Widget build(BuildContext context) {
    final variacion = this.variacion;
    final favorable = variacion?.esFavorable(subirEsBueno: subirEsBueno);
    final colorVariacion = switch (favorable) {
      true => ColoresSacor.verde,
      false => ColoresSacor.rojo,
      null => ColoresSacor.textoTenue,
    };
    final iconoVariacion = switch (variacion?.tendencia) {
      Tendencia.sube => Icons.arrow_upward,
      Tendencia.baja => Icons.arrow_downward,
      Tendencia.igual => Icons.remove,
      _ => Icons.info_outline,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: ColoresSacor.blanco,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColoresSacor.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(etiqueta, style: Estilos.etiqueta)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: ColoresSacor.fondo, borderRadius: BorderRadius.circular(8)),
                child: Icon(icono, size: 18, color: ColoresSacor.textoSecundario),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(valor, style: Estilos.numeroGrande.copyWith(color: colorValor)),
          ),
          const SizedBox(height: 6),
          if (variacion != null)
            Row(
              children: [
                Icon(iconoVariacion, size: 14, color: colorVariacion),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    variacion.descripcion,
                    style: TextStyle(fontSize: 12.5, color: colorVariacion, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          if (nota != null) ...[
            const SizedBox(height: 4),
            Text(nota!, style: Estilos.tenue, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}
