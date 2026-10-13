import '../datos/modelos/entidades.dart';
import '../estado/almacen.dart';
import '../nucleo/dinero.dart';
import '../nucleo/periodo.dart';

const librasPorTonelada = 2200.0;

const tasaIva = 0.13;
const tasaPagoCuenta = 0.0175;

double toneladas(double libras) => libras / librasPorTonelada;

double ventaPesaje(Pesaje pesaje, PrecioLugar? precio) =>
    toneladas(pesaje.libras) * (pesaje.precioTonelada ?? precio?.precio ?? const Dinero.cero()).comoDouble;

enum CategoriaGasto {
  pagos('Pagos a empleados'),
  anticipos('Anticipos'),
  serviciosExternos('Servicios externos'),
  gasolina('Gasolina'),
  viajes('Gastos de viajes');

  const CategoriaGasto(this.nombre);

  final String nombre;
}

class Movimiento {
  const Movimiento(this.fecha, this.monto, this.grupo);

  final DateTime? fecha;
  final double monto;

  final String grupo;
}

class VentaPlaza {
  VentaPlaza(this.lugar);

  final String lugar;
  final Map<String, double> toneladasPorTipo = {};
  double venta = 0;

  double get toneladasTotal => toneladasPorTipo.values.fold(0, (a, b) => a + b);
}

class SinFecha {
  const SinFecha(this.cantidad, this.monto);

  final int cantidad;
  final double monto;
}

class ResumenPeriodo {
  const ResumenPeriodo({
    required this.ventas,
    required this.gastos,
    required this.ventasAnterior,
    required this.gastosAnterior,
    required this.gastosPorCategoria,
    required this.ventasPorPlaza,
    required this.ventaViajes,
    required this.viajesSinFecha,
    required this.externosSinFecha,
    required this.rutasSinFecha,
  });

  final double ventas;
  final double gastos;
  final double ventasAnterior;
  final double gastosAnterior;
  final Map<CategoriaGasto, double> gastosPorCategoria;
  final List<VentaPlaza> ventasPorPlaza;
  final double ventaViajes;
  final SinFecha viajesSinFecha;
  final SinFecha externosSinFecha;
  final SinFecha rutasSinFecha;

  double get ganancia => ventas - gastos;
  double get gananciaAnterior => ventasAnterior - gastosAnterior;
  double get iva => ventas * tasaIva;
  double get pagoCuenta => ventas * tasaPagoCuenta;

  bool get haySinFecha => viajesSinFecha.cantidad + externosSinFecha.cantidad + rutasSinFecha.cantidad > 0;
}

class PuntoMensual {
  const PuntoMensual(this.anio, this.mes, this.ventas, this.gastos);

  final int anio;
  final int mes;
  final double ventas;
  final double gastos;

  double get ganancia => ventas - gastos;
}

class Contabilidad {
  Contabilidad({
    required List<Pesaje> pesajes,
    required PrecioLugar? Function(int id) precio,
    required List<ViajeExtra> viajes,
    required List<Pago> pagos,
    required List<Anticipo> anticipos,
    required List<ServicioExterno> serviciosExternos,
    required List<Ruta> rutas,
    List<GastoViaje> gastosViaje = const [],
  }) {
    for (final p in pesajes) {
      final precioLugar = precio(p.idPrecioLugar);
      ventas.add(Movimiento(p.fecha, ventaPesaje(p, precioLugar), precioLugar?.lugar ?? 'Sin precio'));
      _pesajes.add((p, precioLugar));
    }
    for (final v in viajes) {
      ventas.add(Movimiento(v.fecha, v.total.comoDouble, grupoViajes));
    }
    for (final p in pagos) {
      gastos.add(Movimiento(p.fecha, p.neto.comoDouble, CategoriaGasto.pagos.name));
    }
    for (final a in anticipos) {
      gastos.add(Movimiento(a.fecha, a.cantidad.comoDouble, CategoriaGasto.anticipos.name));
    }
    for (final s in serviciosExternos) {
      gastos.add(Movimiento(s.fecha, s.monto.comoDouble, CategoriaGasto.serviciosExternos.name));
    }
    for (final r in rutas) {
      if (r.gasolina.esCero) continue;
      gastos.add(Movimiento(r.fecha, r.gasolina.comoDouble, CategoriaGasto.gasolina.name));
    }
    for (final g in gastosViaje) {
      gastos.add(Movimiento(g.fecha, g.monto.comoDouble, CategoriaGasto.viajes.name));
    }
  }

  factory Contabilidad.desde(AlmacenSacor almacen) => Contabilidad(
        pesajes: almacen.pesajes,
        precio: almacen.precio,
        viajes: almacen.viajesExtra,
        pagos: almacen.pagos,
        anticipos: almacen.anticipos,
        serviciosExternos: almacen.serviciosExternos,
        rutas: almacen.rutas,
        gastosViaje: almacen.gastosViaje,
      );

  static const grupoViajes = 'Viajes extra';

  final List<Movimiento> ventas = [];
  final List<Movimiento> gastos = [];
  final List<(Pesaje, PrecioLugar?)> _pesajes = [];

  static double _suma(Iterable<Movimiento> movimientos) => movimientos.fold(0, (total, m) => total + m.monto);

  static bool _entre(DateTime? fecha, DateTime desde, DateTime hasta) =>
      fecha != null && !fecha.isBefore(desde) && !fecha.isAfter(hasta);

  ResumenPeriodo resumen(Periodo periodo) {
    bool actual(Movimiento m) => _entre(m.fecha, periodo.desde, periodo.hasta);
    bool anterior(Movimiento m) => _entre(m.fecha, periodo.desdeAnterior, periodo.hastaAnterior);

    final porCategoria = {for (final c in CategoriaGasto.values) c: 0.0};
    for (final g in gastos.where(actual)) {
      final categoria = CategoriaGasto.values.byName(g.grupo);
      porCategoria[categoria] = porCategoria[categoria]! + g.monto;
    }

    final plazas = <String, VentaPlaza>{};
    for (final (pesaje, precio) in _pesajes) {
      if (!_entre(pesaje.fecha, periodo.desde, periodo.hasta)) continue;
      final lugar = precio?.lugar ?? 'Sin precio';
      final plaza = plazas.putIfAbsent(lugar, () => VentaPlaza(lugar));
      final tipo = precio?.tipo ?? 'Sin tipo';
      plaza.toneladasPorTipo[tipo] = (plaza.toneladasPorTipo[tipo] ?? 0) + toneladas(pesaje.libras);
      plaza.venta += ventaPesaje(pesaje, precio);
    }

    SinFecha sinFecha(Iterable<Movimiento> lista) {
      final sinFecha = lista.where((m) => m.fecha == null).toList();
      return SinFecha(sinFecha.length, _suma(sinFecha));
    }

    return ResumenPeriodo(
      ventas: _suma(ventas.where(actual)),
      gastos: _suma(gastos.where(actual)),
      ventasAnterior: _suma(ventas.where(anterior)),
      gastosAnterior: _suma(gastos.where(anterior)),
      gastosPorCategoria: porCategoria,
      ventasPorPlaza: plazas.values.toList()..sort((a, b) => b.venta.compareTo(a.venta)),
      ventaViajes: _suma(ventas.where((m) => m.grupo == grupoViajes && actual(m))),
      viajesSinFecha: sinFecha(ventas.where((m) => m.grupo == grupoViajes)),
      externosSinFecha: sinFecha(gastos.where((m) => m.grupo == CategoriaGasto.serviciosExternos.name)),
      rutasSinFecha: sinFecha(gastos.where((m) => m.grupo == CategoriaGasto.gasolina.name)),
    );
  }

  List<PuntoMensual> serieMensual(DateTime hasta, {int meses = 12}) {
    return [
      for (var i = meses - 1; i >= 0; i--)
        () {
          final inicio = DateTime(hasta.year, hasta.month - i, 1);
          final fin = Periodo.ultimoDiaDelMes(inicio);
          bool enMes(Movimiento m) => _entre(m.fecha, inicio, fin);
          return PuntoMensual(inicio.year, inicio.month, _suma(ventas.where(enMes)), _suma(gastos.where(enMes)));
        }(),
    ];
  }
}

Dinero aDinero(double monto) => Dinero.desdeNumero(monto);
