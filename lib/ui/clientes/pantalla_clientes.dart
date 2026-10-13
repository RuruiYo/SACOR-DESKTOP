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
      subtitulo: 'Persona natural: DUI obligatorio. Empresa (jurídico): NIT obligatorio.',
      iniciales: {
        'nombre': cliente?.nombre,
        'tipo': cliente?.tipo ?? 'Juridico',
        'nombreComercial': cliente?.nombreComercial,
        'nit': cliente?.nit,
        'dui': cliente?.dui,
        'nrc': cliente?.nrc,
        'giro': cliente?.giro,
        'telefono': cliente?.telefono,
        'correo': cliente?.correo,
        'direccion': cliente?.direccion,
      },
      campos: [
        const CampoTexto('nombre', 'Nombre o razón social', ancho: Ancho.completo),
        CampoOpciones<String>('tipo', 'Tipo', [for (final t in Cliente.tipos) (t, conTildes(t))]),
        const CampoTexto('nombreComercial', 'Nombre comercial', obligatorio: false),
        const CampoTexto('nit', 'NIT', obligatorio: false, largo: 20),
        const CampoTexto('dui', 'DUI', obligatorio: false, largo: 10, validar: Validar.dui),
        const CampoTexto('nrc', 'NRC', obligatorio: false, largo: 30),
        const CampoTexto('giro', 'Giro', obligatorio: false),
        const CampoTexto('telefono', 'Teléfono', obligatorio: false, largo: 25, validar: Validar.telefono),
        const CampoTexto('correo', 'Correo', obligatorio: false, largo: 254, validar: Validar.correo),
        const CampoTexto('direccion', 'Dirección', obligatorio: false, largo: 250, ancho: Ancho.completo),
      ],
      alGuardar: (v) async {
        if (v['tipo'] == 'Natural' && v['dui'] == null) {
          throw const FormatException('Un cliente natural requiere DUI con formato 00000000-0.');
        }
        if (v['tipo'] == 'Juridico' && v['nit'] == null) throw const FormatException('Un cliente jurídico requiere NIT.');
        final datos = {
          for (final clave in ['nombre', 'tipo', 'nombreComercial', 'nit', 'dui', 'nrc', 'giro', 'telefono', 'correo', 'direccion'])
            clave: v[clave],
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
          onPressed: () => formularioContrato(context, null),
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
