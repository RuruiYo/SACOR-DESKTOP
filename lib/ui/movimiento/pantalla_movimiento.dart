import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../calculos/contabilidad.dart';
import '../../configuracion/configuracion.dart';
import '../../estado/almacen.dart';
import '../../estado/periodo_estado.dart';
import '../../exportacion/tabla_reporte.dart';
import '../../nucleo/colores.dart';
import '../../nucleo/formatos.dart';
import '../../nucleo/periodo.dart';
import '../../nucleo/variacion.dart';
import '../comunes/boton_exportar.dart';
import '../comunes/insignia.dart';
import '../comunes/tabla.dart';
import '../comunes/tarjeta.dart';
import '../comunes/tarjeta_indicador.dart';
import 'grafico_mensual.dart';

class PantallaMovimiento extends StatelessWidget {
  const PantallaMovimiento({super.key});

  @override
  Widget build(BuildContext context) {
    final almacen = context.watch<AlmacenSacor>();
    final periodo = context.watch<PeriodoEstado>().periodo;
    final contabilidad = Contabilidad.desde(almacen);
    final resumen = contabilidad.resumen(periodo);
    final serie = contabilidad.serieMensual(periodo.hasta);

    final margen = resumen.ventas == 0 ? null : resumen.ganancia / resumen.ventas * 100;
    final toneladasPeriodo = resumen.ventasPorPlaza.fold<double>(0, (t, p) => t + p.toneladasTotal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(builder: (context, restricciones) {
          final tarjetas = [
            TarjetaIndicador(
              etiqueta: 'Ventas',
              valor: Formatos.usd(aDinero(resumen.ventas)),
              icono: Icons.trending_up,
              variacion: Variacion.calcular(resumen.ventas, resumen.ventasAnterior),
              nota: 'Anterior: ${Formatos.usd(aDinero(resumen.ventasAnterior))}',
            ),
            TarjetaIndicador(
              etiqueta: 'Gastos',
              valor: Formatos.usd(aDinero(resumen.gastos)),
              icono: Icons.receipt_long_outlined,
              subirEsBueno: false,
              variacion: Variacion.calcular(resumen.gastos, resumen.gastosAnterior),
              nota: 'Anterior: ${Formatos.usd(aDinero(resumen.gastosAnterior))}',
            ),
            TarjetaIndicador(
              etiqueta: 'Ganancia',
              valor: Formatos.usdConSigno(aDinero(resumen.ganancia)),
              icono: Icons.account_balance_wallet_outlined,
              colorValor: resumen.ganancia < 0 ? ColoresSacor.rojoTexto : null,
              variacion: Variacion.calcular(resumen.ganancia, resumen.gananciaAnterior),
              nota: 'Anterior: ${Formatos.usdConSigno(aDinero(resumen.gananciaAnterior))}',
            ),
            TarjetaIndicador(
              etiqueta: 'Margen de ganancia',
              valor: margen == null ? '—' : Formatos.porcentaje(margen),
              icono: Icons.percent,
              nota: '${Formatos.decimal(toneladasPeriodo)} toneladas recolectadas',
            ),
          ];
          final columnas = restricciones.maxWidth >= 1100 ? 4 : 2;
          final ancho = (restricciones.maxWidth - 16 * (columnas - 1)) / columnas;
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [for (final t in tarjetas) SizedBox(width: ancho, child: t)],
          );
        }),
        const SizedBox(height: 16),
        Tarjeta(
          child: Row(
            children: [
              Expanded(
                child: Wrap(spacing: 28, runSpacing: 8, children: [
                  _Cifra('IVA 13 % sobre ventas', Formatos.usd(aDinero(resumen.iva))),
                  _Cifra('Ventas con IVA', Formatos.usd(aDinero(resumen.ventas + resumen.iva))),
                  _Cifra('Pago a cuenta 1.75 %', Formatos.usd(aDinero(resumen.pagoCuenta))),
                  _Cifra('Período comparado', periodo.rangoAnterior),
                ]),
              ),
              BotonExportar(generar: () => _reporte(context, periodo, resumen, serie)),
            ],
          ),
        ),
        if (resumen.haySinFecha) ...[
          const SizedBox(height: 12),
          Aviso(
            tono: TonoInsignia.alerta,
            titulo: 'Registros sin fecha (no entran en ningún período)',
            mensaje: [
              if (resumen.externosSinFecha.cantidad > 0)
                '${resumen.externosSinFecha.cantidad} servicio(s) externo(s) por '
                    '${Formatos.usd(aDinero(resumen.externosSinFecha.monto))}',
              if (resumen.rutasSinFecha.cantidad > 0)
                '${resumen.rutasSinFecha.cantidad} salida(s) con gasolina por '
                    '${Formatos.usd(aDinero(resumen.rutasSinFecha.monto))}',
              if (resumen.viajesSinFecha.cantidad > 0)
                '${resumen.viajesSinFecha.cantidad} viaje(s) extra por '
                    '${Formatos.usd(aDinero(resumen.viajesSinFecha.monto))}',
            ].join(' · '),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(height: 400, child: TarjetaEvolucion(serie: serie, expandir: true)),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, restricciones) {
          final ventas = _VentasPorPlaza(resumen: resumen);
          final gastos = _GastosPorCategoria(resumen: resumen);
          if (restricciones.maxWidth < 1100) {
            return Column(children: [ventas, const SizedBox(height: 16), gastos]);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: ventas),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: gastos),
            ],
          );
        }),
      ],
    );
  }

  TablaReporte _reporte(BuildContext context, Periodo periodo, ResumenPeriodo resumen, List<PuntoMensual> serie) =>
      TablaReporte(
        titulo: 'Movimiento contable',
        subtitulo: 'Período: ${periodo.rango} · comparado con ${periodo.rangoAnterior}',
        esDemo: context.read<Configuracion>().modoDemo,
        columnas: const [
          ColumnaReporte('Concepto', TipoColumna.texto, flex: 4),
          ColumnaReporte('Período', TipoColumna.dinero),
          ColumnaReporte('Período anterior', TipoColumna.dinero),
          ColumnaReporte('Variación', TipoColumna.texto),
        ],
        filas: [
          ['Ventas', aDinero(resumen.ventas), aDinero(resumen.ventasAnterior),
            Variacion.calcular(resumen.ventas, resumen.ventasAnterior).corta],
          for (final p in resumen.ventasPorPlaza) ['   Pesaje · ${p.lugar}', aDinero(p.venta), null, null],
          ['   Viajes extra', aDinero(resumen.ventaViajes), null, null],
          ['Gastos', aDinero(resumen.gastos), aDinero(resumen.gastosAnterior),
            Variacion.calcular(resumen.gastos, resumen.gastosAnterior).corta],
          for (final c in CategoriaGasto.values) ['   ${c.nombre}', aDinero(resumen.gastosPorCategoria[c]!), null, null],
          ['Ganancia', aDinero(resumen.ganancia), aDinero(resumen.gananciaAnterior),
            Variacion.calcular(resumen.ganancia, resumen.gananciaAnterior).corta],
          ['IVA 13 % sobre ventas', aDinero(resumen.iva), null, null],
          ['Pago a cuenta 1.75 %', aDinero(resumen.pagoCuenta), null, null],
        ],
        notas: [
          'Ventas = pesajes (libras ÷ 2200 × precio por tonelada) + viajes extra (precio × cantidad).',
          'Gastos = pagos (cantidad − descuento) + anticipos + servicios externos + gasolina de las salidas.',
          'Meses: ${serie.map((p) => '${Formatos.mesCorto(p.anio, p.mes)} ${Formatos.usd(aDinero(p.ventas))}').join(', ')}',
        ],
      );
}

class _Cifra extends StatelessWidget {
  const _Cifra(this.etiqueta, this.valor);

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(etiqueta, style: Estilos.tenue),
          const SizedBox(height: 2),
          Text(valor, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ColoresSacor.texto)),
        ],
      );
}

class _VentasPorPlaza extends StatelessWidget {
  const _VentasPorPlaza({required this.resumen});

  final ResumenPeriodo resumen;

  @override
  Widget build(BuildContext context) {
    final tipos = {for (final p in resumen.ventasPorPlaza) ...p.toneladasPorTipo.keys}.toList()..sort();
    final filas = [
      ...resumen.ventasPorPlaza.map((p) => (p.lugar, p.toneladasPorTipo, p.venta)),
      if (resumen.ventaViajes > 0) (Contabilidad.grupoViajes, const <String, double>{}, resumen.ventaViajes),
    ];

    return Tarjeta(
      titulo: 'Ventas por plaza',
      subtitulo: 'Pesajes del período al precio con que se registraron, más viajes extra.',
      child: TablaDatos<(String, Map<String, double>, double)>(
        filas: filas,
        mensajeVacio: 'Sin ventas en el período.',
        columnas: [
          ColumnaTabla(titulo: 'Plaza', flex: 3, celda: (f) => Text(f.$1)),
          for (final tipo in tipos)
            ColumnaTabla(
              titulo: '$tipo (t)',
              numerica: true,
              celda: (f) => Text(f.$2[tipo] == null ? '—' : Formatos.decimal(f.$2[tipo]!)),
            ),
          ColumnaTabla(titulo: 'Venta', numerica: true, celda: (f) => Text(Formatos.usd(aDinero(f.$3)))),
          ColumnaTabla(
            titulo: '% de ventas',
            numerica: true,
            celda: (f) => Text(resumen.ventas == 0 ? '—' : Formatos.porcentaje(f.$3 / resumen.ventas * 100)),
          ),
        ],
        pie: [
          const Text('TOTAL'),
          for (final tipo in tipos)
            Text(Formatos.decimal(resumen.ventasPorPlaza.fold<double>(0, (t, p) => t + (p.toneladasPorTipo[tipo] ?? 0)))),
          Text(Formatos.usd(aDinero(resumen.ventas))),
          const Text(''),
        ],
      ),
    );
  }
}

class _GastosPorCategoria extends StatelessWidget {
  const _GastosPorCategoria({required this.resumen});

  final ResumenPeriodo resumen;

  @override
  Widget build(BuildContext context) {
    final total = resumen.gastos;
    return Tarjeta(
      titulo: 'Gastos por categoría',
      subtitulo: 'Total: ${Formatos.usd(aDinero(total))}',
      child: Column(
        children: [
          for (final categoria in CategoriaGasto.values) ...[
            _BarraCategoria(
              nombre: categoria.nombre,
              monto: resumen.gastosPorCategoria[categoria]!,
              total: total,
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _BarraCategoria extends StatelessWidget {
  const _BarraCategoria({required this.nombre, required this.monto, required this.total});

  final String nombre;
  final double monto;
  final double total;

  @override
  Widget build(BuildContext context) {
    final proporcion = total == 0 ? 0.0 : (monto / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(nombre, style: Estilos.cuerpo)),
            Text(Formatos.usd(aDinero(monto)), style: Estilos.cifraTabla.copyWith(fontWeight: FontWeight.w600)),
            SizedBox(
              width: 64,
              child: Text(Formatos.porcentaje(proporcion * 100), textAlign: TextAlign.right, style: Estilos.tenue),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: proporcion,
            minHeight: 8,
            color: ColoresSacor.serieGastos,
            backgroundColor: ColoresSacor.fondo,
          ),
        ),
      ],
    );
  }
}
