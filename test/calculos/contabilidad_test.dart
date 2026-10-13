import 'package:flutter_test/flutter_test.dart';
import 'package:sacor_desktop/calculos/contabilidad.dart';
import 'package:sacor_desktop/calculos/planilla_pesaje.dart';
import 'package:sacor_desktop/datos/modelos/entidades.dart';
import 'package:sacor_desktop/nucleo/periodo.dart';

PrecioLugar precio(int id, String tipo, String lugar, double valor) =>
    PrecioLugar({'idPrecioLugar': id, 'tipo': tipo, 'lugar': lugar, 'precio': valor});

Contrato contrato(int id, int idPrecio) =>
    Contrato({'idServicioContrato': id, 'idCliente': 1, 'idRutaTrabajo': 1, 'idPrecioLugar': idPrecio});

int _siguiente = 1;
Pesaje pesaje(int contrato, int idPrecio, String fecha, double libras, [String? etapa]) => Pesaje({
      'idPesaje': _siguiente++,
      'idServicioContrato': contrato,
      'idEmpleadoSubio': 1,
      'idTecnicoTransporte': 2,
      'idPrecioLugar': idPrecio,
      'fecha': '${fecha}T00:00:00',
      'pesoTotal': libras,
      'etapa': ?etapa,
    });

void main() {
  final precios = {
    1: precio(1, 'Orgánico', 'Plaza Mundo Apopa', 45.50),
    2: precio(2, 'Sólido', 'Plaza Mundo Apopa', 70.00),
    3: precio(3, 'Orgánico', 'Plaza Mundo Soyapango', 45.50),
    4: precio(4, 'Sólido', 'Plaza Mundo Soyapango', 70.00),
  };

  group('pesaje', () {
    test('toneladas = libras ÷ 2200 y venta = toneladas × precio (fila del 01/08 del Excel)', () {
      final organico = pesaje(1, 1, '2026-08-01', 757.6);
      final solido = pesaje(2, 2, '2026-08-01', 3387.8);

      expect(toneladas(757.6), closeTo(0.344364, 1e-6));
      expect(ventaPesaje(organico, precios[1]), closeTo(15.668545, 1e-6));
      expect(ventaPesaje(solido, precios[2]), closeTo(107.793636, 1e-6));
      expect(aDinero(ventaPesaje(organico, precios[1]) + ventaPesaje(solido, precios[2])).centavos, 12346);
    });

    test('un pesaje sin precio no suma venta', () {
      expect(ventaPesaje(pesaje(1, 99, '2026-08-01', 1000), null), 0);
    });
  });

  group('contabilidad', () {
    final periodo = Periodo.personalizado(DateTime(2026, 8, 1), DateTime(2026, 8, 31));

    Contabilidad armar() => Contabilidad(
          pesajes: [
            pesaje(1, 1, '2026-08-01', 2200),
            pesaje(2, 2, '2026-08-15', 4400),
            pesaje(1, 1, '2026-07-20', 2200),
          ],
          precio: (id) => precios[id],
          viajes: [
            ViajeExtra({'idViajeExtra': 1, 'idCliente': 1, 'idCamion': 1, 'tipo': '[2026-08] Andamios', 'precio': 45, 'cantidad': 2}),
            ViajeExtra({'idViajeExtra': 2, 'idCliente': 1, 'idCamion': 1, 'tipo': 'Sin fecha', 'precio': 50, 'cantidad': 1}),
          ],
          pagos: [
            Pago({'idPago': 1, 'idEmpleado': 1, 'fecha': '2026-08-15T00:00:00', 'cantidad': 300, 'descuento': 40}),
          ],
          anticipos: [
            Anticipo({'idAnticipo': 1, 'idEmpleado': 1, 'fecha': '2026-08-05T00:00:00', 'cantidad': 40}),
          ],
          serviciosExternos: [
            ServicioExterno({'idServicioExt': 1, 'nombre': '[2026-08] Góndola', 'cantidadPago': 735}),
            ServicioExterno({'idServicioExt': 2, 'nombre': 'Báscula', 'cantidadPago': 85}),
          ],
          rutas: [
            Ruta({'idRutaTrabajo': 1, 'destino': '[2026-08-02] Plaza Mundo Apopa', 'dineroGasolina': 25}),
            Ruta({'idRutaTrabajo': 2, 'destino': 'Plaza Mundo Apopa', 'dineroGasolina': 22}),
            Ruta({'idRutaTrabajo': 3, 'destino': '[2026-07-30] Plaza Mundo Apopa', 'dineroGasolina': 30}),
          ],
        );

    test('ventas, gastos, ganancia e impuestos del período', () {
      final r = armar().resumen(periodo);

      expect(r.ventas, closeTo(45.5 + 140 + 90, 1e-9));
      expect(r.gastos, closeTo(260 + 40 + 735 + 25, 1e-9));
      expect(r.ganancia, closeTo(275.5 - 1060, 1e-9));
      expect(r.iva, closeTo(275.5 * 0.13, 1e-9));
      expect(r.pagoCuenta, closeTo(275.5 * 0.0175, 1e-9));
      expect(r.ventaViajes, 90);
      expect(r.gastosPorCategoria[CategoriaGasto.gasolina], 25);
      expect(r.gastosPorCategoria[CategoriaGasto.serviciosExternos], 735);
    });

    test('compara con el período anterior de la misma duración', () {
      final r = armar().resumen(periodo);
      expect(r.ventasAnterior, closeTo(45.5, 1e-9));
      expect(r.gastosAnterior, 30);
    });

    test('lo que no trae fecha se reporta aparte', () {
      final r = armar().resumen(periodo);
      expect(r.viajesSinFecha.cantidad, 1);
      expect(r.viajesSinFecha.monto, 50);
      expect(r.externosSinFecha.monto, 85);
      expect(r.rutasSinFecha.monto, 22);
      expect(r.haySinFecha, isTrue);
    });

    test('ventas por plaza con toneladas por tipo', () {
      final r = armar().resumen(periodo);
      final apopa = r.ventasPorPlaza.single;
      expect(apopa.lugar, 'Plaza Mundo Apopa');
      expect(apopa.toneladasPorTipo, {'Orgánico': 1.0, 'Sólido': 2.0});
      expect(apopa.venta, closeTo(185.5, 1e-9));
    });

    test('serie mensual de 12 meses termina en el mes indicado', () {
      final serie = armar().serieMensual(DateTime(2026, 8, 31));
      expect(serie, hasLength(12));
      expect((serie.last.anio, serie.last.mes), (2026, 8));
      expect((serie.first.anio, serie.first.mes), (2025, 9));
      expect(serie[10].ventas, closeTo(45.5, 1e-9));
    });
  });

  group('planilla de pesaje', () {
    final contratos = [contrato(3, 3), contrato(4, 4), contrato(1, 1)];

    PlanillaPesaje armar(List<Pesaje> pesajes) => PlanillaPesaje.armar(
          lugar: 'Plaza Mundo Soyapango',
          mes: DateTime(2026, 8),
          contratos: contratos,
          precio: (id) => precios[id],
          pesajes: pesajes,
        );

    test('una fila por día y solo los contratos de la plaza, orgánico primero', () {
      final planilla = armar(const []);
      expect(planilla.filas, hasLength(31));
      expect(planilla.columnas.map((c) => c.tipo), ['Orgánico', 'Sólido']);
      expect(planilla.venta, 0);
    });

    test('suma etapas por día (4ta antes que 1ra) y calcula totales como el Excel', () {
      final planilla = armar([
        pesaje(3, 3, '2026-08-01', 1591, '1ra Etapa'),
        pesaje(3, 3, '2026-08-01', 1179.8, '4ta Etapa'),
        pesaje(4, 4, '2026-08-01', 3518, '1ra Etapa'),
        pesaje(1, 1, '2026-08-01', 900),
        pesaje(3, 3, '2026-09-01', 500, '4ta Etapa'),
      ]);

      final organico = planilla.columnas[0];
      expect(organico.etapas, ['4ta Etapa', '1ra Etapa']);
      final dia1 = planilla.filas.first;
      expect(dia1.celdas[0].libras, closeTo(2770.8, 1e-9));
      expect(dia1.celdas[0].librasPorEtapa['4ta Etapa'], closeTo(1179.8, 1e-9));
      expect(dia1.venta, closeTo(169.241545, 1e-6));
      expect(planilla.diasConPesaje, 1);
      expect(planilla.iva, closeTo(169.241545 * 0.13, 1e-6));
    });

    test('plazas con contrato, en orden alfabético', () {
      expect(plazasConContrato(contratos, (id) => precios[id]), ['Plaza Mundo Apopa', 'Plaza Mundo Soyapango']);
    });
  });
}
