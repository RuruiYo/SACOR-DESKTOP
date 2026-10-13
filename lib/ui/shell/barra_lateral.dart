import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../configuracion/configuracion.dart';
import '../../estado/navegacion_estado.dart';
import '../../nucleo/colores.dart';
import '../comunes/tarjeta.dart';
import 'logo.dart';

class BarraLateral extends StatelessWidget {
  const BarraLateral({super.key, required this.compacta});

  final bool compacta;

  @override
  Widget build(BuildContext context) {
    final navegacion = context.watch<NavegacionEstado>();
    final configuracion = context.read<Configuracion>();

    final grupos = <String, List<Seccion>>{};
    for (final seccion in Seccion.values) {
      grupos.putIfAbsent(seccion.grupo, () => []).add(seccion);
    }

    return Container(
      width: compacta ? 76 : 248,
      color: ColoresSacor.blanco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(compacta ? 20 : 20, 20, 12, 24),
            child: Align(
              alignment: compacta ? Alignment.center : Alignment.centerLeft,
              child: LogoSacor(mostrarTexto: !compacta),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final grupo in grupos.entries) ...[
                  if (!compacta)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
                      child: Text(
                        grupo.key.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: ColoresSacor.textoTenue,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 10),
                  for (final seccion in grupo.value)
                    _ItemMenu(
                      seccion: seccion,
                      activa: navegacion.seccion == seccion,
                      compacta: compacta,
                      alTocar: () => navegacion.ir(seccion),
                    ),
                ],
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: compacta
                ? Tooltip(
                    message: configuracion.modoDemo ? 'Modo demostración' : 'Conectado a ${configuracion.urlApi}',
                    child: _Punto(demo: configuracion.modoDemo),
                  )
                : Row(
                    children: [
                      _Punto(demo: configuracion.modoDemo),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              configuracion.modoDemo ? 'Modo demostración' : 'Servidor central',
                              style: Estilos.etiqueta.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              configuracion.modoDemo ? 'Datos ficticios' : configuracion.urlApi.authority,
                              style: Estilos.tenue,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Punto extends StatelessWidget {
  const _Punto({required this.demo});

  final bool demo;

  @override
  Widget build(BuildContext context) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: demo ? ColoresSacor.ambar : ColoresSacor.verde,
          shape: BoxShape.circle,
        ),
      );
}

class _ItemMenu extends StatefulWidget {
  const _ItemMenu({required this.seccion, required this.activa, required this.compacta, required this.alTocar});

  final Seccion seccion;
  final bool activa;
  final bool compacta;
  final VoidCallback alTocar;

  @override
  State<_ItemMenu> createState() => _ItemMenuState();
}

class _ItemMenuState extends State<_ItemMenu> {
  bool _encima = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.activa ? ColoresSacor.verdeOscuro : ColoresSacor.textoSecundario;
    final fondo = widget.activa
        ? ColoresSacor.verdeSuave
        : (_encima ? ColoresSacor.hover : Colors.transparent);

    final item = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _encima = true),
      onExit: (_) => setState(() => _encima = false),
      child: GestureDetector(
        onTap: widget.alTocar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: EdgeInsets.symmetric(horizontal: widget.compacta ? 0 : 12, vertical: 10),
          decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisAlignment: widget.compacta ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(widget.activa ? widget.seccion.iconoActivo : widget.seccion.icono, size: 20,
                  color: widget.activa ? ColoresSacor.verde : color),
              if (!widget.compacta) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.seccion.menu,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.activa ? ColoresSacor.verdeOscuro : ColoresSacor.texto,
                      fontWeight: widget.activa ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      selected: widget.activa,
      label: widget.seccion.menu,
      child: widget.compacta ? Tooltip(message: widget.seccion.menu, child: item) : item,
    );
  }
}
