import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../configuracion/configuracion.dart';
import '../../datos/modelos/entidades.dart';
import '../../datos/recurso.dart';
import '../../estado/almacen.dart';
import '../../estado/periodo_estado.dart';
import '../../estado/sesion_estado.dart';
import '../../exportacion/tabla_reporte.dart';
import '../../nucleo/dinero.dart';
import '../../nucleo/formatos.dart';
import '../../nucleo/texto_fechado.dart';
import '../comunes/boton_exportar.dart';
import '../comunes/controles.dart';
import '../comunes/formulario.dart';
import '../comunes/insignia.dart';
import '../comunes/tabla.dart';
import '../comunes/tabla_paginada.dart';
import '../comunes/tarjeta.dart';

class PantallaServiciosExternos extends StatefulWidget {
  const PantallaServiciosExternos({super.key});

  @override
  State<PantallaServiciosExternos> createState() => _PantallaServiciosExternosState();
}

class _PantallaServiciosExternosState extends State<PantallaServiciosExternos> {
  String _busqueda = '';

  DateTime? _mes;

  static final _sinFecha = DateTime(0);

  @override
  Widget build(BuildContext context) {
    final almacen = context.watch<AlmacenSacor>();
    final hoy = context.read<PeriodoEstado>().hoy;
    final meses = {for (final s in almacen.serviciosExternos) if (s.fecha != null) DateTime(s.fecha!.year, s.fecha!.month)}
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final texto = _busqueda.toLowerCase();
    final filas = almacen.serviciosExternos.where((s) {
      if (_mes == _sinFecha && s.fecha != null) return false;
      if (_mes != null && _mes != _sinFecha && (s.fecha == null || s.fecha!.year != _mes!.year || s.fecha!.month != _mes!.month)) {
        return false;
      }
      return texto.isEmpty ||
          s.nombre.toLowerCase().contains(texto) ||
          (s.direccion?.toLowerCase().contains(texto) ?? false);
    }).toList()
      ..sort((a, b) => (b.fecha ?? DateTime(1900)).compareTo(a.fecha ?? DateTime(1900)));

    bool delMes(ServicioExterno s, DateTime mes) =>
        s.fecha != null && s.fecha!.year == mes.year && s.fecha!.month == mes.month;
    final esteMes = Dinero.sumar(almacen.serviciosExternos.where((s) => delMes(s, hoy)).map((s) => s.monto));
    final anterior = DateTime(hoy.year, hoy.month - 1);
    final mesAnterior = Dinero.sumar(almacen.serviciosExternos.where((s) => delMes(s, anterior)).map((s) => s.monto));
    final sinFecha = almacen.serviciosExternos.where((s) => s.fecha == null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Tarjeta(
          child: ResumenCifras(cifras: [
            (Formatos.mesLargo(hoy.year, hoy.month), Formatos.usd(esteMes)),
            (Formatos.mesLargo(anterior.year, anterior.month), Formatos.usd(mesAnterior)),
            ('Mostrados', Formatos.usd(Dinero.sumar(filas.map((s) => s.monto)))),
          ]),
        ),
        if (sinFecha.isNotEmpty) ...[
          const SizedBox(height: 12),
          Aviso(
            tono: TonoInsignia.alerta,
            mensaje: '${sinFecha.length} servicio(s) sin mes (por ejemplo, registrados desde la app móvil). '
                'Edítelos y elija el mes para que cuenten en los gastos de ese mes.',
          ),
        ],
        const SizedBox(height: 16),
        Tarjeta(
          titulo: 'Servicios externos',
          acciones: [
            BotonExportar(generar: () => _reporte(context, filas)),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () => _formulario(context, null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nuevo servicio'),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilaFiltros(filtros: [
                CampoBusqueda(sugerencia: 'Buscar servicio', alCambiar: (t) => setState(() => _busqueda = t)),
                SelectorFiltro<DateTime?>(
                  etiqueta: 'Mes',
                  valor: _mes,
                  ancho: 200,
                  opciones: [
                    (null, 'Todos'),
                    for (final m in meses) (m, Formatos.mesLargo(m.year, m.month)),
                    (_sinFecha, 'Sin mes'),
                  ],
                  alCambiar: (m) => setState(() => _mes = m),
                ),
              ]),
              const SizedBox(height: 12),
              TablaPaginada<ServicioExterno>(
                filas: filas,
                mensajeVacio: 'No hay servicios externos con esos filtros.',
                columnas: [
                  ColumnaTabla(titulo: 'Mes', celda: (s) => Text(s.nombreFechado.fechaVisible)),
                  ColumnaTabla(titulo: 'Servicio', flex: 4, celda: (s) => Text(s.nombre)),
                  ColumnaTabla(titulo: 'Lugar o proveedor', flex: 3, celda: (s) => Text(s.direccion ?? '—')),
                  ColumnaTabla(titulo: 'Monto', numerica: true, celda: (s) => Text(Formatos.usd(s.monto))),
                  ColumnaTabla(
                    titulo: '',
                    anchoMinimo: 96,
                    celda: (s) => AccionesFila(
                      alEditar: () => _formulario(context, s),
                      alEliminar: () => eliminarConConfirmacion(
                        context,
                        que: 'el servicio "${s.nombre}"',
                        eliminar: () =>
                            almacen.eliminar(Recurso.serviciosExternos, s, detalle: 'Servicio externo eliminado'),
                      ),
                    ),
                  ),
                ],
                pie: [
                  const Text('TOTAL'),
                  const Text(''),
                  const Text(''),
                  Text(Formatos.usd(Dinero.sumar(filas.map((s) => s.monto)))),
                  const Text(''),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  TablaReporte _reporte(BuildContext context, List<ServicioExterno> filas) => TablaReporte(
        titulo: 'Servicios externos',
        subtitulo: 'Registros: ${filas.length}',
        esDemo: context.read<Configuracion>().modoDemo,
        columnas: const [
          ColumnaReporte('Mes', TipoColumna.texto),
          ColumnaReporte('Servicio', TipoColumna.texto, flex: 4),
          ColumnaReporte('Lugar o proveedor', TipoColumna.texto, flex: 3),
          ColumnaReporte('Monto', TipoColumna.dinero),
        ],
        filas: [for (final s in filas) [s.nombreFechado.fechaVisible, s.nombre, s.direccion, s.monto]],
        totales: ['Total', null, null, Dinero.sumar(filas.map((s) => s.monto))],
      );

  Future<void> _formulario(BuildContext context, ServicioExterno? servicio) async {
    final almacen = context.read<AlmacenSacor>();
    final usuario = context.read<SesionEstado>().usuario!;
    final hoy = context.read<PeriodoEstado>().hoy;
    final lugares = {for (final s in almacen.serviciosExternos) if (s.direccion != null) s.direccion!}.toList()..sort();

    final guardado = await mostrarFormulario(
      context,
      titulo: servicio == null ? 'Nuevo servicio externo' : 'Editar servicio externo',
      subtitulo: 'Servicios que contrata SACOR, como la góndola donde se bota la basura.',
      iniciales: {
        'mes': servicio == null ? DateTime(hoy.year, hoy.month) : servicio.fecha,
        'nombre': servicio?.nombre,
        'monto': servicio?.monto,
        'direccion': servicio?.direccion,
      },
      campos: [
        const CampoFecha('mes', 'Mes', soloMes: true),
        const CampoDinero('monto', 'Monto pagado'),
        const CampoTexto('nombre', 'Servicio', largo: 138, ancho: Ancho.completo,
            sugerencias: ['Góndola', 'Relleno sanitario', 'Botadero', 'Mantenimiento de camión']),
        CampoTexto('direccion', 'Lugar o proveedor', obligatorio: false, largo: 250, ancho: Ancho.completo, sugerencias: lugares),
      ],
      alGuardar: (v) async {
        final datos = {
          'nombre': TextoFechado.escribir(v['mes'] as DateTime?, v['nombre']! as String, soloMes: true),
          'cantidadPago': (v['monto']! as Dinero).toJson(),
          'direccion': v['direccion'],
        };
        if (servicio == null) {
          await almacen.crear(Recurso.serviciosExternos, {...datos, 'idAdministrador': usuario.id},
              detalle: 'Servicio externo registrado');
        } else {
          await almacen.actualizar(Recurso.serviciosExternos, servicio, servicio.con(datos),
              detalle: 'Servicio externo editado');
        }
      },
    );
    if (guardado && context.mounted) notificar(context, servicio == null ? 'Servicio registrado.' : 'Servicio actualizado.');
  }
}
