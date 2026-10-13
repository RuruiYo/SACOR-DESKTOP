import '../../nucleo/dinero.dart';
import '../../nucleo/formatos.dart';

typedef Json = Map<String, dynamic>;

int leerEntero(Object? valor) => valor is num ? valor.toInt() : 0;

int? leerEnteroOpcional(Object? valor) => valor is num ? valor.toInt() : null;

String leerTexto(Object? valor) => valor is String ? valor : '';

String? leerTextoOpcional(Object? valor) => valor is String && valor.trim().isNotEmpty ? valor : null;

Dinero leerDinero(Object? valor) => Dinero.desdeJson(valor);

Dinero? leerDineroOpcional(Object? valor) => Dinero.desdeJsonOpcional(valor);

double leerDecimal(Object? valor) => valor is num ? valor.toDouble() : 0;

double? leerDecimalOpcional(Object? valor) => valor is num ? valor.toDouble() : null;

DateTime? leerFecha(Object? valor) {
  if (valor is! String || valor.isEmpty) return null;
  final fecha = DateTime.tryParse(valor);
  return fecha == null ? null : DateTime(fecha.year, fecha.month, fecha.day);
}

String fechaJson(DateTime fecha) => '${Formatos.fechaIso(fecha)}T00:00:00';
