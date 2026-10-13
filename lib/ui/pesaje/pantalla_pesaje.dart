import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../calculos/contabilidad.dart';
import '../../calculos/planilla_pesaje.dart';
import '../../configuracion/configuracion.dart';
import '../../datos/modelos/entidades.dart';
import '../../datos/modelos/json.dart';
import '../../datos/recurso.dart';
import '../../estado/almacen.dart';
import '../../estado/navegacion_estado.dart';
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
import '../comunes/tarjeta.dart';

final _libras = NumberFormat('#,##0.0', 'en_US');
final _toneladas = NumberFormat('#,##0.00', 'en_US');

String formatoLibras(double valor) => valor == 0 ? '—' : _libras.format(valor);
String formatoToneladas(double valor) => valor == 0 ? '—' : _toneladas.format(valor);
String formatoVenta(double valor) => valor == 0 ? '—' : Formatos.usd(aDinero(valor));

class PantallaPesaje extends StatefulWidget {
  const PantallaPesaje({super.key});

  @override
  State<PantallaPesaje> createState() => _PantallaPesajeState();
}

class _PantallaPesajeState extends State<PantallaPesaje> {
  String? _plaza;
  late DateTime _mes;
  int? _tecnico;

  @override
  void initState() {
    super.initState();
    final hoy = context.read<PeriodoEstado>().hoy;
    _mes = DateTime(hoy.year, hoy.month);
  }

  @override
  Widget build(BuildContext context) {
    final almacen = context.watch<AlmacenSacor>();
    final plazas = plazasConContrato(almacen.contratos, almacen.precio);

    if (plazas.isEmpty) {
      return Tarjeta(
        child: Column(
          children: [
            const Aviso(
              tono: TonoInsignia.info,
              titulo: 'Todavía no hay contratos',
              mensaje: 'El cuadro de pesaje se arma por plaza a partir de los contratos (servicio_contrato) y sus '
                  'precios por tonelada. Regístrelos en Clientes y contratos.',
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.read<NavegacionEstado>().ir(Seccion.clientes),
              child: const Text('Ir a Clientes y contratos'),
            ),
          ],
        ),
      );
    }

    final plaza = plazas.contains(_plaza) ? _plaza! : plazas.first;
    final tecnicos = _tecnicos(almacen);
    if (_tecnico != null && !tecnicos.any((t) => t.id == _tecnico)) _tecnico = null;
    final planilla = PlanillaPesaje.armar(
      lugar: plaza,
      mes: _mes,
      contratos: almacen.contratos,
      precio: almacen.precio,
      pesajes: _tecnico == null ? almacen.pesajes : almacen.pesajes.where((p) => p.idTecnico == _tecnico).toList(),
    );
    final tecnicoActual = _tecnico ?? tecnicoPorDefecto(almacen, plaza);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Tarjeta(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SelectorFiltro<String>(
                etiqueta: 'Plaza',
                valor: plaza,
                ancho: 260,
                opciones: [for (final p in plazas) (p, p)],
                alCambiar: (p) => setState(() {
                  _plaza = p;
                  _tecnico = null;
                }),
              ),
              _SelectorMes(mes: _mes, alCambiar: (m) => setState(() => _mes = m)),
              SelectorFiltro<int?>(
                etiqueta: 'Técnico',
                valor: _tecnico,
                ancho: 260,
                opciones: [
                  (null, 'Todos los técnicos'),
                  for (final t in tecnicos) (t.id, t.nombre),
                ],
                alCambiar: (id) => setState(() => _tecnico = id),
              ),
              const SizedBox(width: 4),
              FilledButton.icon(
                onPressed: () => formularioPesaje(context, plaza: plaza, fecha: _fechaSugerida(), tecnico: tecnicoActual),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar pesaje'),
              ),
              BotonExportar(generar: () => _reporte(context, planilla)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Tarjeta(
          child: ResumenCifras(cifras: [
            ('Toneladas', _toneladas.format(planilla.toneladasTotal)),
            ('Venta', Formatos.usd(aDinero(planilla.venta))),
            ('IVA 13 %', Formatos.usd(aDinero(planilla.iva))),
            ('Total con IVA', Formatos.usd(aDinero(planilla.venta + planilla.iva))),
            ('Pago a cuenta 1.75 %', Formatos.usd(aDinero(planilla.pagoCuenta))),
            ('Días con pesaje', '${planilla.diasConPesaje}'),
          ]),
        ),
        const SizedBox(height: 16),
        Tarjeta(
          titulo: 'Detalle de $plaza · ${Formatos.mesLargo(_mes.year, _mes.month)}'
              '${_tecnico == null ? '' : ' · ${almacen.nombreEmpleado(_tecnico!)}'}',
          subtitulo: 'Toneladas = libras ÷ 2200. Toque un día para ver, agregar o corregir sus pesajes.',
          child: _CuadroPesaje(
            planilla: planilla,
            alTocarDia: (fila) => mostrarDialogo(context, plaza, fila.dia, tecnicoActual, soloTecnico: _tecnico),
          ),
        ),
        const SizedBox(height: 16),
        _ResumenPlazas(mes: _mes, plazas: plazas),
      ],
    );
  }

  DateTime _fechaSugerida() {
    final hoy = context.read<PeriodoEstado>().hoy;
    return hoy.year == _mes.year && hoy.month == _mes.month ? hoy : _mes;
  }

  Future<void> mostrarDialogo(BuildContext context, String plaza, DateTime dia, int? tecnico, {int? soloTecnico}) =>
      showDialog<void>(
        context: context,
        builder: (_) => _DialogoDia(plaza: plaza, dia: dia, tecnico: tecnico, soloTecnico: soloTecnico),
      );

  TablaReporte _reporte(BuildContext context, PlanillaPesaje planilla) {
    final columnas = <ColumnaReporte>[const ColumnaReporte('Fecha', TipoColumna.fecha)];
    for (final c in planilla.columnas) {
      for (final e in c.etapas) {
        columnas.add(ColumnaReporte('${c.tipo} $e (lb)', TipoColumna.decimal));
      }
      columnas
        ..add(ColumnaReporte('${c.tipo} (lb)', TipoColumna.decimal))
        ..add(ColumnaReporte('${c.tipo} (t)', TipoColumna.decimal))
        ..add(ColumnaReporte('${c.tipo} \$/t', TipoColumna.dinero))
        ..add(ColumnaReporte('${c.tipo} total', TipoColumna.dinero));
    }
    columnas.add(const ColumnaReporte('Total del día', TipoColumna.dinero));

    List<Object?> celdas(List<CeldaPlanilla> fila) => [
          for (var i = 0; i < planilla.columnas.length; i++) ...[
            for (final e in planilla.columnas[i].etapas) fila[i].librasPorEtapa[e] ?? 0.0,
            fila[i].libras,
            fila[i].toneladas,
            planilla.columnas[i].precio?.precio,
            aDinero(fila[i].venta),
          ],
        ];

    return TablaReporte(
      titulo: 'Cuadro de pesaje ${planilla.lugar}',
      subtitulo: '${Formatos.mesLargo(planilla.mes.year, planilla.mes.month)} · toneladas = libras ÷ 2200',
      esDemo: context.read<Configuracion>().modoDemo,
      columnas: columnas,
      filas: [
        for (final f in planilla.filas) [f.dia, ...celdas(f.celdas), aDinero(f.venta)],
      ],
      totales: ['TOTAL', ...celdas(planilla.totales), aDinero(planilla.venta)],
      notas: [
        'IVA 13 %: ${Formatos.usd(aDinero(planilla.iva))} · Total con IVA: '
            '${Formatos.usd(aDinero(planilla.venta + planilla.iva))} · Pago a cuenta 1.75 %: '
            '${Formatos.usd(aDinero(planilla.pagoCuenta))}',
      ],
    );
  }
}

List<Empleado> _tecnicos(AlmacenSacor almacen) => almacen.empleados
    .where((e) => e.activo && e.tipo == 'Tecnico')
    .toList()
  ..sort((a, b) => a.nombre.compareTo(b.nombre));

int? tecnicoPorDefecto(AlmacenSacor almacen, String plaza) {
  final salidas = almacen.rutas.where((r) => r.destino == plaza && r.fecha != null).toList()
    ..sort((a, b) => b.fecha!.compareTo(a.fecha!));
  for (final salida in salidas.take(20)) {
    for (final id in almacen.personalDeRuta(salida.id)) {
      final empleado = almacen.empleado(id);
      if (empleado != null && empleado.activo && empleado.tipo == 'Tecnico') return id;
    }
  }
  final contratos = {for (final c in almacen.contratos) if (almacen.precio(c.idPrecioLugar)?.lugar == plaza) c.id};
  final pesajes = almacen.pesajes.where((p) => contratos.contains(p.idContrato) && p.fecha != null).toList()
    ..sort((a, b) => b.fecha!.compareTo(a.fecha!));
  for (final p in pesajes) {
    if (almacen.empleado(p.idTecnico)?.tipo == 'Tecnico') return p.idTecnico;
  }
  return null;
}

Future<void> formularioPesaje(
  BuildContext context, {
  required String plaza,
  required DateTime fecha,
  int? tecnico,
  Pesaje? pesaje,
}) async {
  final almacen = context.read<AlmacenSacor>();
  final usuario = context.read<SesionEstado>().usuario!;
  final contratos = almacen.contratos.where((c) => almacen.precio(c.idPrecioLugar)?.lugar == plaza).toList()
    ..sort((a, b) => (almacen.precio(a.idPrecioLugar)?.tipo ?? '').compareTo(almacen.precio(b.idPrecioLugar)?.tipo ?? ''));

  final tecnicos = _tecnicos(almacen);
  final idTecnico = pesaje?.idTecnico ?? tecnico;
  if (idTecnico != null && !tecnicos.any((t) => t.id == idTecnico)) {
    final actual = almacen.empleado(idTecnico);
    if (actual != null) tecnicos.add(actual);
  }

  final etapas = <String>{
    '4ta Etapa',
    '1ra Etapa',
    for (final p in almacen.pesajes)
      if (p.etapa != null && contratos.any((c) => c.id == p.idContrato)) p.etapa!,
  }.toList();

  final guardado = await mostrarFormulario(
    context,
    titulo: pesaje == null ? 'Agregar pesaje' : 'Editar pesaje',
    subtitulo: plaza,
    iniciales: {
      'contrato': pesaje?.idContrato ?? (contratos.length == 1 ? contratos.first.id : null),
      'fecha': pesaje?.fecha ?? fecha,
      'libras': pesaje?.libras,
      'etapa': pesaje?.etapa,
      'tecnico': idTecnico,
    },
    campos: [
      CampoOpciones<int>('contrato', 'Tipo de desecho', [
        for (final c in contratos)
          (c.id, '${almacen.precio(c.idPrecioLugar)?.tipo} · ${Formatos.usd(almacen.precio(c.idPrecioLugar)?.precio ?? const Dinero.cero())}/t'),
      ]),
      const CampoFecha('fecha', 'Fecha'),
      const CampoNumero('libras', 'Peso', decimales: 2, minimo: 0.01, maximo: 100000, sufijo: 'lb'),
      CampoTexto('etapa', 'Etapa', obligatorio: false, largo: 60, sugerencias: etapas, ayuda: 'Solo si la plaza se pesa por etapas.'),
      CampoOpciones<int>('tecnico', 'Técnico responsable', [for (final t in tecnicos) (t.id, '${t.nombre} (${t.tipoVisible})')],
          ancho: Ancho.completo),
    ],
    alGuardar: (v) async {
      final contrato = almacen.contrato(v['contrato']! as int)!;
      final datos = {
        'idServicioContrato': contrato.id,
        'idEmpleadoSubio': pesaje?.idEmpleadoSubio ?? usuario.id,
        'idTecnicoTransporte': v['tecnico'],
        'idPrecioLugar': contrato.idPrecioLugar,
        'fecha': fechaJson(v['fecha']! as DateTime),
        'pesoTotal': v['libras'],
        'etapa': v['etapa'],
      };
      if (pesaje == null) {
        await almacen.crear(Recurso.pesajes, {...datos, 'precioTonelada': almacen.precio(contrato.idPrecioLugar)?.precio.toJson()},
            detalle: 'Pesaje registrado');
      } else {
        final mismoPrecio = pesaje.idPrecioLugar == contrato.idPrecioLugar && pesaje.precioTonelada != null;
        await almacen.actualizar(
          Recurso.pesajes,
          pesaje,
          pesaje.con({
            ...datos,
            'precioTonelada': mismoPrecio
                ? pesaje.precioTonelada!.toJson()
                : almacen.precio(contrato.idPrecioLugar)?.precio.toJson(),
          }),
          detalle: 'Pesaje editado',
        );
      }
    },
  );
  if (guardado && context.mounted) notificar(context, pesaje == null ? 'Pesaje registrado.' : 'Pesaje actualizado.');
}

class _SelectorMes extends StatelessWidget {
  const _SelectorMes({required this.mes, required this.alCambiar});

  final DateTime mes;
  final ValueChanged<DateTime> alCambiar;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Mes anterior',
          onPressed: () => alCambiar(DateTime(mes.year, mes.month - 1)),
          icon: const Icon(Icons.chevron_left),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            final elegido = await elegirMes(context, mes);
            if (elegido != null) alCambiar(elegido);
          },
          icon: const Icon(Icons.calendar_month_outlined, size: 18),
          label: Text(Formatos.mesLargo(mes.year, mes.month)),
        ),
        IconButton(
          tooltip: 'Mes siguiente',
          onPressed: () => alCambiar(DateTime(mes.year, mes.month + 1)),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _CuadroPesaje extends StatelessWidget {
  const _CuadroPesaje({required this.planilla, required this.alTocarDia});

  final PlanillaPesaje planilla;
  final void Function(FilaPlanilla fila) alTocarDia;

  @override
  Widget build(BuildContext context) {
    final columnas = <ColumnaTabla<FilaPlanilla>>[
      ColumnaTabla(
        titulo: 'Fecha',
        anchoMinimo: 100,
        celda: (f) => Text(DateFormat('EEE dd/MM', 'es').format(f.dia)),
      ),
    ];
    final pie = <Widget>[const Text('TOTAL')];

    for (var i = 0; i < planilla.columnas.length; i++) {
      final columna = planilla.columnas[i];
      final precio = columna.precio == null ? '' : ' ${Formatos.usd(columna.precio!.precio)}/t';
      for (final etapa in columna.etapas) {
        columnas.add(ColumnaTabla(
          titulo: '${columna.tipo} $etapa',
          numerica: true,
          anchoMinimo: 100,
          celda: (f) => Text(formatoLibras(f.celdas[i].librasPorEtapa[etapa] ?? 0)),
        ));
        pie.add(Text(formatoLibras(planilla.totales[i].librasPorEtapa[etapa] ?? 0)));
      }
      columnas.addAll([
        ColumnaTabla(
          titulo: '${columna.tipo} lb',
          numerica: true,
          anchoMinimo: 96,
          celda: (f) => Text(formatoLibras(f.celdas[i].libras)),
        ),
        ColumnaTabla(
          titulo: 'Toneladas',
          numerica: true,
          anchoMinimo: 84,
          celda: (f) => Text(formatoToneladas(f.celdas[i].toneladas)),
        ),
        ColumnaTabla(
          titulo: 'Total$precio',
          numerica: true,
          anchoMinimo: 110,
          celda: (f) => Text(formatoVenta(f.celdas[i].venta)),
        ),
      ]);
      pie.addAll([
        Text(formatoLibras(planilla.totales[i].libras)),
        Text(formatoToneladas(planilla.totales[i].toneladas)),
        Text(formatoVenta(planilla.totales[i].venta)),
      ]);
    }

    columnas.add(ColumnaTabla(
      titulo: 'Total del día',
      numerica: true,
      anchoMinimo: 120,
      celda: (f) => Text(formatoVenta(f.venta), style: const TextStyle(fontWeight: FontWeight.w600)),
    ));
    pie.add(Text(formatoVenta(planilla.venta)));

    return TablaDatos<FilaPlanilla>(columnas: columnas, filas: planilla.filas, alTocar: alTocarDia, pie: pie);
  }
}

class _DialogoDia extends StatelessWidget {
  const _DialogoDia({required this.plaza, required this.dia, required this.tecnico, this.soloTecnico});

  final String plaza;
  final DateTime dia;
  final int? tecnico;
  final int? soloTecnico;

  @override
  Widget build(BuildContext context) {
    final almacen = context.watch<AlmacenSacor>();
    final contratos = {
      for (final c in almacen.contratos)
        if (almacen.precio(c.idPrecioLugar)?.lugar == plaza) c.id: c,
    };
    final pesajes = almacen.pesajes
        .where((p) => contratos.containsKey(p.idContrato) && p.fecha == dia)
        .where((p) => soloTecnico == null || p.idTecnico == soloTecnico)
        .toList()
      ..sort((a, b) => (almacen.precio(a.idPrecioLugar)?.tipo ?? '').compareTo(almacen.precio(b.idPrecioLugar)?.tipo ?? ''));
    final venta = pesajes.fold<double>(0, (t, p) => t + ventaPesaje(p, almacen.precio(p.idPrecioLugar)));

    return DialogoFormulario(
      titulo: 'Pesajes del ${Formatos.fecha(dia)}',
      subtitulo: '$plaza · ${pesajes.length} pesaje(s) · ${Formatos.usd(aDinero(venta))}',
      ancho: 860,
      contenido: TablaDatos<Pesaje>(
        filas: pesajes,
        mensajeVacio: 'No hay pesajes este día.',
        columnas: [
          ColumnaTabla(titulo: 'Tipo', celda: (p) => Text(almacen.precio(p.idPrecioLugar)?.tipo ?? '—')),
          ColumnaTabla(titulo: 'Etapa', celda: (p) => Text(p.etapa ?? '—')),
          ColumnaTabla(titulo: 'Libras', numerica: true, celda: (p) => Text(_libras.format(p.libras))),
          ColumnaTabla(titulo: 'Toneladas', numerica: true, celda: (p) => Text(_toneladas.format(toneladas(p.libras)))),
          ColumnaTabla(
            titulo: 'Venta',
            numerica: true,
            celda: (p) => Text(Formatos.usd(aDinero(ventaPesaje(p, almacen.precio(p.idPrecioLugar))))),
          ),
          ColumnaTabla(titulo: 'Técnico', flex: 3, celda: (p) => Text(almacen.nombreEmpleado(p.idTecnico))),
          ColumnaTabla(
            titulo: '',
            anchoMinimo: 96,
            celda: (p) => AccionesFila(
              alEditar: () => formularioPesaje(context, plaza: plaza, fecha: dia, pesaje: p),
              alEliminar: () => eliminarConConfirmacion(
                context,
                que: 'el pesaje de ${_libras.format(p.libras)} lb',
                eliminar: () => almacen.eliminar(Recurso.pesajes, p, detalle: 'Pesaje eliminado'),
              ),
            ),
          ),
        ],
      ),
      acciones: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
        FilledButton.icon(
          onPressed: () => formularioPesaje(context, plaza: plaza, fecha: dia, tecnico: tecnico),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Agregar pesaje'),
        ),
      ],
    );
  }
}

class _ResumenPlazas extends StatelessWidget {
  const _ResumenPlazas({required this.mes, required this.plazas});

  final DateTime mes;
  final List<String> plazas;

  @override
  Widget build(BuildContext context) {
    final almacen = context.watch<AlmacenSacor>();
    final planillas = [
      for (final p in plazas)
        PlanillaPesaje.armar(
            lugar: p, mes: mes, contratos: almacen.contratos, precio: almacen.precio, pesajes: almacen.pesajes),
    ];
    final tipos = {for (final p in planillas) ...p.columnas.map((c) => c.tipo)}.toList()..sort();
    double toneladasDe(PlanillaPesaje p, String tipo) {
      var total = 0.0;
      for (var i = 0; i < p.columnas.length; i++) {
        if (p.columnas[i].tipo == tipo) total += p.totales[i].toneladas;
      }
      return total;
    }

    final venta = planillas.fold<double>(0, (t, p) => t + p.venta);

    return Tarjeta(
      titulo: 'Todas las plazas · ${Formatos.mesLargo(mes.year, mes.month)}',
      child: TablaDatos<PlanillaPesaje>(
        filas: planillas,
        columnas: [
          ColumnaTabla(titulo: 'Plaza', flex: 3, celda: (p) => Text(p.lugar)),
          for (final tipo in tipos)
            ColumnaTabla(titulo: '$tipo (t)', numerica: true, celda: (p) => Text(formatoToneladas(toneladasDe(p, tipo)))),
          ColumnaTabla(titulo: 'Venta', numerica: true, celda: (p) => Text(formatoVenta(p.venta))),
          ColumnaTabla(titulo: 'IVA 13 %', numerica: true, celda: (p) => Text(formatoVenta(p.iva))),
          ColumnaTabla(
            titulo: 'Total con IVA',
            numerica: true,
            celda: (p) => Text(formatoVenta(p.venta + p.iva), style: const TextStyle(color: ColoresSacor.verdeOscuro)),
          ),
        ],
        pie: [
          const Text('TOTAL'),
          for (final tipo in tipos)
            Text(formatoToneladas(planillas.fold<double>(0, (t, p) => t + toneladasDe(p, tipo)))),
          Text(formatoVenta(venta)),
          Text(formatoVenta(venta * tasaIva)),
          Text(formatoVenta(venta * (1 + tasaIva))),
        ],
      ),
    );
  }
}
