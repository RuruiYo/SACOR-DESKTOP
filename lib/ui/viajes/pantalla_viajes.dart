import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../datos/modelos/entidades.dart';
import '../../datos/recurso.dart';
import '../../estado/almacen.dart';
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

class PantallaViajes extends StatefulWidget {
  const PantallaViajes({super.key});

  @override
  State<PantallaViajes> createState() => _PantallaViajesState();
}

class _PantallaViajesState extends State<PantallaViajes> {
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    final almacen = context.watch<AlmacenSacor>();
    final texto = _busqueda.toLowerCase();
    final filas = almacen.viajesExtra
        .where((v) =>
            texto.isEmpty ||
            v.tipo.toLowerCase().contains(texto) ||
            almacen.nombreCliente(v.idCliente).toLowerCase().contains(texto))
        .toList()
      ..sort((a, b) => (b.fecha ?? DateTime(1900)).compareTo(a.fecha ?? DateTime(1900)));
    final sinFecha = almacen.viajesExtra.where((v) => v.fecha == null).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Tarjeta(
          child: ResumenCifras(cifras: [
            ('Viajes registrados', Formatos.entero(almacen.viajesExtra.length)),
            ('Viajes realizados', Formatos.entero(almacen.viajesExtra.fold(0, (t, v) => t + v.cantidad))),
            ('Venta total', Formatos.usd(Dinero.sumar(almacen.viajesExtra.map((v) => v.total)))),
          ]),
        ),
        if (sinFecha > 0) ...[
          const SizedBox(height: 12),
          Aviso(
            tono: TonoInsignia.alerta,
            mensaje: '$sinFecha viaje(s) sin mes (por ejemplo, registrados desde la app móvil): no entran en las '
                'ventas de ningún mes. Edítelos y elija el mes.',
          ),
        ],
        const SizedBox(height: 16),
        Tarjeta(
          titulo: 'Viajes extra',
          acciones: [
            FilledButton.icon(
              onPressed: () => _formulario(context, null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nuevo viaje extra'),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilaFiltros(filtros: [
                CampoBusqueda(sugerencia: 'Buscar por cliente o tipo', alCambiar: (t) => setState(() => _busqueda = t)),
              ]),
              const SizedBox(height: 12),
              TablaPaginada<ViajeExtra>(
                filas: filas,
                mensajeVacio: 'No hay viajes extra.',
                columnas: [
                  ColumnaTabla(titulo: 'Mes', celda: (v) => Text(v.tipoFechado.fechaVisible)),
                  ColumnaTabla(titulo: 'Cliente', flex: 3, celda: (v) => Text(almacen.nombreCliente(v.idCliente))),
                  ColumnaTabla(titulo: 'Tipo', flex: 3, celda: (v) => Text(v.tipo.isEmpty ? '—' : v.tipo)),
                  ColumnaTabla(titulo: 'Camión', celda: (v) => Text(almacen.camion(v.idCamion)?.descripcion ?? '—')),
                  ColumnaTabla(titulo: 'Precio', numerica: true, celda: (v) => Text(Formatos.usd(v.precio))),
                  ColumnaTabla(titulo: 'Viajes', numerica: true, anchoMinimo: 70, celda: (v) => Text('${v.cantidad}')),
                  ColumnaTabla(titulo: 'Total', numerica: true, celda: (v) => Text(Formatos.usd(v.total))),
                  ColumnaTabla(
                    titulo: 'Personal',
                    flex: 3,
                    celda: (v) {
                      final nombres = almacen.personalDeViaje(v.id).map(almacen.nombreEmpleado).toList();
                      return Text(nombres.isEmpty ? '—' : nombres.join(', '));
                    },
                  ),
                  ColumnaTabla(
                    titulo: '',
                    anchoMinimo: 96,
                    celda: (v) => AccionesFila(
                      alEditar: () => _formulario(context, v),
                      alEliminar: () => eliminarConConfirmacion(
                        context,
                        que: 'el viaje extra "${v.tipo}"',
                        eliminar: () async {
                          await almacen.asignarPersonalViaje(v.id, {});
                          await almacen.eliminar(Recurso.viajesExtra, v, detalle: 'Viaje extra eliminado');
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

  Future<void> _formulario(BuildContext context, ViajeExtra? viaje) async {
    final almacen = context.read<AlmacenSacor>();
    final usuario = context.read<SesionEstado>().usuario!;
    final hoy = context.read<PeriodoEstado>().hoy;
    if (almacen.clientes.isEmpty || almacen.camiones.isEmpty) {
      notificar(context, 'Para un viaje extra se necesitan al menos un cliente y un camión.', error: true);
      return;
    }
    final personal = viaje == null ? <int>[] : almacen.personalDeViaje(viaje.id);
    final empleados = almacen.empleados.where((e) => e.activo || personal.contains(e.id)).toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));

    final guardado = await mostrarFormulario(
      context,
      titulo: viaje == null ? 'Nuevo viaje extra' : 'Editar viaje extra',
      iniciales: {
        'mes': viaje == null ? DateTime(hoy.year, hoy.month) : viaje.fecha,
        'cliente': viaje?.idCliente,
        'tipo': viaje?.tipo,
        'camion': viaje?.idCamion,
        'precio': viaje?.precio,
        'cantidad': viaje?.cantidad ?? 1,
        'personal': personal,
      },
      campos: [
        const CampoFecha('mes', 'Mes', soloMes: true),
        CampoOpciones<int>('cliente', 'Cliente', [
          for (final c in [...almacen.clientes]..sort((a, b) => a.nombre.compareTo(b.nombre))) (c.id, c.nombre),
        ]),
        const CampoTexto('tipo', 'Descripción', largo: 50, ancho: Ancho.completo,
            sugerencias: ['Transporte extra', 'Retiro de ripio', 'Retiro de poda', 'Viaje expreso']),
        CampoOpciones<int>('camion', 'Camión', [for (final c in almacen.camiones) (c.id, c.descripcion)]),
        const CampoDinero('precio', 'Precio por viaje'),
        const CampoNumero('cantidad', 'Cantidad de viajes', minimo: 1, maximo: 100000),
        CampoSeleccion('personal', 'Personal del viaje', [for (final e in empleados) (e.id, '${e.nombre} (${e.tipoVisible})')]),
      ],
      alGuardar: (v) async {
        final precio = v['precio']! as Dinero;
        final cantidad = v['cantidad']! as int;
        final datos = {
          'idCliente': v['cliente'],
          'idCamion': v['camion'],
          'tipo': TextoFechado.escribir(v['mes'] as DateTime?, v['tipo']! as String, soloMes: true),
          'precio': precio.toJson(),
          'cantidad': cantidad,
          'pagoMonto': precio.multiplicar(cantidad).toJson(),
        };
        final elegidos = v['personal']! as Set<int>;
        if (viaje == null) {
          final creado = await almacen.crear(Recurso.viajesExtra, {...datos, 'idAdministrador': usuario.id},
              detalle: 'Viaje extra registrado');
          await almacen.asignarPersonalViaje(creado[Recurso.viajesExtra.campoId] as int, elegidos);
        } else {
          await almacen.actualizar(Recurso.viajesExtra, viaje, viaje.con(datos), detalle: 'Viaje extra editado');
          await almacen.asignarPersonalViaje(viaje.id, elegidos);
        }
      },
    );
    if (guardado && context.mounted) notificar(context, viaje == null ? 'Viaje registrado.' : 'Viaje actualizado.');
  }
}
