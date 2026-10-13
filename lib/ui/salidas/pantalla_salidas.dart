import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../datos/cliente_api.dart';
import '../../datos/modelos/entidades.dart';
import '../../datos/recurso.dart';
import '../../estado/almacen.dart';
import '../../estado/navegacion_estado.dart';
import '../../estado/periodo_estado.dart';
import '../../estado/sesion_estado.dart';
import '../../nucleo/dinero.dart';
import '../../nucleo/formatos.dart';
import '../../nucleo/texto_fechado.dart';
import '../comunes/controles.dart';
import '../comunes/formulario.dart';
import '../comunes/insignia.dart';
import '../comunes/tabla.dart';
import '../comunes/tabla_paginada.dart';
import '../comunes/tarjeta.dart';

enum _Pestana { salidas, camiones }

class PantallaSalidas extends StatefulWidget {
  const PantallaSalidas({super.key});

  @override
  State<PantallaSalidas> createState() => _PantallaSalidasState();
}

class _PantallaSalidasState extends State<PantallaSalidas> {
  _Pestana _pestana = _Pestana.salidas;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<_Pestana>(
            segments: const [
              ButtonSegment(value: _Pestana.salidas, label: Text('Salidas y gasolina'), icon: Icon(Icons.route_outlined)),
              ButtonSegment(value: _Pestana.camiones, label: Text('Camiones'), icon: Icon(Icons.local_shipping_outlined)),
            ],
            selected: {_pestana},
            onSelectionChanged: (s) => setState(() => _pestana = s.first),
          ),
        ),
        const SizedBox(height: 16),
        if (_pestana == _Pestana.salidas) const _Salidas() else const _Camiones(),
      ],
    );
  }
}

class _Salidas extends StatefulWidget {
  const _Salidas();

  @override
  State<_Salidas> createState() => _SalidasState();
}

class _SalidasState extends State<_Salidas> {
  String _busqueda = '';
  DateTime? _mes;
  int? _contrato;

  @override
  void initState() {
    super.initState();
    final hoy = context.read<PeriodoEstado>().hoy;
    _mes = DateTime(hoy.year, hoy.month);
    final navegacion = context.read<NavegacionEstado>();
    _contrato = navegacion.contratoPendiente;
    navegacion.contratoPendiente = null;
  }

  @override
  Widget build(BuildContext context) {
    final almacen = context.watch<AlmacenSacor>();
    final meses = {for (final r in almacen.rutas) if (r.fecha != null) DateTime(r.fecha!.year, r.fecha!.month)}.toList()
      ..sort((a, b) => b.compareTo(a));
    if (_mes != null && !meses.contains(_mes)) meses.insert(0, _mes!);

    final contratos = {for (final r in almacen.rutas) if (r.idContrato != null) r.idContrato!}.toList()
      ..sort((a, b) => b.compareTo(a));
    if (_contrato != null && !contratos.contains(_contrato)) _contrato = null;
    String nombreContrato(int id) {
      final c = almacen.contrato(id);
      if (c == null) return 'Contrato #$id';
      return '${almacen.nombreCliente(c.idCliente)}${c.idCotizacion == null ? '' : ' · cot. #${c.idCotizacion}'}';
    }

    final texto = _busqueda.toLowerCase();
    final filas = almacen.rutas.where((r) {
      final f = r.fecha;
      if (_contrato != null) {
        if (r.idContrato != _contrato) return false;
      } else if (_mes != null && (f == null || f.year != _mes!.year || f.month != _mes!.month)) {
        return false;
      }
      return texto.isEmpty || r.destino.toLowerCase().contains(texto);
    }).toList()
      ..sort((a, b) => (b.fecha ?? DateTime(1900)).compareTo(a.fecha ?? DateTime(1900)));
    final gasolina = Dinero.sumar(filas.map((r) => r.gasolina));
    final sinFecha = almacen.rutas.where((r) => r.fecha == null).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Tarjeta(
          child: ResumenCifras(cifras: [
            ('Salidas mostradas', Formatos.entero(filas.length)),
            ('Gasolina', Formatos.usd(gasolina)),
            ('Promedio por salida', filas.isEmpty ? '—' : Formatos.usd(Dinero(gasolina.centavos ~/ filas.length))),
          ]),
        ),
        if (sinFecha > 0) ...[
          const SizedBox(height: 12),
          Aviso(
            tono: TonoInsignia.alerta,
            mensaje: '$sinFecha salida(s) sin fecha en el destino: su gasolina no entra en ningún mes. '
                'Elija "Todas" en el filtro de mes para verlas y editarlas.',
          ),
        ],
        const SizedBox(height: 16),
        Tarjeta(
          titulo: 'Salidas',
          subtitulo: 'Cada salida es un día de trabajo en un lugar: quiénes van y cuánto llevan para gasolina.',
          acciones: [
            if (_contrato != null)
              OutlinedButton.icon(
                onPressed: () => asignarPersonalContrato(context, _contrato!),
                icon: const Icon(Icons.group_add_outlined, size: 18),
                label: const Text('Asignar a todos los viajes'),
              ),
            FilledButton.icon(
              onPressed: () => formularioSalida(context, null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nueva salida'),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilaFiltros(filtros: [
                CampoBusqueda(sugerencia: 'Buscar destino', alCambiar: (t) => setState(() => _busqueda = t)),
                SelectorFiltro<DateTime?>(
                  etiqueta: 'Mes',
                  valor: _mes,
                  ancho: 200,
                  opciones: [(null, 'Todas'), for (final m in meses) (m, Formatos.mesLargo(m.year, m.month))],
                  alCambiar: (m) => setState(() => _mes = m),
                ),
                if (contratos.isNotEmpty)
                  SelectorFiltro<int?>(
                    etiqueta: 'Contrato',
                    valor: _contrato,
                    ancho: 260,
                    opciones: [(null, 'Todas las salidas'), for (final c in contratos) (c, nombreContrato(c))],
                    alCambiar: (c) => setState(() => _contrato = c),
                  ),
              ]),
              const SizedBox(height: 12),
              TablaPaginada<Ruta>(
                filas: filas,
                mensajeVacio: 'No hay salidas con esos filtros.',
                columnas: [
                  ColumnaTabla(titulo: 'Fecha', celda: (r) => Text(r.destinoFechado.fechaVisible)),
                  ColumnaTabla(titulo: 'Destino', flex: 3, celda: (r) => Text(r.destino)),
                  ColumnaTabla(
                    titulo: 'Tipo',
                    celda: (r) => r.idContrato == null
                        ? Text(r.tipo ?? '—')
                        : CeldaDoble(r.tipo ?? '—', nombreContrato(r.idContrato!)),
                  ),
                  ColumnaTabla(titulo: 'Gasolina', numerica: true, celda: (r) => Text(Formatos.usd(r.gasolina))),
                  ColumnaTabla(
                    titulo: 'Gastos del viaje',
                    numerica: true,
                    celda: (r) {
                      final gastos = almacen.gastosDeRuta(r.id);
                      return Text(gastos.esCero ? '—' : Formatos.usd(gastos));
                    },
                  ),
                  ColumnaTabla(
                    titulo: 'Personal',
                    flex: 4,
                    celda: (r) {
                      final nombres = almacen.personalDeRuta(r.id).map(almacen.nombreEmpleado).toList();
                      return Text(nombres.isEmpty ? '—' : nombres.join(', '));
                    },
                  ),
                  ColumnaTabla(
                    titulo: '',
                    anchoMinimo: 96,
                    celda: (r) => AccionesFila(
                      alEditar: () => formularioSalida(context, r),
                      alEliminar: () => eliminarConConfirmacion(
                        context,
                        que: 'la salida a ${r.destino}',
                        eliminar: () async {
                          if (almacen.contratos.any((c) => c.idRutaTrabajo == r.id)) {
                            throw const ApiExcepcion(409, 'No se puede eliminar: hay contratos que usan esta salida como ruta.');
                          }
                          await almacen.asignarPersonalRuta(r.id, {});
                          await almacen.eliminar(Recurso.rutas, r, detalle: 'Salida eliminada');
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> formularioSalida(BuildContext context, Ruta? ruta) async {
  final almacen = context.read<AlmacenSacor>();
  final usuario = context.read<SesionEstado>().usuario!;
  final hoy = context.read<PeriodoEstado>().hoy;
  final destinos = <String>{
    for (final p in almacen.precios) p.lugar,
    for (final r in almacen.rutas) r.destino,
  }.toList()
    ..sort();
  final personal = ruta == null ? <int>[] : almacen.personalDeRuta(ruta.id);
  final empleados = almacen.empleados.where((e) => e.activo || personal.contains(e.id)).toList()
    ..sort((a, b) => a.nombre.compareTo(b.nombre));

  final guardado = await mostrarFormulario(
    context,
    titulo: ruta == null ? 'Nueva salida' : 'Editar salida',
    iniciales: {
      'fecha': ruta == null ? hoy : ruta.fecha,
      'destino': ruta?.destino,
      'tipo': ruta?.tipo ?? (ruta == null ? 'Recolección' : null),
      'gasolina': ruta?.gasolina,
      'personal': personal,
    },
    campos: [
      const CampoFecha('fecha', 'Fecha'),
      const CampoDinero('gasolina', 'Dinero para gasolina', permitirCero: true),
      CampoTexto('destino', 'Destino', largo: 185, ancho: Ancho.completo, sugerencias: destinos),
      const CampoTexto('tipo', 'Tipo', obligatorio: false, largo: 60, sugerencias: ['Recolección', 'Viaje extra', 'Mantenimiento']),
      CampoSeleccion('personal', 'Personal que va', [for (final e in empleados) (e.id, '${e.nombre} (${e.tipoVisible})')]),
    ],
    alGuardar: (v) async {
      final datos = {
        'destino': TextoFechado.escribir(v['fecha'] as DateTime?, v['destino']! as String),
        'dineroGasolina': (v['gasolina']! as Dinero).toJson(),
        'tipo': v['tipo'],
      };
      final elegidos = v['personal']! as Set<int>;
      if (ruta == null) {
        final creada = await almacen.crear(Recurso.rutas, {...datos, 'idAdministrador': usuario.id},
            detalle: 'Salida registrada');
        await almacen.asignarPersonalRuta(creada[Recurso.rutas.campoId] as int, elegidos);
      } else {
        await almacen.actualizar(Recurso.rutas, ruta, ruta.con(datos), detalle: 'Salida editada');
        await almacen.asignarPersonalRuta(ruta.id, elegidos);
      }
    },
  );
  if (guardado && context.mounted) notificar(context, ruta == null ? 'Salida registrada.' : 'Salida actualizada.');
}

Future<void> asignarPersonalContrato(BuildContext context, int idContrato) async {
  final almacen = context.read<AlmacenSacor>();
  final viajes = almacen.viajesDeContrato(idContrato);
  if (viajes.isEmpty) return;

  final comunes = viajes
      .map((v) => almacen.personalDeRuta(v.id).toSet())
      .reduce((a, b) => a.intersection(b));
  final empleados = almacen.empleados.where((e) => e.activo).toList()..sort((a, b) => a.nombre.compareTo(b.nombre));

  final guardado = await mostrarFormulario(
    context,
    titulo: 'Personal del contrato de ${almacen.nombreCliente(almacen.contrato(idContrato)?.idCliente ?? 0)}',
    subtitulo: 'Reemplaza el personal de los ${viajes.length} viajes. Para cambiar un viaje en particular, edítelo en la tabla.',
    textoGuardar: 'Asignar',
    iniciales: {'personal': comunes.toList()},
    campos: [
      CampoSeleccion('personal', 'Personal que va', [for (final e in empleados) (e.id, '${e.nombre} (${e.tipoVisible})')]),
    ],
    alGuardar: (v) async {
      final elegidos = v['personal']! as Set<int>;
      for (final viaje in viajes) {
        await almacen.asignarPersonalRuta(viaje.id, elegidos);
      }
    },
  );
  if (guardado && context.mounted) notificar(context, 'Personal asignado a ${viajes.length} viaje(s).');
}

class _Camiones extends StatelessWidget {
  const _Camiones();

  @override
  Widget build(BuildContext context) {
    final almacen = context.watch<AlmacenSacor>();
    final filas = [...almacen.camiones]..sort((a, b) => a.placa.compareTo(b.placa));

    return Tarjeta(
      titulo: 'Camiones',
      subtitulo: '${filas.length} registrados',
      acciones: [
        FilledButton.icon(
          onPressed: () => _formulario(context, null),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Nuevo camión'),
        ),
      ],
      child: TablaPaginada<Camion>(
        filas: filas,
        mensajeVacio: 'No hay camiones registrados.',
        columnas: [
          ColumnaTabla(titulo: 'Placa', celda: (c) => Text(c.placa, style: Estilos.negrita)),
          ColumnaTabla(titulo: 'Nombre', celda: (c) => Text(c.nombre ?? '—')),
          ColumnaTabla(titulo: 'Tipo', celda: (c) => Text(c.tipo ?? '—')),
          ColumnaTabla(titulo: 'Estado', celda: (c) => Text(c.estado ?? '—')),
          ColumnaTabla(titulo: 'Dueño', celda: (c) => Text(c.dueno ?? '—')),
          ColumnaTabla(titulo: 'Observación', flex: 3, celda: (c) => Text(c.observacion ?? '—')),
          ColumnaTabla(
            titulo: '',
            anchoMinimo: 96,
            celda: (c) => AccionesFila(
              alEditar: () => _formulario(context, c),
              alEliminar: () => eliminarConConfirmacion(
                context,
                que: 'el camión ${c.placa}',
                eliminar: () => almacen.eliminar(Recurso.camiones, c, detalle: 'Camión eliminado'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _formulario(BuildContext context, Camion? camion) async {
    final almacen = context.read<AlmacenSacor>();
    final guardado = await mostrarFormulario(
      context,
      titulo: camion == null ? 'Nuevo camión' : 'Editar camión',
      iniciales: {
        'placa': camion?.placa,
        'nombre': camion?.nombre,
        'tipo': camion?.tipo,
        'estado': camion?.estado ?? (camion == null ? 'Activo' : null),
        'dueno': camion?.dueno,
        'observacion': camion?.observacion,
      },
      campos: [
        CampoTexto('placa', 'Placa', largo: 15, mayusculas: true,
            validar: (p) => p.length < 5 ? 'La placa no es válida.' : null),
        const CampoTexto('nombre', 'Nombre', obligatorio: false, largo: 100),
        const CampoTexto('tipo', 'Tipo', obligatorio: false, largo: 60, sugerencias: ['Volteo', 'Compactador', 'Pick-up']),
        const CampoTexto('estado', 'Estado', obligatorio: false, largo: 40,
            sugerencias: ['Activo', 'En taller', 'Fuera de servicio']),
        const CampoTexto('dueno', 'Dueño', obligatorio: false, largo: 150),
        const CampoTexto('observacion', 'Observación', obligatorio: false, largo: 1000, ancho: Ancho.completo),
      ],
      alGuardar: (v) async {
        final placa = v['placa']! as String;
        if (almacen.camiones.any((c) => c.placa.toUpperCase() == placa && c.id != camion?.id)) {
          throw const FormatException('Ya existe un camión con esa placa.');
        }
        final datos = {
          'placa': placa,
          'nombre': v['nombre'],
          'tipo': v['tipo'],
          'estado': v['estado'],
          'dueno': v['dueno'],
          'observacion': v['observacion'],
        };
        if (camion == null) {
          await almacen.crear(Recurso.camiones, datos, detalle: 'Camión registrado');
        } else {
          await almacen.actualizar(Recurso.camiones, camion, camion.con(datos), detalle: 'Camión editado');
        }
      },
    );
    if (guardado && context.mounted) notificar(context, camion == null ? 'Camión registrado.' : 'Camión actualizado.');
  }
}
