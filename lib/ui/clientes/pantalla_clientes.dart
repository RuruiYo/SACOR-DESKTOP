import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../datos/modelos/entidades.dart';
import '../../datos/modelos/json.dart';
import '../../datos/recurso.dart';
import '../../estado/almacen.dart';
import '../../estado/navegacion_estado.dart';
import '../../estado/sesion_estado.dart';
import '../../nucleo/dinero.dart';
import '../../nucleo/formatos.dart';
import '../comunes/controles.dart';
import '../comunes/formulario.dart';
import '../comunes/tabla.dart';
import '../comunes/tabla_paginada.dart';
import '../comunes/tarjeta.dart';

enum _Pestana { clientes, contratos, precios }

class PantallaClientes extends StatefulWidget {
  const PantallaClientes({super.key});

  @override
  State<PantallaClientes> createState() => _PantallaClientesState();
}

class _PantallaClientesState extends State<PantallaClientes> {
  _Pestana _pestana = _Pestana.clientes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<_Pestana>(
            segments: const [
              ButtonSegment(value: _Pestana.clientes, label: Text('Clientes'), icon: Icon(Icons.storefront_outlined)),
              ButtonSegment(value: _Pestana.contratos, label: Text('Contratos'), icon: Icon(Icons.handshake_outlined)),
              ButtonSegment(value: _Pestana.precios, label: Text('Precios por tonelada'), icon: Icon(Icons.sell_outlined)),
            ],
            selected: {_pestana},
            onSelectionChanged: (s) => setState(() => _pestana = s.first),
          ),
        ),
        const SizedBox(height: 16),
        switch (_pestana) {
          _Pestana.clientes => const _Clientes(),
          _Pestana.contratos => const _Contratos(),
          _Pestana.precios => const _Precios(),
        },
      ],
    );
  }
}

class _Clientes extends StatefulWidget {
  const _Clientes();

  @override
  State<_Clientes> createState() => _ClientesState();
}

class _ClientesState extends State<_Clientes> {
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    final almacen = context.watch<AlmacenSacor>();
    final contratosPorCliente = <int, int>{};
    for (final c in almacen.contratos) {
      contratosPorCliente[c.idCliente] = (contratosPorCliente[c.idCliente] ?? 0) + 1;
    }
    final texto = _busqueda.toLowerCase();
    final filas = almacen.clientes
        .where((c) =>
            texto.isEmpty ||
            c.nombre.toLowerCase().contains(texto) ||
            (c.nombreComercial?.toLowerCase().contains(texto) ?? false) ||
            (c.documento?.contains(texto) ?? false))
        .toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));

    return Tarjeta(
      titulo: 'Clientes',
      subtitulo: '${almacen.clientes.length} registrados',
      acciones: [
        FilledButton.icon(
          onPressed: () => _formulario(context, null),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Nuevo cliente'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilaFiltros(filtros: [
            CampoBusqueda(sugerencia: 'Buscar por nombre, NIT o DUI', alCambiar: (t) => setState(() => _busqueda = t)),
          ]),
          const SizedBox(height: 12),
          TablaPaginada<Cliente>(
            filas: filas,
            mensajeVacio: 'No hay clientes con esa búsqueda.',
            columnas: [
              ColumnaTabla(titulo: 'Cliente', flex: 4, anchoMinimo: 220, celda: (c) => CeldaDoble(c.nombre, c.nombreComercial)),
              ColumnaTabla(titulo: 'Tipo', celda: (c) => Text(c.tipoVisible)),
              ColumnaTabla(titulo: 'NIT / DUI', celda: (c) => Text(c.documento ?? '—')),
              ColumnaTabla(titulo: 'NRC', celda: (c) => Text(c.nrc ?? '—')),
              ColumnaTabla(titulo: 'Teléfono', celda: (c) => Text(c.telefono ?? '—')),
              ColumnaTabla(titulo: 'Correo', flex: 3, celda: (c) => Text(c.correo ?? '—')),
              ColumnaTabla(titulo: 'Contratos', numerica: true, celda: (c) => Text('${contratosPorCliente[c.id] ?? 0}')),
              ColumnaTabla(
                titulo: '',
                anchoMinimo: 96,
                celda: (c) => AccionesFila(
                  alEditar: () => _formulario(context, c),
                  alEliminar: () => eliminarConConfirmacion(
                    context,
                    que: 'al cliente ${c.nombre}',
                    eliminar: () => almacen.eliminar(Recurso.clientes, c, detalle: 'Cliente eliminado'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _formulario(BuildContext context, Cliente? cliente) async {
    final almacen = context.read<AlmacenSacor>();
    final usuario = context.read<SesionEstado>().usuario!;
    final guardado = await mostrarFormulario(
      context,
      titulo: cliente == null ? 'Nuevo cliente' : 'Editar cliente',
      subtitulo: 'Los mismos datos de contacto que pide el sitio web.',
      iniciales: {
        'nombre': cliente?.nombre,
        'dui': cliente?.dui,
        'correo': cliente?.correo,
        'telefono': cliente?.telefono,
      },
      campos: [
        const CampoTexto('nombre', 'Nombre completo / Empresa o institución', ancho: Ancho.completo),
        const CampoTexto('dui', 'DUI', largo: 10, validar: Validar.dui),
        const CampoTexto('correo', 'Correo electrónico', obligatorio: false, largo: 254, validar: Validar.correo),
        const CampoTexto('telefono', 'Teléfono / WhatsApp', largo: 25, validar: Validar.telefono),
      ],
      alGuardar: (v) async {
        final dui = v['dui']! as String;
        if (almacen.clientes.any((c) => c.dui == dui && c.id != cliente?.id)) {
          throw const FormatException('Ya existe un cliente con ese DUI.');
        }
        final datos = {
          'nombre': v['nombre'],
          'dui': dui,
          'correo': v['correo'],
          'telefono': v['telefono'],
          if (cliente == null) 'tipo': 'Natural',
        };
        if (cliente == null) {
          await almacen.crear(Recurso.clientes, {...datos, 'idAdministradorRegistro': usuario.id},
              detalle: 'Cliente registrado');
        } else {
          await almacen.actualizar(Recurso.clientes, cliente, cliente.con(datos), detalle: 'Cliente editado');
        }
      },
    );
    if (guardado && context.mounted) notificar(context, cliente == null ? 'Cliente registrado.' : 'Cliente actualizado.');
  }
}

class _Contratos extends StatelessWidget {
  const _Contratos();

  @override
  Widget build(BuildContext context) {
    final almacen = context.watch<AlmacenSacor>();
    final pesajesPorContrato = <int, int>{};
    for (final p in almacen.pesajes) {
      pesajesPorContrato[p.idContrato] = (pesajesPorContrato[p.idContrato] ?? 0) + 1;
    }
    String lugar(Contrato c) => almacen.precio(c.idPrecioLugar)?.lugar ?? '—';
    final filas = [...almacen.contratos]..sort((a, b) {
        final porLugar = lugar(a).compareTo(lugar(b));
        return porLugar != 0
            ? porLugar
            : (almacen.precio(a.idPrecioLugar)?.tipo ?? '').compareTo(almacen.precio(b.idPrecioLugar)?.tipo ?? '');
      });

    return Tarjeta(
      titulo: 'Contratos',
      subtitulo: 'Lo que se le cobra a cada cliente por tonelada en cada plaza. El cuadro de pesaje usa estos contratos.',
      acciones: [
        FilledButton.icon(
          onPressed: () => nuevoContrato(context),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Nuevo contrato'),
        ),
      ],
      child: TablaPaginada<Contrato>(
        filas: filas,
        mensajeVacio: 'No hay contratos registrados.',
        columnas: [
          ColumnaTabla(titulo: 'Cliente', flex: 3, celda: (c) => Text(almacen.nombreCliente(c.idCliente))),
          ColumnaTabla(titulo: 'Plaza', flex: 3, celda: (c) => Text(lugar(c))),
          ColumnaTabla(titulo: 'Tipo', celda: (c) => Text(almacen.precio(c.idPrecioLugar)?.tipo ?? '—')),
          ColumnaTabla(
            titulo: 'Precio / t',
            numerica: true,
            celda: (c) => Text(Formatos.usd(almacen.precio(c.idPrecioLugar)?.precio ?? const Dinero.cero())),
          ),
          ColumnaTabla(titulo: 'Desde', celda: (c) => Text(Formatos.fecha(c.fecha))),
          ColumnaTabla(titulo: 'Transporte', celda: (c) => Text(c.tipoTransportaje ?? '—')),
          ColumnaTabla(titulo: 'Observación', flex: 3, celda: (c) => Text(c.observacion ?? '—')),
          ColumnaTabla(titulo: 'Pesajes', numerica: true, celda: (c) => Text('${pesajesPorContrato[c.id] ?? 0}')),
          ColumnaTabla(
            titulo: 'Viajes',
            anchoMinimo: 110,
            celda: (c) {
              final viajes = almacen.viajesDeContrato(c.id);
              if (viajes.isEmpty) return const Text('—');
              final conPersonal = viajes.where((v) => almacen.personalDeRuta(v.id).isNotEmpty).length;
              return CeldaDoble('${viajes.length} viajes', '$conPersonal con personal');
            },
          ),
          ColumnaTabla(
            titulo: '',
            anchoMinimo: 140,
            celda: (c) => AccionesFila(
              extras: [
                if (almacen.viajesDeContrato(c.id).isNotEmpty)
                  BotonFila(
                    tooltip: 'Ver viajes y asignar personal',
                    icono: Icons.local_shipping_outlined,
                    alPresionar: () => context.read<NavegacionEstado>().verViajesDeContrato(c.id),
                  ),
              ],
              alEditar: () => formularioContrato(context, c),
              alEliminar: () => eliminarConConfirmacion(
                context,
                que: 'el contrato de ${lugar(c)}',
                eliminar: () => almacen.eliminar(Recurso.contratos, c, detalle: 'Contrato eliminado'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _servicios = ['Acarreo de materiales', 'Recoleccion de desechos', 'Reciclaje', 'Especifico'];
const _serviciosConDestino = {'Acarreo de materiales', 'Especifico'};
String _etiquetaServicio(String servicio) => switch (servicio) {
      'Recoleccion de desechos' => 'Recolección de desechos',
      'Especifico' => 'Específico',
      _ => servicio,
    };

const _frecuencias = ['Diaria', 'Semanal', 'Quincenal', 'Mensual', 'A demanda'];

int? _estimarViajes(int meses, String frecuencia) => switch (frecuencia) {
      'Diaria' => (meses * 365 / 12).round(),
      'Semanal' => (meses * 52 / 12).round(),
      'Quincenal' => meses * 2,
      'Mensual' => meses,
      'A demanda' => 1,
      _ => null,
    };

Future<void> nuevoContrato(BuildContext context) async {
  final almacen = context.read<AlmacenSacor>();
  if (almacen.clientes.isEmpty) {
    notificar(context, 'Registre primero al cliente.', error: true);
    return;
  }
  final servicios = {for (final s in _servicios) s.toLowerCase()};
  final materiales = {for (final p in almacen.precios) if (!servicios.contains(p.tipo.toLowerCase())) p.tipo}.toList()..sort();
  if (materiales.isEmpty) {
    notificar(context, 'No hay tipos de material. Regístrelos en Precios por tonelada.', error: true);
    return;
  }
  final hoy = DateTime.now();
  Map<String, Object?> solicitud = const {};

  final continuar = await mostrarFormulario(
    context,
    titulo: 'Nuevo contrato',
    subtitulo: 'Los mismos datos que pide el sitio web. Al continuar se indican los precios por tonelada.',
    textoGuardar: 'Continuar',
    ancho: 680,
    iniciales: {
      'servicio': _servicios.first,
      'modalidad': 'recurrente',
      'inicio': DateTime(hoy.year, hoy.month, hoy.day + 1),
      'materiales': <int>[],
    },
    campos: [
      CampoOpciones<int>('cliente', 'Cliente', [
        for (final c in [...almacen.clientes]..sort((a, b) => a.nombre.compareTo(b.nombre))) (c.id, c.nombre),
      ], ancho: Ancho.completo),
      CampoOpciones<String>('servicio', 'Tipo de servicio', [for (final s in _servicios) (s, _etiquetaServicio(s))]),
      const CampoOpciones<String>('modalidad', 'Modalidad', [
        ('puntual', 'Servicio puntual'),
        ('recurrente', 'Contrato recurrente'),
      ]),
      const CampoTexto('lugar', 'Lugar de recolección', largo: 120),
      const CampoTexto('destino', 'Destino',
          obligatorio: false, largo: 70, ayuda: 'Solo para Acarreo de materiales y Específico.'),
      CampoSeleccion('materiales', 'Tipos de material', [
        for (var i = 0; i < materiales.length; i++) (i, materiales[i]),
      ], obligatorio: true),
      const CampoNumero('duracion', 'Duración del contrato (meses)',
          obligatorio: false, minimo: 1, maximo: 36, ayuda: 'Solo contrato recurrente.'),
      CampoOpciones<String>('frecuencia', 'Frecuencia de viajes', [for (final f in _frecuencias) (f, f)],
          obligatorio: false, ayuda: 'Solo contrato recurrente.'),
      const CampoFecha('inicio', 'Fecha de inicio o fecha estimada'),
      const CampoTexto('volumen', 'Volumen aproximado', obligatorio: false, largo: 60, ayuda: 'Solo servicio puntual.'),
      const CampoTexto('descripcion', 'Descripción', obligatorio: false, largo: 600, ancho: Ancho.completo),
    ],
    alGuardar: (v) async {
      if (v['modalidad'] == 'recurrente') {
        if (v['duracion'] == null || v['frecuencia'] == null) {
          throw const FormatException('Un contrato recurrente necesita la duración en meses y la frecuencia.');
        }
        final cantidad = _estimarViajes((v['duracion']! as num).toInt(), v['frecuencia']! as String)!;
        if (cantidad > 200) throw const FormatException('El contrato no puede tener más de 200 viajes.');
      }
      solicitud = v;
    },
  );
  if (!continuar || !context.mounted) return;

  final elegidos = [for (final i in (solicitud['materiales']! as Set<int>).toList()..sort()) materiales[i]];
  final lugar = solicitud['lugar']! as String;
  final servicio = solicitud['servicio']! as String;
  final recurrente = solicitud['modalidad'] == 'recurrente';
  final frecuenciaWeb = solicitud['frecuencia'] as String?;
  final cantidad = recurrente ? _estimarViajes((solicitud['duracion']! as num).toInt(), frecuenciaWeb!)! : 1;
  final frecuencia = !recurrente || frecuenciaWeb == 'A demanda' ? 'Unica' : frecuenciaWeb!;
  final inicio = solicitud['inicio']! as DateTime;
  Dinero? precioActual(String material) =>
      almacen.precios.where((p) => p.tipo == material && p.lugar == lugar).firstOrNull?.precio;
  final notas = [
    if (recurrente) 'Duración: ${(solicitud['duracion']! as num).toInt()} mes(es), frecuencia ${frecuenciaWeb!.toLowerCase()}.',
    if (!recurrente && solicitud['volumen'] != null) 'Volumen: ${solicitud['volumen']}.',
    if (solicitud['descripcion'] != null) solicitud['descripcion']! as String,
  ].join(' ');

  final guardado = await mostrarFormulario(
    context,
    titulo: 'Precios del contrato',
    subtitulo: '$cantidad viaje(s) desde el ${Formatos.fecha(inicio)} en $lugar. Los precios se guardan en "Precios por tonelada".',
    textoGuardar: 'Crear contrato',
    ancho: 520,
    iniciales: {for (var i = 0; i < elegidos.length; i++) 'precio_$i': precioActual(elegidos[i])},
    campos: [
      for (var i = 0; i < elegidos.length; i++)
        CampoDinero('precio_$i', 'Precio por tonelada · ${elegidos[i]}', ancho: Ancho.completo),
    ],
    alGuardar: (v) async {
      await almacen.generarContrato({
        'idCliente': solicitud['cliente'],
        'tipoServicio': servicio,
        'cantidad': cantidad,
        'fechaInicio': Formatos.fechaIso(inicio),
        'frecuencia': frecuencia,
        'precios': [
          for (var i = 0; i < elegidos.length; i++) {'tipo': elegidos[i], 'precio': (v['precio_$i']! as Dinero).toJson()},
        ],
        'lugar': lugar,
        'destino': _serviciosConDestino.contains(servicio) ? solicitud['destino'] : null,
        'observacion': notas.isEmpty ? null : notas,
      });
    },
  );
  if (guardado && context.mounted) {
    notificar(context, 'Contrato creado con $cantidad viaje(s). El administrador técnico ya puede asignar el personal.');
  }
}

Future<void> formularioContrato(BuildContext context, Contrato? contrato) async {
  final almacen = context.read<AlmacenSacor>();
  if (almacen.clientes.isEmpty || almacen.precios.isEmpty || almacen.rutas.isEmpty) {
    notificar(context, 'Para un contrato se necesitan al menos un cliente, un precio y una salida (ruta).', error: true);
    return;
  }
  final precios = [...almacen.precios]..sort((a, b) => a.descripcion.compareTo(b.descripcion));
  final rutas = [...almacen.rutas]
    ..sort((a, b) => (b.fecha ?? DateTime(1900)).compareTo(a.fecha ?? DateTime(1900)));

  final guardado = await mostrarFormulario(
    context,
    titulo: contrato == null ? 'Nuevo contrato' : 'Editar contrato',
    iniciales: {
      'cliente': contrato?.idCliente,
      'precio': contrato?.idPrecioLugar,
      'ruta': contrato?.idRutaTrabajo ?? rutas.first.id,
      'fecha': contrato?.fecha,
      'tipoTransportaje': contrato?.tipoTransportaje,
      'observacion': contrato?.observacion,
    },
    campos: [
      CampoOpciones<int>('cliente', 'Cliente', [
        for (final c in [...almacen.clientes]..sort((a, b) => a.nombre.compareTo(b.nombre))) (c.id, c.nombre),
      ]),
      CampoOpciones<int>('precio', 'Plaza, tipo y precio', [
        for (final p in precios) (p.id, '${p.descripcion} · ${Formatos.usd(p.precio)}/t'),
      ]),
      CampoOpciones<int>(
        'ruta',
        'Ruta (salida)',
        [for (final r in rutas) (r.id, '${r.destino} · ${r.destinoFechado.fechaVisible}')],
        ayuda: 'La base exige una ruta para cada contrato.',
      ),
      const CampoFecha('fecha', 'Vigente desde', obligatorio: false),
      const CampoTexto('tipoTransportaje', 'Tipo de transporte',
          obligatorio: false, largo: 80, sugerencias: ['Camión volteo', 'Compactador', 'Pick-up']),
      const CampoTexto('observacion', 'Observación', obligatorio: false, largo: 1000, ancho: Ancho.completo),
    ],
    alGuardar: (v) async {
      final fecha = v['fecha'] as DateTime?;
      final datos = {
        'idCliente': v['cliente'],
        'idPrecioLugar': v['precio'],
        'idRutaTrabajo': v['ruta'],
        'fecha': fecha == null ? null : fechaJson(fecha),
        'tipoTransportaje': v['tipoTransportaje'],
        'observacion': v['observacion'],
      };
      if (contrato == null) {
        await almacen.crear(Recurso.contratos, datos, detalle: 'Contrato registrado');
      } else {
        await almacen.actualizar(Recurso.contratos, contrato, contrato.con(datos), detalle: 'Contrato editado');
      }
    },
  );
  if (guardado && context.mounted) notificar(context, contrato == null ? 'Contrato registrado.' : 'Contrato actualizado.');
}

class _Precios extends StatelessWidget {
  const _Precios();

  @override
  Widget build(BuildContext context) {
    final almacen = context.watch<AlmacenSacor>();
    final usos = <int, int>{};
    for (final c in almacen.contratos) {
      usos[c.idPrecioLugar] = (usos[c.idPrecioLugar] ?? 0) + 1;
    }
    final filas = [...almacen.precios]..sort((a, b) {
        final porLugar = a.lugar.compareTo(b.lugar);
        return porLugar != 0 ? porLugar : a.tipo.compareTo(b.tipo);
      });

    return Tarjeta(
      titulo: 'Precios por tonelada',
      subtitulo: 'Precio actual de cada tipo de desecho en cada plaza.',
      acciones: [
        FilledButton.icon(
          onPressed: () => _formulario(context, null),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Nuevo precio'),
        ),
      ],
      child: TablaPaginada<PrecioLugar>(
        filas: filas,
        mensajeVacio: 'No hay precios registrados.',
        columnas: [
          ColumnaTabla(titulo: 'Plaza o lugar', flex: 4, celda: (p) => Text(p.lugar)),
          ColumnaTabla(titulo: 'Tipo', celda: (p) => Text(p.tipo)),
          ColumnaTabla(titulo: 'Precio / t', numerica: true, celda: (p) => Text(Formatos.usd(p.precio))),
          ColumnaTabla(titulo: 'Actualizado', celda: (p) => Text(Formatos.fecha(p.fechaModificacion))),
          ColumnaTabla(titulo: 'Contratos', numerica: true, celda: (p) => Text('${usos[p.id] ?? 0}')),
          ColumnaTabla(
            titulo: '',
            anchoMinimo: 96,
            celda: (p) => AccionesFila(
              alEditar: () => _formulario(context, p),
              alEliminar: () => eliminarConConfirmacion(
                context,
                que: 'el precio ${p.descripcion}',
                eliminar: () => almacen.eliminar(Recurso.precios, p, detalle: 'Precio eliminado'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _formulario(BuildContext context, PrecioLugar? precio) async {
    final almacen = context.read<AlmacenSacor>();
    final lugares = {for (final p in almacen.precios) p.lugar}.toList()..sort();
    final usado = precio != null && almacen.pesajes.any((p) => p.idPrecioLugar == precio.id);
    final guardado = await mostrarFormulario(
      context,
      titulo: precio == null ? 'Nuevo precio' : 'Editar precio',
      iniciales: {'tipo': precio?.tipo, 'lugar': precio?.lugar, 'precio': precio?.precio},
      campos: [
        const CampoTexto('tipo', 'Tipo de desecho', largo: 60, sugerencias: ['Orgánico', 'Sólido']),
        CampoTexto('lugar', 'Plaza o lugar', largo: 200, sugerencias: lugares),
        CampoDinero(
          'precio',
          'Precio por tonelada',
          ayuda: usado ? 'El nuevo precio solo aplica a los pesajes que se registren desde ahora; las ventas anteriores no cambian.' : null,
        ),
      ],
      alGuardar: (v) async {
        final tipo = v['tipo']! as String;
        final lugar = v['lugar']! as String;
        if (almacen.precios.any((p) => p.tipo == tipo && p.lugar == lugar && p.id != precio?.id)) {
          throw const FormatException('Ya existe un precio para ese tipo y lugar.');
        }
        final datos = {'tipo': tipo, 'lugar': lugar, 'precio': (v['precio']! as Dinero).toJson()};
        if (precio == null) {
          await almacen.crear(Recurso.precios, datos, detalle: 'Precio registrado');
        } else {
          await almacen.actualizar(Recurso.precios, precio, precio.con(datos), detalle: 'Precio editado');
        }
      },
    );
    if (guardado && context.mounted) notificar(context, precio == null ? 'Precio registrado.' : 'Precio actualizado.');
  }
}
