import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../datos/modelos/entidades.dart';
import '../../datos/recurso.dart';
import '../../estado/almacen.dart';
import '../../estado/navegacion_estado.dart';
import '../../estado/sesion_estado.dart';
import '../../nucleo/abrir_enlace.dart';
import '../../nucleo/colores.dart';
import '../../nucleo/dinero.dart';
import '../../nucleo/formatos.dart';
import '../../nucleo/whatsapp.dart';
import '../comunes/controles.dart';
import '../comunes/formulario.dart';
import '../comunes/insignia.dart';
import '../comunes/tabla.dart';
import '../comunes/tabla_paginada.dart';
import '../comunes/tarjeta.dart';

enum _Pestana { cotizaciones, postulaciones }

class PantallaSolicitudesWeb extends StatefulWidget {
  const PantallaSolicitudesWeb({super.key});

  @override
  State<PantallaSolicitudesWeb> createState() => _PantallaSolicitudesWebState();
}

class _PantallaSolicitudesWebState extends State<PantallaSolicitudesWeb> {
  _Pestana _pestana = _Pestana.cotizaciones;

  @override
  Widget build(BuildContext context) {
    final almacen = context.watch<AlmacenSacor>();
    final pendientesCotizacion = almacen.cotizaciones.where((c) => c.estado == 'Pendiente').length;
    final pendientesPostulacion = almacen.solicitudesPuesto.where((s) => !s.atendida).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<_Pestana>(
            segments: [
              ButtonSegment(
                value: _Pestana.cotizaciones,
                label: Text('Cotizaciones (${_pendientes(pendientesCotizacion)})'),
                icon: const Icon(Icons.request_quote_outlined),
              ),
              ButtonSegment(
                value: _Pestana.postulaciones,
                label: Text('Postulaciones (${_pendientes(pendientesPostulacion)})'),
                icon: const Icon(Icons.work_outline),
              ),
            ],
            selected: {_pestana},
            onSelectionChanged: (s) => setState(() => _pestana = s.first),
          ),
        ),
        const SizedBox(height: 16),
        if (_pestana == _Pestana.cotizaciones) const _Cotizaciones() else const _Postulaciones(),
      ],
    );
  }
}

String _pendientes(int cantidad) => cantidad == 1 ? '1 pendiente' : '$cantidad pendientes';

int _porFechaDesc(DateTime? a, DateTime? b, int idA, int idB) {
  final porFecha = (b ?? DateTime(1900)).compareTo(a ?? DateTime(1900));
  return porFecha != 0 ? porFecha : idB.compareTo(idA);
}

bool _coincide(String texto, Iterable<String?> campos) =>
    texto.isEmpty || campos.any((c) => c != null && c.toLowerCase().contains(texto));

Future<void> _escribirPorWhatsapp(BuildContext context, String? telefono, String mensaje) async {
  final enlace = enlaceWhatsapp(telefono, mensaje);
  if (enlace == null) {
    notificar(context, 'No hay un teléfono de El Salvador válido para WhatsApp.', error: true);
    return;
  }
  try {
    await abrirEnlace(enlace);
  } on Object {
    if (context.mounted) notificar(context, 'No se pudo abrir WhatsApp.', error: true);
  }
}

Widget _botonWhatsapp(BuildContext context, String? telefono, String mensaje) => BotonFila(
      tooltip: numeroWhatsapp(telefono) == null ? 'Sin teléfono para WhatsApp' : 'Escribir por WhatsApp',
      icono: Icons.chat_outlined,
      color: numeroWhatsapp(telefono) == null ? ColoresSacor.textoTenue : ColoresSacor.verde,
      alPresionar: () => _escribirPorWhatsapp(context, telefono, mensaje),
    );

class _InsigniaCotizacion extends StatelessWidget {
  const _InsigniaCotizacion(this.estado);

  final String estado;

  @override
  Widget build(BuildContext context) {
    final texto = Cotizacion.estadoVisible(estado);
    return switch (estado) {
      'Pendiente' => Insignia(texto, tono: TonoInsignia.alerta, icono: Icons.schedule),
      'EnRevision' => Insignia(texto, tono: TonoInsignia.info, icono: Icons.manage_search),
      'Cotizada' => Insignia(texto, tono: TonoInsignia.info, icono: Icons.request_quote_outlined),
      'Aprobada' => Insignia(texto, tono: TonoInsignia.exito, icono: Icons.check_circle_outline),
      'Rechazada' => Insignia(texto, tono: TonoInsignia.error, icono: Icons.cancel_outlined),
      _ => Insignia(texto, icono: Icons.inventory_2_outlined),
    };
  }
}

class _Cotizaciones extends StatefulWidget {
  const _Cotizaciones();

  @override
  State<_Cotizaciones> createState() => _CotizacionesState();
}

class _CotizacionesState extends State<_Cotizaciones> {
  String _busqueda = '';
  String? _estado;

  @override
  Widget build(BuildContext context) {
    final almacen = context.watch<AlmacenSacor>();
    final texto = _busqueda.toLowerCase();
    final filas = almacen.cotizaciones.where((c) {
      if (_estado != null && c.estado != _estado) return false;
      final persona = almacen.usuarioWeb(c.idUsuarioWeb);
      return _coincide(texto, [persona?.nombre, persona?.dui, c.tipoServicio, c.descripcion, '#${c.id}']);
    }).toList()
      ..sort((a, b) => _porFechaDesc(a.fecha, b.fecha, a.id, b.id));

    int contar(String estado) => almacen.cotizaciones.where((c) => c.estado == estado).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Tarjeta(
          child: ResumenCifras(cifras: [
            for (final e in Cotizacion.estados) (Cotizacion.estadoVisible(e), Formatos.entero(contar(e))),
          ]),
        ),
        const SizedBox(height: 16),
        Tarjeta(
          titulo: 'Cotizaciones',
          subtitulo: 'Solicitudes de servicio enviadas desde el sitio web.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilaFiltros(filtros: [
                CampoBusqueda(
                  sugerencia: 'Buscar por nombre, DUI o servicio',
                  ancho: 300,
                  alCambiar: (t) => setState(() => _busqueda = t),
                ),
                SelectorFiltro<String?>(
                  etiqueta: 'Estado',
                  valor: _estado,
                  ancho: 200,
                  opciones: [(null, 'Todos'), for (final e in Cotizacion.estados) (e, Cotizacion.estadoVisible(e))],
                  alCambiar: (e) => setState(() => _estado = e),
                ),
              ]),
              const SizedBox(height: 12),
              TablaPaginada<Cotizacion>(
                filas: filas,
                mensajeVacio: 'No hay cotizaciones con esos filtros.',
                alTocar: (c) => _detalle(context, c),
                columnas: [
                  ColumnaTabla(
                    titulo: 'Solicitud',
                    flex: 2,
                    anchoMinimo: 100,
                    celda: (c) => CeldaDoble('#${c.id}', Formatos.fecha(c.fecha)),
                  ),
                  ColumnaTabla(
                    titulo: 'Cliente',
                    flex: 4,
                    anchoMinimo: 190,
                    celda: (c) {
                      final p = almacen.usuarioWeb(c.idUsuarioWeb);
                      return CeldaDoble(p?.nombre ?? 'Usuario #${c.idUsuarioWeb}', p?.telefono ?? p?.correo);
                    },
                  ),
                  ColumnaTabla(
                    titulo: 'Servicio',
                    flex: 5,
                    anchoMinimo: 220,
                    celda: (c) => CeldaDoble(c.tipoServicio ?? '—', c.detalles.join(' · ')),
                  ),
                  ColumnaTabla(titulo: 'Estado', flex: 3, anchoMinimo: 130, celda: (c) => _InsigniaCotizacion(c.estado)),
                  ColumnaTabla(
                    titulo: 'Analista',
                    flex: 3,
                    anchoMinimo: 120,
                    celda: (c) => Text(c.idAnalista == null ? '—' : almacen.nombreEmpleado(c.idAnalista!)),
                  ),
                  ColumnaTabla(
                    titulo: '',
                    flex: 2,
                    anchoMinimo: 110,
                    celda: (c) {
                      final p = almacen.usuarioWeb(c.idUsuarioWeb);
                      return AccionesFila(
                        extras: [
                          _botonWhatsapp(context, p?.telefono, saludoCotizacion(p?.nombre ?? '', c.tipoServicio, c.id)),
                        ],
                        alEditar: () => cambiarEstadoCotizacion(context, c),
                        alEliminar: () => eliminarConConfirmacion(
                          context,
                          que: 'la cotización #${c.id}',
                          eliminar: () => almacen.eliminar(Recurso.cotizaciones, c, detalle: 'Cotización web eliminada'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _detalle(BuildContext context, Cotizacion c) {
    final almacen = context.read<AlmacenSacor>();
    final p = almacen.usuarioWeb(c.idUsuarioWeb);
    Widget fila(String etiqueta, String? valor) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 140, child: Text(etiqueta, style: Estilos.secundario)),
              Expanded(child: SelectableText(valor == null || valor.isEmpty ? '—' : valor, style: Estilos.cuerpo)),
            ],
          ),
        );

    showDialog<void>(
      context: context,
      builder: (contexto) => DialogoFormulario(
        titulo: 'Cotización #${c.id}',
        subtitulo: '${Formatos.fecha(c.fecha)} · ${Cotizacion.estadoVisible(c.estado)}',
        ancho: 640,
        contenido: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            fila('Cliente', p?.nombre),
            fila('DUI', p?.dui),
            fila('Teléfono', p?.telefono),
            fila('Correo', p?.correo),
            const Divider(height: 24),
            fila('Servicio', c.tipoServicio),
            for (final d in c.detalles) fila('', d),
            const Divider(height: 24),
            fila('Analista', c.idAnalista == null ? null : almacen.nombreEmpleado(c.idAnalista!)),
            fila('Viajes', _resumenViajes(almacen, c)),
          ],
        ),
        acciones: [
          if (c.estado == 'Aprobada' && almacen.viajesDeCotizacion(c.id).isEmpty)
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(contexto).pop();
                generarViajesCotizacion(context, c);
              },
              icon: const Icon(Icons.add_task, size: 18),
              label: const Text('Crear contrato y viajes'),
            ),
          if (almacen.viajesDeCotizacion(c.id).isNotEmpty)
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(contexto).pop();
                final contrato = almacen.contratoDeCotizacion(c.id);
                if (contrato != null) context.read<NavegacionEstado>().verViajesDeContrato(contrato.id);
              },
              icon: const Icon(Icons.local_shipping_outlined, size: 18),
              label: const Text('Ver viajes'),
            ),
          TextButton.icon(
            onPressed: () => _escribirPorWhatsapp(contexto, p?.telefono, saludoCotizacion(p?.nombre ?? '', c.tipoServicio, c.id)),
            icon: const Icon(Icons.chat_outlined, size: 18),
            label: const Text('Escribir por WhatsApp'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(contexto).pop();
              cambiarEstadoCotizacion(context, c);
            },
            child: const Text('Cambiar estado'),
          ),
        ],
      ),
    );
  }
}

String? _resumenViajes(AlmacenSacor almacen, Cotizacion c) {
  final viajes = almacen.viajesDeCotizacion(c.id);
  if (viajes.isEmpty) {
    return c.estado == 'Aprobada'
        ? 'Sin contrato todavía. Use "Crear contrato y viajes".'
        : 'El contrato y sus viajes se crean al aprobar la cotización.';
  }
  final asignados = viajes.where((v) => almacen.personalDeRuta(v.id).isNotEmpty).length;
  return '${viajes.length} generados (${Formatos.fecha(viajes.first.fecha)} a ${Formatos.fecha(viajes.last.fecha)}) · '
      '$asignados con personal asignado';
}

String? _valorDetalle(Cotizacion c, String clave) {
  for (final d in c.detalles) {
    final i = d.indexOf(':');
    if (i > 0 && d.substring(0, i).trim().toLowerCase() == clave) {
      final valor = d.substring(i + 1).trim();
      return valor.isEmpty ? null : valor;
    }
  }
  return null;
}

const _serviciosConDestino = {'acarreo de materiales', 'especifico', 'específico'};

const _frecuencias = [
  ('Unica', 'Todos en la misma fecha'),
  ('Diaria', 'Diaria'),
  ('Semanal', 'Semanal'),
  ('Quincenal', 'Quincenal'),
  ('Mensual', 'Mensual'),
];

Future<void> generarViajesCotizacion(BuildContext context, Cotizacion cotizacion) async {
  final almacen = context.read<AlmacenSacor>();
  final recurrente = (_valorDetalle(cotizacion, 'modalidad') ?? '').contains('recurrente');
  final frecuenciaWeb = _valorDetalle(cotizacion, 'frecuencia');
  final frecuencia = _frecuencias.any((f) => f.$1 == frecuenciaWeb)
      ? frecuenciaWeb
      : (recurrente ? 'Semanal' : 'Unica');
  final fechaWeb = DateTime.tryParse(_valorDetalle(cotizacion, 'inicio') ?? _valorDetalle(cotizacion, 'fecha estimada') ?? '');
  final manana = DateTime.now().add(const Duration(days: 1));
  final cantidad = int.tryParse(_valorDetalle(cotizacion, 'viajes') ?? '') ?? 1;
  final lugarWeb = _valorDetalle(cotizacion, 'recoleccion');
  final conDestino = _serviciosConDestino.contains((cotizacion.tipoServicio ?? '').trim().toLowerCase());
  final materiales = (_valorDetalle(cotizacion, 'materiales') ?? '')
      .split(',')
      .map((m) => m.trim())
      .where((m) => m.isNotEmpty)
      .toSet()
      .toList();
  final sinMateriales = materiales.isEmpty;
  final tiposConocidos = {for (final p in almacen.precios) p.tipo}.toList()..sort();
  Dinero? precioActual(String material) =>
      almacen.precios.where((p) => p.tipo == material && p.lugar == lugarWeb).firstOrNull?.precio;

  Map<String, Object?> resultado = const {};

  final guardado = await mostrarFormulario(
    context,
    titulo: 'Contrato de la cotización #${cotizacion.id}',
    subtitulo: 'Se crean el cliente, el contrato y sus viajes. Después el administrador técnico asigna el personal de cada viaje desde el móvil.',
    textoGuardar: 'Crear contrato',
    ancho: 600,
    iniciales: {
      'cantidad': cantidad.clamp(1, 200),
      'inicio': fechaWeb == null ? DateTime(manana.year, manana.month, manana.day) : DateTime(fechaWeb.year, fechaWeb.month, fechaWeb.day),
      'frecuencia': frecuencia,
      'lugar': lugarWeb,
      'destino': conDestino ? _valorDetalle(cotizacion, 'destino') : null,
      for (var i = 0; i < materiales.length; i++) 'precio_$i': precioActual(materiales[i]),
    },
    campos: [
      const CampoNumero('cantidad', 'Cantidad de viajes', minimo: 1, maximo: 200),
      const CampoFecha('inicio', 'Fecha del primer viaje'),
      const CampoOpciones<String>('frecuencia', 'Frecuencia', _frecuencias),
      const CampoTexto('lugar', 'Lugar de recolección', largo: 120),
      if (conDestino) const CampoTexto('destino', 'Destino', obligatorio: false, largo: 70),
      if (sinMateriales) ...[
        CampoTexto('material_0', 'Material', largo: 60, sugerencias: tiposConocidos,
            ayuda: 'La solicitud no indicó materiales.'),
        const CampoDinero('precio_0', 'Precio por tonelada'),
      ] else
        for (var i = 0; i < materiales.length; i++)
          CampoDinero('precio_$i', 'Precio por tonelada · ${materiales[i]}'),
    ],
    alGuardar: (v) async {
      final inicio = v['inicio']! as DateTime;
      resultado = await almacen.generarViajesCotizacion(cotizacion.id, {
        'cantidad': v['cantidad'],
        'fechaInicio': Formatos.fechaIso(inicio),
        'frecuencia': v['frecuencia'],
        'precios': [
          for (var i = 0; i < (sinMateriales ? 1 : materiales.length); i++)
            {
              'tipo': sinMateriales ? v['material_0'] : materiales[i],
              'precio': (v['precio_$i']! as Dinero).toJson(),
            },
        ],
        'lugar': v['lugar'],
        'destino': conDestino ? v['destino'] : null,
      });
    },
  );

  if (!guardado || !context.mounted) return;

  notificar(
    context,
    '${resultado['mensaje'] ?? 'Viajes generados.'}'
    ' Los precios por tonelada quedaron guardados para ${materiales.isEmpty ? 'el material' : materiales.join(', ')}.'
    ' El administrador técnico ya puede asignar el personal desde el móvil.',
  );
}

Future<void> cambiarEstadoCotizacion(BuildContext context, Cotizacion cotizacion) async {
  final almacen = context.read<AlmacenSacor>();
  final usuario = context.read<SesionEstado>().usuario!;
  final guardado = await mostrarFormulario(
    context,
    titulo: 'Cotización #${cotizacion.id}',
    subtitulo: 'Al guardar quedás como analista de esta cotización.',
    ancho: 480,
    iniciales: {'estado': cotizacion.estado},
    campos: [
      CampoOpciones<String>(
        'estado',
        'Estado',
        [for (final e in Cotizacion.estados) (e, Cotizacion.estadoVisible(e))],
        ancho: Ancho.completo,
      ),
    ],
    alGuardar: (v) => almacen.actualizar(
      Recurso.cotizaciones,
      cotizacion,
      cotizacion.con({'estado': v['estado'], 'idAdministradorAnalista': usuario.id}),
      detalle: 'Estado de cotización web: ${Cotizacion.estadoVisible(v['estado']! as String)}',
    ),
  );
  if (!guardado || !context.mounted) return;
  notificar(context, 'Cotización #${cotizacion.id} actualizada.');

  final actualizada = almacen.cotizaciones.where((c) => c.id == cotizacion.id).firstOrNull;
  if (actualizada != null && actualizada.estado == 'Aprobada' && almacen.contratoDeCotizacion(actualizada.id) == null) {
    await generarViajesCotizacion(context, actualizada);
  }
}

class _Postulaciones extends StatefulWidget {
  const _Postulaciones();

  @override
  State<_Postulaciones> createState() => _PostulacionesState();
}

class _PostulacionesState extends State<_Postulaciones> {
  String _busqueda = '';
  bool? _atendidas = false;

  @override
  Widget build(BuildContext context) {
    final almacen = context.watch<AlmacenSacor>();
    final usuario = context.read<SesionEstado>().usuario!;
    final texto = _busqueda.toLowerCase();
    final filas = almacen.solicitudesPuesto.where((s) {
      if (_atendidas != null && s.atendida != _atendidas) return false;
      final persona = almacen.usuarioWeb(s.idUsuarioWeb);
      return _coincide(texto, [persona?.nombre, persona?.dui, s.puesto, '#${s.id}']);
    }).toList()
      ..sort((a, b) => _porFechaDesc(a.fecha, b.fecha, a.id, b.id));

    final total = almacen.solicitudesPuesto.length;
    final atendidas = almacen.solicitudesPuesto.where((s) => s.atendida).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Tarjeta(
          child: ResumenCifras(cifras: [
            ('Pendientes', Formatos.entero(total - atendidas)),
            ('Atendidas', Formatos.entero(atendidas)),
            ('Total', Formatos.entero(total)),
          ]),
        ),
        const SizedBox(height: 16),
        Tarjeta(
          titulo: 'Postulaciones',
          subtitulo: 'Experiencia, municipio, licencia y mensaje llegan solo por WhatsApp: la web no los guarda.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilaFiltros(filtros: [
                CampoBusqueda(
                  sugerencia: 'Buscar por nombre, DUI o puesto',
                  ancho: 300,
                  alCambiar: (t) => setState(() => _busqueda = t),
                ),
                SelectorFiltro<bool?>(
                  etiqueta: 'Mostrar',
                  valor: _atendidas,
                  ancho: 200,
                  opciones: const [(false, 'Pendientes'), (true, 'Atendidas'), (null, 'Todas')],
                  alCambiar: (v) => setState(() => _atendidas = v),
                ),
              ]),
              const SizedBox(height: 12),
              TablaPaginada<SolicitudPuesto>(
                filas: filas,
                mensajeVacio: 'No hay postulaciones con esos filtros.',
                columnas: [
                  ColumnaTabla(
                    titulo: 'Solicitud',
                    flex: 2,
                    anchoMinimo: 100,
                    celda: (s) => CeldaDoble('#${s.id}', Formatos.fecha(s.fecha)),
                  ),
                  ColumnaTabla(
                    titulo: 'Postulante',
                    flex: 4,
                    anchoMinimo: 190,
                    celda: (s) {
                      final p = almacen.usuarioWeb(s.idUsuarioWeb);
                      return CeldaDoble(p?.nombre ?? 'Usuario #${s.idUsuarioWeb}', p == null ? null : 'DUI ${p.dui}');
                    },
                  ),
                  ColumnaTabla(
                    titulo: 'Contacto',
                    flex: 3,
                    anchoMinimo: 150,
                    celda: (s) {
                      final p = almacen.usuarioWeb(s.idUsuarioWeb);
                      return CeldaDoble(p?.telefono ?? '—', p?.correo);
                    },
                  ),
                  ColumnaTabla(titulo: 'Puesto', flex: 3, anchoMinimo: 150, celda: (s) => Text(s.puesto)),
                  ColumnaTabla(
                    titulo: 'Estado',
                    flex: 2,
                    anchoMinimo: 120,
                    celda: (s) => s.atendida
                        ? const Insignia('Atendida', tono: TonoInsignia.exito, icono: Icons.check_circle_outline)
                        : const Insignia('Pendiente', tono: TonoInsignia.alerta, icono: Icons.schedule),
                  ),
                  ColumnaTabla(
                    titulo: 'Atendida por',
                    flex: 3,
                    anchoMinimo: 120,
                    celda: (s) => Text(s.idAnalista == null ? '—' : almacen.nombreEmpleado(s.idAnalista!)),
                  ),
                  ColumnaTabla(
                    titulo: '',
                    flex: 2,
                    anchoMinimo: 110,
                    celda: (s) {
                      final p = almacen.usuarioWeb(s.idUsuarioWeb);
                      return AccionesFila(
                        extras: [
                          _botonWhatsapp(context, p?.telefono, saludoPostulacion(p?.nombre ?? '', s.puesto, s.id)),
                          BotonFila(
                            tooltip: s.atendida ? 'Volver a pendiente' : 'Marcar como atendida',
                            icono: s.atendida ? Icons.undo : Icons.task_alt,
                            color: s.atendida ? null : ColoresSacor.verde,
                            alPresionar: () => _alternarAtendida(context, s, usuario.id),
                          ),
                        ],
                        alEliminar: () => eliminarConConfirmacion(
                          context,
                          que: 'la postulación #${s.id}',
                          eliminar: () =>
                              almacen.eliminar(Recurso.solicitudesPuesto, s, detalle: 'Postulación web eliminada'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _alternarAtendida(BuildContext context, SolicitudPuesto solicitud, int idUsuario) async {
    final almacen = context.read<AlmacenSacor>();
    final atender = !solicitud.atendida;
    try {
      await almacen.actualizar(
        Recurso.solicitudesPuesto,
        solicitud,
        solicitud.con({'idAdministradorAnalista': atender ? idUsuario : null}),
        detalle: atender ? 'Postulación web atendida' : 'Postulación web vuelta a pendiente',
      );
      if (context.mounted) {
        notificar(context, atender ? 'Postulación #${solicitud.id} atendida.' : 'Postulación #${solicitud.id} pendiente.');
      }
    } on Object catch (e) {
      if (context.mounted) notificar(context, '$e', error: true);
    }
  }
}
