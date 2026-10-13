import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../calculos/contabilidad.dart';
import '../../nucleo/colores.dart';
import '../../nucleo/dinero.dart';
import '../../nucleo/formatos.dart';
import '../comunes/tabla.dart';
import '../comunes/tarjeta.dart';

class _Serie {
  const _Serie(this.nombre, this.color, this.valor);

  final String nombre;
  final Color color;
  final Dinero Function(PuntoMensual punto) valor;
}

const _series = [
  _Serie('Ventas', ColoresSacor.serieVentas, _ventas),
  _Serie('Gastos', ColoresSacor.serieGastos, _gastos),
];

Dinero _ventas(PuntoMensual p) => aDinero(p.ventas);
Dinero _gastos(PuntoMensual p) => aDinero(p.gastos);

class TarjetaEvolucion extends StatefulWidget {
  const TarjetaEvolucion({super.key, required this.serie, this.alto = 280, this.expandir = false});

  final List<PuntoMensual> serie;

  final double alto;

  final bool expandir;

  @override
  State<TarjetaEvolucion> createState() => _TarjetaEvolucionState();
}

class _TarjetaEvolucionState extends State<TarjetaEvolucion> {
  bool _comoTabla = false;

  @override
  Widget build(BuildContext context) {
    final ultimo = widget.serie.isEmpty ? null : widget.serie.last;

    final area = _comoTabla
        ? SingleChildScrollView(child: _TablaSerie(serie: widget.serie))
        : _Grafico(serie: widget.serie);

    return Tarjeta(
      titulo: 'Ventas y gastos por mes',
      subtitulo: 'Últimos 12 meses hasta el final del período elegido.',
      expandir: widget.expandir,
      acciones: [
        IconButton(
          tooltip: _comoTabla ? 'Ver como gráfico' : 'Ver como tabla',
          onPressed: () => setState(() => _comoTabla = !_comoTabla),
          icon: Icon(_comoTabla ? Icons.show_chart : Icons.table_rows_outlined),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: widget.expandir ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              for (final serie in _series)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 16, height: 3, decoration: BoxDecoration(color: serie.color, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    Text(serie.nombre, style: Estilos.etiqueta),
                    if (ultimo != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        Formatos.usd(serie.valor(ultimo)),
                        style: Estilos.etiqueta.copyWith(fontWeight: FontWeight.w600, color: ColoresSacor.texto),
                      ),
                    ],
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.expandir) Expanded(child: area) else SizedBox(height: widget.alto, child: area),
        ],
      ),
    );
  }
}

class _Grafico extends StatelessWidget {
  const _Grafico({required this.serie});

  final List<PuntoMensual> serie;

  static double intervaloAgradable(double maximo) {
    if (maximo <= 0) return 100;
    final crudo = maximo / 4;
    final magnitud = pow(10, (log(crudo) / ln10).floor()).toDouble();
    final normalizado = crudo / magnitud;
    final paso = normalizado <= 1
        ? 1.0
        : normalizado <= 2
            ? 2.0
            : normalizado <= 2.5
                ? 2.5
                : normalizado <= 5
                    ? 5.0
                    : 10.0;
    return paso * magnitud;
  }

  @override
  Widget build(BuildContext context) {
    if (serie.isEmpty) {
      return const Center(child: Text('Sin datos para graficar.', style: Estilos.secundario));
    }

    final maximo = serie
        .expand((p) => _series.map((s) => s.valor(p).comoDouble))
        .fold<double>(0, max);
    final intervalo = intervaloAgradable(maximo);
    final techo = max(intervalo, (maximo / intervalo).ceil() * intervalo);

    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 6),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (serie.length - 1).toDouble(),
          minY: 0,
          maxY: techo,
          clipData: const FlClipData.all(),
          borderData: FlBorderData(
            show: true,
            border: const Border(bottom: BorderSide(color: ColoresSacor.bordeFuerte)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: intervalo,
            getDrawingHorizontalLine: (_) => const FlLine(color: ColoresSacor.grilla, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                interval: intervalo,
                getTitlesWidget: (valor, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(
                    Formatos.usdCompacto(valor),
                    style: const TextStyle(fontSize: 11.5, color: ColoresSacor.ejeTexto),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (valor, meta) {
                  final indice = valor.round();
                  if (indice != valor || indice < 0 || indice >= serie.length) return const SizedBox.shrink();
                  final punto = serie[indice];
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      Formatos.mesCorto(punto.anio, punto.mes),
                      style: const TextStyle(fontSize: 11.5, color: ColoresSacor.ejeTexto),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            for (final s in _series)
              LineChartBarData(
                spots: [
                  for (var i = 0; i < serie.length; i++) FlSpot(i.toDouble(), s.valor(serie[i]).comoDouble),
                ],
                color: s.color,
                barWidth: 2,
                isCurved: false,
                isStrokeCapRound: true,
                isStrokeJoinRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, porcentaje, barra, indice) => FlDotCirclePainter(
                    radius: 4,
                    color: s.color,
                    strokeWidth: 2,
                    strokeColor: ColoresSacor.blanco,
                  ),
                ),
              ),
          ],
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            getTouchedSpotIndicator: (barra, indices) => [
              for (final _ in indices)
                TouchedSpotIndicatorData(
                  const FlLine(color: ColoresSacor.bordeFuerte, strokeWidth: 1),
                  FlDotData(
                    getDotPainter: (spot, porcentaje, barra, indice) => FlDotCirclePainter(
                      radius: 5,
                      color: barra.color ?? ColoresSacor.texto,
                      strokeWidth: 2,
                      strokeColor: ColoresSacor.blanco,
                    ),
                  ),
                ),
            ],
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => ColoresSacor.blanco,
              tooltipBorder: const BorderSide(color: ColoresSacor.borde),
              tooltipBorderRadius: BorderRadius.circular(8),
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              maxContentWidth: 240,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItems: (puntos) {
                final ordenados = [...puntos]..sort((a, b) => a.barIndex.compareTo(b.barIndex));
                return [
                  for (var i = 0; i < ordenados.length; i++)
                    () {
                      final punto = serie[ordenados[i].spotIndex];
                      final s = _series[ordenados[i].barIndex];
                      final valor = Formatos.usd(s.valor(punto));
                      return LineTooltipItem(
                        i == 0 ? '${Formatos.mesLargo(punto.anio, punto.mes)}\n' : '',
                        const TextStyle(fontSize: 12, color: ColoresSacor.textoSecundario, height: 1.6),
                        textAlign: TextAlign.left,
                        children: [
                          TextSpan(text: '━ ', style: TextStyle(color: s.color, fontWeight: FontWeight.w900)),
                          TextSpan(
                            text: valor,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ColoresSacor.texto),
                          ),
                          TextSpan(
                            text: '  ${s.nombre}',
                            style: const TextStyle(fontSize: 12, color: ColoresSacor.textoSecundario),
                          ),
                        ],
                      );
                    }(),
                ];
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TablaSerie extends StatelessWidget {
  const _TablaSerie({required this.serie});

  final List<PuntoMensual> serie;

  @override
  Widget build(BuildContext context) {
    return TablaDatos<PuntoMensual>(
      filas: serie.reversed.toList(),
      columnas: [
        ColumnaTabla(titulo: 'Mes', celda: (p) => Text(Formatos.mesLargo(p.anio, p.mes)), flex: 3),
        for (final s in _series)
          ColumnaTabla(titulo: s.nombre, numerica: true, celda: (p) => Text(Formatos.usd(s.valor(p)))),
        ColumnaTabla(
          titulo: 'Ganancia',
          numerica: true,
          celda: (p) => Text(Formatos.usdConSigno(aDinero(p.ganancia))),
        ),
      ],
    );
  }
}
