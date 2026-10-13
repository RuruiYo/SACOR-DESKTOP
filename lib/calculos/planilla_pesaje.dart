import '../datos/modelos/entidades.dart';
import '../nucleo/periodo.dart';
import 'contabilidad.dart';

class ColumnaPlanilla {
  ColumnaPlanilla(this.contrato, this.precio, this.etapas);

  final Contrato contrato;
  final PrecioLugar? precio;

  final List<String> etapas;

  String get tipo => precio?.tipo ?? 'Contrato #${contrato.id}';
}

class CeldaPlanilla {
  final Map<String, double> librasPorEtapa = {};
  double libras = 0;
  double venta = 0;

  double get toneladas => libras / librasPorTonelada;
}

class FilaPlanilla {
  FilaPlanilla(this.dia, int columnas) : celdas = List.generate(columnas, (_) => CeldaPlanilla());

  final DateTime dia;
  final List<CeldaPlanilla> celdas;
  final List<Pesaje> pesajes = [];

  double get venta => celdas.fold(0, (total, c) => total + c.venta);
  double get libras => celdas.fold(0, (total, c) => total + c.libras);
  bool get vacia => pesajes.isEmpty;
}

class PlanillaPesaje {
  PlanillaPesaje._(this.lugar, this.mes, this.columnas, this.filas, this.totales);

  factory PlanillaPesaje.armar({
    required String lugar,
    required DateTime mes,
    required List<Contrato> contratos,
    required PrecioLugar? Function(int id) precio,
    required List<Pesaje> pesajes,
  }) {
    final inicio = DateTime(mes.year, mes.month, 1);
    final fin = Periodo.ultimoDiaDelMes(inicio);

    final contratosPlaza = contratos.where((c) => precio(c.idPrecioLugar)?.lugar == lugar).toList()
      ..sort((a, b) => (precio(a.idPrecioLugar)?.tipo ?? '').compareTo(precio(b.idPrecioLugar)?.tipo ?? ''));
    final posicion = {for (var i = 0; i < contratosPlaza.length; i++) contratosPlaza[i].id: i};

    final delMes = pesajes.where((p) {
      final fecha = p.fecha;
      return fecha != null && posicion.containsKey(p.idContrato) && !fecha.isBefore(inicio) && !fecha.isAfter(fin);
    }).toList();

    final columnas = [
      for (final c in contratosPlaza)
        ColumnaPlanilla(c, precio(c.idPrecioLugar), _etapas(delMes.where((p) => p.idContrato == c.id))),
    ];

    final filas = [
      for (var d = 1; d <= fin.day; d++) FilaPlanilla(DateTime(inicio.year, inicio.month, d), columnas.length),
    ];
    final totales = List.generate(columnas.length, (_) => CeldaPlanilla());

    for (final p in delMes) {
      final i = posicion[p.idContrato]!;
      final fila = filas[p.fecha!.day - 1];
      final venta = ventaPesaje(p, precio(p.idPrecioLugar));
      fila.pesajes.add(p);
      for (final celda in [fila.celdas[i], totales[i]]) {
        celda.libras += p.libras;
        celda.venta += venta;
        final etapa = p.etapa ?? sinEtapa;
        celda.librasPorEtapa[etapa] = (celda.librasPorEtapa[etapa] ?? 0) + p.libras;
      }
    }

    return PlanillaPesaje._(lugar, inicio, columnas, filas, totales);
  }

  static const sinEtapa = 'Sin etapa';

  final String lugar;
  final DateTime mes;
  final List<ColumnaPlanilla> columnas;
  final List<FilaPlanilla> filas;
  final List<CeldaPlanilla> totales;

  double get venta => totales.fold(0, (total, c) => total + c.venta);
  double get toneladasTotal => totales.fold(0, (total, c) => total + c.toneladas);
  double get iva => venta * tasaIva;
  double get pagoCuenta => venta * tasaPagoCuenta;
  int get diasConPesaje => filas.where((f) => !f.vacia).length;

  static List<String> _etapas(Iterable<Pesaje> pesajes) {
    final etapas = pesajes.map((p) => p.etapa).toSet();
    if (etapas.every((e) => e == null)) return const [];
    final conNombre = etapas.whereType<String>().toList()..sort(_ordenEtapa);
    return [...conNombre, if (etapas.contains(null)) sinEtapa];
  }

  static int _ordenEtapa(String a, String b) {
    int numero(String e) => int.tryParse(RegExp(r'\d+').firstMatch(e)?.group(0) ?? '') ?? -1;
    final na = numero(a), nb = numero(b);
    if (na != nb) return nb.compareTo(na);
    return a.compareTo(b);
  }
}

List<String> plazasConContrato(List<Contrato> contratos, PrecioLugar? Function(int id) precio) {
  final lugares = {for (final c in contratos) precio(c.idPrecioLugar)?.lugar}.whereType<String>().toList()..sort();
  return lugares;
}
