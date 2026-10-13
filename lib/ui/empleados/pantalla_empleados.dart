import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../configuracion/configuracion.dart';
import '../../datos/modelos/entidades.dart';
import '../../datos/modelos/json.dart';
import '../../datos/recurso.dart';
import '../../estado/almacen.dart';
import '../../estado/periodo_estado.dart';
import '../../estado/sesion_estado.dart';
import '../../exportacion/tabla_reporte.dart';
import '../../nucleo/colores.dart';
import '../../nucleo/dinero.dart';
import '../../nucleo/formatos.dart';
import '../comunes/boton_exportar.dart';
import '../comunes/controles.dart';
import '../comunes/formulario.dart';
import '../comunes/insignia.dart';
import '../comunes/tabla.dart';
import '../comunes/tabla_paginada.dart';
import '../comunes/tarjeta.dart';

class PantallaEmpleados extends StatefulWidget {
  const PantallaEmpleados({super.key});

  @override
  State<PantallaEmpleados> createState() => _PantallaEmpleadosState();
}

class _PantallaEmpleadosState extends State<PantallaEmpleados> {
  String _busqueda = '';
  String? _estado = 'Activo';
  String? _tipo;
  int? _seleccionado;

  @override
  Widget build(BuildContext context) {
    final almacen = context.watch<AlmacenSacor>();
    final hoy = context.read<PeriodoEstado>().hoy;

    final ultimoPago = <int, DateTime>{};
    for (final p in almacen.pagos) {
      final fecha = p.fecha;
      if (fecha == null) continue;
      final actual = ultimoPago[p.idEmpleado];
      if (actual == null || fecha.isAfter(actual)) ultimoPago[p.idEmpleado] = fecha;
    }

    final texto = _busqueda.toLowerCase();
    final filas = almacen.empleados
        .where((e) => _estado == null || e.estado == _estado)
        .where((e) => _tipo == null || e.tipo == _tipo)
        .where((e) => texto.isEmpty || e.nombre.toLowerCase().contains(texto) || e.dui.contains(texto))
        .toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));

    final activos = almacen.empleados.where((e) => e.activo).toList();
    final inicioMes = DateTime(hoy.year, hoy.month, 1);
    bool esteMes(DateTime? f) => f != null && !f.isBefore(inicioMes) && !f.isAfter(hoy);
    final pagadoMes = Dinero.sumar(almacen.pagos.where((p) => esteMes(p.fecha)).map((p) => p.neto));
    final anticiposMes = Dinero.sumar(almacen.anticipos.where((a) => esteMes(a.fecha)).map((a) => a.cantidad));

    final seleccionado = _seleccionado == null ? null : almacen.empleado(_seleccionado!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Tarjeta(
          child: ResumenCifras(cifras: [
            ('Empleados activos', Formatos.entero(activos.length)),
            ('Sueldos mensuales (activos)', Formatos.usd(Dinero.sumar(activos.map((e) => e.sueldo)))),
            ('Pagado en ${Formatos.nombreMes(hoy.month).toLowerCase()}', Formatos.usd(pagadoMes)),
            ('Anticipos en ${Formatos.nombreMes(hoy.month).toLowerCase()}', Formatos.usd(anticiposMes)),
          ]),
        ),
        const SizedBox(height: 16),
        Tarjeta(
          titulo: 'Planilla de empleados',
          acciones: [
            BotonExportar(generar: () => _reporte(context, filas, ultimoPago)),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () => _formularioEmpleado(context, null),
              icon: const Icon(Icons.person_add_alt, size: 18),
              label: const Text('Nuevo empleado'),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilaFiltros(filtros: [
                CampoBusqueda(sugerencia: 'Buscar por nombre o DUI', alCambiar: (t) => setState(() => _busqueda = t)),
                SelectorFiltro<String?>(
                  etiqueta: 'Estado',
                  valor: _estado,
                  ancho: 170,
                  opciones: [(null, 'Todos'), for (final e in Empleado.estados) (e, e)],
                  alCambiar: (v) => setState(() => _estado = v),
                ),
                SelectorFiltro<String?>(
                  etiqueta: 'Tipo',
                  valor: _tipo,
                  ancho: 190,
                  opciones: [
                    (null, 'Todos'),
                    for (final t in [...Empleado.tipos, ...Empleado.tiposAnteriores]) (t, conTildes(t)),
                  ],
                  alCambiar: (v) => setState(() => _tipo = v),
                ),
              ]),
              const SizedBox(height: 12),
              TablaPaginada<Empleado>(
                filas: filas,
                mensajeVacio: 'No hay empleados con esos filtros.',
                esSeleccionada: (e) => e.id == _seleccionado,
                alTocar: (e) => setState(() => _seleccionado = e.id == _seleccionado ? null : e.id),
                columnas: [
                  ColumnaTabla(titulo: 'Empleado', flex: 4, anchoMinimo: 220, celda: (e) => CeldaDoble(e.nombre, 'DUI ${e.dui}')),
                  ColumnaTabla(titulo: 'Tipo', celda: (e) => Text(e.tipoVisible)),
                  ColumnaTabla(titulo: 'Estado', anchoMinimo: 110, celda: (e) => _InsigniaEstado(e.estado)),
                  ColumnaTabla(titulo: 'Teléfono', celda: (e) => Text(e.telefono ?? '—')),
                  ColumnaTabla(titulo: 'Sueldo', numerica: true, celda: (e) => Text(Formatos.usd(e.sueldo))),
                  ColumnaTabla(titulo: 'Ingreso', celda: (e) => Text(Formatos.fecha(e.fechaIngreso))),
                  ColumnaTabla(titulo: 'Último pago', celda: (e) => Text(Formatos.fecha(ultimoPago[e.id]))),
                  ColumnaTabla(
                    titulo: '',
                    flex: 2,
                    anchoMinimo: 150,
                    celda: (e) => AccionesFila(
                      extras: [
                        BotonFila(
                          tooltip: 'Registrar pago',
                          icono: Icons.payments_outlined,
                          color: ColoresSacor.verde,
                          alPresionar: () => _formularioPago(context, e, null),
                        ),
                      ],
                      alEditar: () => _formularioEmpleado(context, e),
                      alEliminar: () => _eliminarEmpleado(context, e),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (seleccionado != null) ...[
          const SizedBox(height: 16),
          _DetalleEmpleado(
            empleado: seleccionado,
            alRegistrarPago: () => _formularioPago(context, seleccionado, null),
            alEditarPago: (p) => _formularioPago(context, seleccionado, p),
            alRegistrarAnticipo: () => _formularioAnticipo(context, seleccionado, null),
            alEditarAnticipo: (a) => _formularioAnticipo(context, seleccionado, a),
            alCerrar: () => setState(() => _seleccionado = null),
          ),
        ],
      ],
    );
  }

  TablaReporte _reporte(BuildContext context, List<Empleado> filas, Map<int, DateTime> ultimoPago) => TablaReporte(
        titulo: 'Planilla de empleados',
        subtitulo: 'Empleados: ${filas.length}',
        esDemo: context.read<Configuracion>().modoDemo,
        columnas: const [
          ColumnaReporte('Nombre', TipoColumna.texto, flex: 4),
          ColumnaReporte('DUI', TipoColumna.texto),
          ColumnaReporte('Tipo', TipoColumna.texto),
          ColumnaReporte('Estado', TipoColumna.texto),
          ColumnaReporte('Teléfono', TipoColumna.texto),
          ColumnaReporte('Sueldo', TipoColumna.dinero),
          ColumnaReporte('Ingreso', TipoColumna.fecha),
          ColumnaReporte('Último pago', TipoColumna.fecha),
        ],
        filas: [
          for (final e in filas)
            [e.nombre, e.dui, e.tipoVisible, e.estado, e.telefono, e.sueldo, e.fechaIngreso, ultimoPago[e.id]],
        ],
        totales: ['Total', null, null, null, null, Dinero.sumar(filas.map((e) => e.sueldo)), null, null],
      );

  Future<void> _formularioEmpleado(BuildContext context, Empleado? empleado) async {
    final almacen = context.read<AlmacenSacor>();
    final usuario = context.read<SesionEstado>().usuario!;
    final hoy = context.read<PeriodoEstado>().hoy;
    final nuevo = empleado == null;
    String? codigoNuevo;

    final guardado = await mostrarFormulario(
      context,
      titulo: nuevo ? 'Nuevo empleado' : 'Editar empleado',
      subtitulo: empleado == null ? 'El código de acceso se genera automáticamente.' : empleado.nombre,
      iniciales: {
        'nombre': empleado?.nombre,
        'dui': empleado?.dui,
        'telefono': empleado?.telefono,
        'tipo': empleado?.tipo,
        'estado': empleado?.estado ?? 'Activo',
        'sueldo': empleado?.sueldo,
        'fechaIngreso': empleado?.fechaIngreso ?? hoy,
        'codigoAf': empleado?.codigoAf,
      },
      campos: [
        const CampoTexto('nombre', 'Nombre completo', ancho: Ancho.completo),
        const CampoTexto('dui', 'DUI', largo: 10, validar: Validar.dui, ayuda: '00000000-0'),
        const CampoTexto('telefono', 'Teléfono', obligatorio: false, largo: 25, validar: Validar.telefono),
        CampoOpciones<String>('tipo', 'Tipo', [
          for (final t in Empleado.tipos) (t, conTildes(t)),
          if (empleado != null && empleado.tipoAnterior) (empleado.tipo, '${conTildes(empleado.tipo)} (ya no existe)'),
        ]),
        CampoOpciones<String>('estado', 'Estado', [for (final e in Empleado.estados) (e, e)]),
        const CampoDinero('sueldo', 'Sueldo mensual', permitirCero: true),
        const CampoFecha('fechaIngreso', 'Fecha de ingreso'),
        const CampoTexto('codigoAf', 'Código AF', obligatorio: false, largo: 30),
      ],
      alGuardar: (v) async {
        final ingreso = v['fechaIngreso']! as DateTime;
        if (ingreso.isBefore(DateTime(1990)) || ingreso.isAfter(hoy.add(const Duration(days: 1)))) {
          throw const FormatException('La fecha de ingreso está fuera del rango permitido.');
        }
        final dui = v['dui']! as String;
        if (almacen.empleados.any((e) => e.dui == dui && e.id != empleado?.id)) {
          throw const FormatException('Ya existe un empleado con ese DUI.');
        }
        final datos = <String, Object?>{
          'nombre': v['nombre'],
          'dui': dui,
          'telefono': v['telefono'],
          'tipo': v['tipo'],
          'estado': v['estado'],
          'sueldo': (v['sueldo']! as Dinero).toJson(),
          'fechaIngreso': fechaJson(ingreso),
          'codigoAf': v['codigoAf'],
        };

        if (empleado == null) {
          final codigo = _generarCodigo(almacen, v['tipo']! as String);
          await almacen.crear(Recurso.empleados, {...datos, 'codigoEmpleado': codigo, 'idAdministradorRegistro': usuario.id},
              detalle: 'Empleado registrado');
          codigoNuevo = codigo;
        } else {
          if (empleado.id == usuario.id && (v['tipo'] != Empleado.administradorOperativo || v['estado'] != 'Activo')) {
            throw const FormatException('No puede quitarse a sí mismo el rol de administrador ni desactivarse.');
          }
          await almacen.actualizar(Recurso.empleados, empleado, empleado.con(datos), detalle: 'Empleado editado');
        }
      },
    );
    if (!guardado || !context.mounted) return;
    final codigo = codigoNuevo;
    if (codigo != null) {
      final creado = almacen.empleados.where((e) => e.codigo == codigo).firstOrNull;
      await _mostrarCodigo(context, creado?.nombre ?? '', codigo, nuevo: true);
    } else if (!nuevo) {
      notificar(context, 'Empleado actualizado.');
    }
  }

  static String _generarCodigo(AlmacenSacor almacen, String tipo) {
    final azar = Random.secure();
    final admin = tipo.startsWith('Administrador');
    final existentes = almacen.empleados.map((e) => e.codigo).toSet();
    for (var intento = 0; intento < 200; intento++) {
      final codigo = (admin ? 100000 + azar.nextInt(900000) : 1000 + azar.nextInt(9000)).toString();
      if (!existentes.contains(codigo)) return codigo;
    }
    throw const FormatException('No se pudo generar un código libre. Intente de nuevo.');
  }

  static Future<void> _mostrarCodigo(BuildContext context, String nombre, String codigo, {bool nuevo = false}) {
    return showDialog<void>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: Text(nuevo ? 'Empleado registrado' : 'Código de acceso'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Código de acceso de $nombre:', style: Estilos.secundario),
            const SizedBox(height: 8),
            SelectableText(codigo, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 4)),
            const SizedBox(height: 8),
            const Text('Es su contraseña para la app móvil (y para el escritorio si es administrador). '
                'Entrégueselo en privado.', style: Estilos.tenue),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Clipboard.setData(ClipboardData(text: codigo)),
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copiar'),
          ),
          FilledButton(onPressed: () => Navigator.of(contexto).pop(), child: const Text('Listo')),
        ],
      ),
    );
  }

  Future<void> _eliminarEmpleado(BuildContext context, Empleado empleado) async {
    if (empleado.id == context.read<SesionEstado>().usuario?.id) {
      notificar(context, 'No puede eliminar su propio usuario.', error: true);
      return;
    }
    final almacen = context.read<AlmacenSacor>();
    await eliminarConConfirmacion(
      context,
      que: 'al empleado ${empleado.nombre}',
      eliminar: () => almacen.eliminar(Recurso.empleados, empleado, detalle: 'Empleado eliminado'),
    );
    if (_seleccionado == empleado.id && almacen.empleado(empleado.id) == null) setState(() => _seleccionado = null);
  }

  Future<void> _formularioPago(BuildContext context, Empleado empleado, Pago? pago) async {
    final almacen = context.read<AlmacenSacor>();
    final hoy = context.read<PeriodoEstado>().hoy;
    final guardado = await mostrarFormulario(
      context,
      titulo: pago == null ? 'Registrar pago' : 'Editar pago',
      subtitulo: empleado.nombre,
      iniciales: {
        'fecha': pago?.fecha ?? hoy,
        'cantidad': pago?.cantidad ?? (pago == null ? Dinero(empleado.sueldo.centavos ~/ 2) : null),
        'descuento': pago?.descuento ?? const Dinero.cero(),
        'observacion': pago?.observacion,
      },
      campos: const [
        CampoFecha('fecha', 'Fecha'),
        CampoDinero('cantidad', 'Cantidad', ayuda: 'Monto bruto del pago.'),
        CampoDinero('descuento', 'Descuento', permitirCero: true, ayuda: 'Por ejemplo, anticipo devuelto.'),
        CampoTexto('observacion', 'Observación', obligatorio: false, largo: 1000, ancho: Ancho.completo),
      ],
      alGuardar: (v) async {
        final cantidad = v['cantidad']! as Dinero;
        final descuento = v['descuento']! as Dinero;
        if (descuento > cantidad) throw const FormatException('El descuento no puede ser mayor que la cantidad.');
        final datos = {
          'idEmpleado': empleado.id,
          'fecha': fechaJson(v['fecha']! as DateTime),
          'cantidad': cantidad.toJson(),
          'descuento': descuento.toJson(),
          'observacion': v['observacion'],
        };
        if (pago == null) {
          await almacen.crear(Recurso.pagos, datos, detalle: 'Pago registrado');
        } else {
          await almacen.actualizar(Recurso.pagos, pago, pago.con(datos), detalle: 'Pago editado');
        }
      },
    );
    if (guardado && context.mounted) {
      notificar(context, pago == null ? 'Pago registrado.' : 'Pago actualizado.');
      setState(() => _seleccionado = empleado.id);
    }
  }

  Future<void> _formularioAnticipo(BuildContext context, Empleado empleado, Anticipo? anticipo) async {
    final almacen = context.read<AlmacenSacor>();
    final hoy = context.read<PeriodoEstado>().hoy;
    final guardado = await mostrarFormulario(
      context,
      titulo: anticipo == null ? 'Registrar anticipo' : 'Editar anticipo',
      subtitulo: empleado.nombre,
      iniciales: {'fecha': anticipo?.fecha ?? hoy, 'cantidad': anticipo?.cantidad, 'observacion': anticipo?.observacion},
      campos: const [
        CampoFecha('fecha', 'Fecha de entrega'),
        CampoDinero('cantidad', 'Cantidad'),
        CampoTexto('observacion', 'Observación', obligatorio: false, largo: 1000, ancho: Ancho.completo),
      ],
      alGuardar: (v) async {
        final datos = {
          'idEmpleado': empleado.id,
          'fecha': fechaJson(v['fecha']! as DateTime),
          'cantidad': (v['cantidad']! as Dinero).toJson(),
          'observacion': v['observacion'],
        };
        if (anticipo == null) {
          await almacen.crear(Recurso.anticipos, datos, detalle: 'Anticipo registrado');
        } else {
          await almacen.actualizar(Recurso.anticipos, anticipo, anticipo.con(datos), detalle: 'Anticipo editado');
        }
      },
    );
    if (guardado && context.mounted) notificar(context, anticipo == null ? 'Anticipo registrado.' : 'Anticipo actualizado.');
  }
}

class _InsigniaEstado extends StatelessWidget {
  const _InsigniaEstado(this.estado);

  final String estado;

  @override
  Widget build(BuildContext context) => switch (estado) {
        'Activo' => const Insignia('Activo', tono: TonoInsignia.exito, icono: Icons.check_circle_outline),
        'Suspendido' => const Insignia('Suspendido', tono: TonoInsignia.alerta, icono: Icons.pause_circle_outline),
        _ => Insignia(estado, icono: Icons.remove_circle_outline),
      };
}

class _DetalleEmpleado extends StatelessWidget {
  const _DetalleEmpleado({
    required this.empleado,
    required this.alRegistrarPago,
    required this.alEditarPago,
    required this.alRegistrarAnticipo,
    required this.alEditarAnticipo,
    required this.alCerrar,
  });

  final Empleado empleado;
  final VoidCallback alRegistrarPago;
  final void Function(Pago pago) alEditarPago;
  final VoidCallback alRegistrarAnticipo;
  final void Function(Anticipo anticipo) alEditarAnticipo;
  final VoidCallback alCerrar;

  @override
  Widget build(BuildContext context) {
    final almacen = context.watch<AlmacenSacor>();
    int porFecha(DateTime? a, DateTime? b) => (b ?? DateTime(1900)).compareTo(a ?? DateTime(1900));
    final pagos = almacen.pagos.where((p) => p.idEmpleado == empleado.id).toList()
      ..sort((a, b) => porFecha(a.fecha, b.fecha));
    final anticipos = almacen.anticipos.where((a) => a.idEmpleado == empleado.id).toList()
      ..sort((a, b) => porFecha(a.fecha, b.fecha));

    return Tarjeta(
      titulo: empleado.nombre,
      subtitulo: '${empleado.tipoVisible} · ingresó el ${Formatos.fecha(empleado.fechaIngreso)}',
      acciones: [
        TextButton.icon(
          onPressed: () => _PantallaEmpleadosState._mostrarCodigo(context, empleado.nombre, empleado.codigo),
          icon: const Icon(Icons.key_outlined, size: 18),
          label: const Text('Ver código'),
        ),
        const SizedBox(width: 4),
        OutlinedButton.icon(
          onPressed: alRegistrarAnticipo,
          icon: const Icon(Icons.savings_outlined, size: 18),
          label: const Text('Registrar anticipo'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: alRegistrarPago,
          icon: const Icon(Icons.payments_outlined, size: 18),
          label: const Text('Registrar pago'),
        ),
        IconButton(tooltip: 'Cerrar', onPressed: alCerrar, icon: const Icon(Icons.close)),
      ],
      child: LayoutBuilder(builder: (context, restricciones) {
        final tablaPagos = _Seccion(
          titulo: 'Pagos (${pagos.length})',
          child: TablaPaginada<Pago>(
            filas: pagos,
            tamano: 10,
            mensajeVacio: 'Sin pagos registrados.',
            columnas: [
              ColumnaTabla(titulo: 'Fecha', celda: (p) => Text(Formatos.fecha(p.fecha))),
              ColumnaTabla(titulo: 'Cantidad', numerica: true, celda: (p) => Text(Formatos.usd(p.cantidad))),
              ColumnaTabla(titulo: 'Descuento', numerica: true, celda: (p) => Text(Formatos.usd(p.descuento))),
              ColumnaTabla(titulo: 'Neto', numerica: true, celda: (p) => Text(Formatos.usd(p.neto))),
              ColumnaTabla(titulo: 'Observación', flex: 3, celda: (p) => Text(p.observacion ?? '—')),
              ColumnaTabla(
                titulo: '',
                anchoMinimo: 96,
                celda: (p) => AccionesFila(
                  alEditar: () => alEditarPago(p),
                  alEliminar: () => eliminarConConfirmacion(
                    context,
                    que: 'el pago del ${Formatos.fecha(p.fecha)}',
                    eliminar: () => almacen.eliminar(Recurso.pagos, p, detalle: 'Pago eliminado'),
                  ),
                ),
              ),
            ],
          ),
        );
        final tablaAnticipos = _Seccion(
          titulo: 'Anticipos (${anticipos.length})',
          child: TablaPaginada<Anticipo>(
            filas: anticipos,
            tamano: 10,
            mensajeVacio: 'Sin anticipos registrados.',
            columnas: [
              ColumnaTabla(titulo: 'Fecha', celda: (a) => Text(Formatos.fecha(a.fecha))),
              ColumnaTabla(titulo: 'Cantidad', numerica: true, celda: (a) => Text(Formatos.usd(a.cantidad))),
              ColumnaTabla(titulo: 'Observación', flex: 3, celda: (a) => Text(a.observacion ?? '—')),
              ColumnaTabla(
                titulo: '',
                anchoMinimo: 96,
                celda: (a) => AccionesFila(
                  alEditar: () => alEditarAnticipo(a),
                  alEliminar: () => eliminarConConfirmacion(
                    context,
                    que: 'el anticipo del ${Formatos.fecha(a.fecha)}',
                    eliminar: () => almacen.eliminar(Recurso.anticipos, a, detalle: 'Anticipo eliminado'),
                  ),
                ),
              ),
            ],
          ),
        );

        if (restricciones.maxWidth < 1100) {
          return Column(children: [tablaPagos, const SizedBox(height: 20), tablaAnticipos]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: tablaPagos),
            const SizedBox(width: 24),
            Expanded(flex: 2, child: tablaAnticipos),
          ],
        );
      }),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [Text(titulo, style: Estilos.negrita), const SizedBox(height: 8), child],
      );
}
