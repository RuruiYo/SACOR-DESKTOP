import 'documento_dte.dart';

const carpetaDteDisponible = false;

Future<String> carpetaDtePorDefecto() async => r'Documentos\SACOR\DTE';

Future<String?> carpetaDteElegida() async => null;

Future<void> guardarCarpetaDte(String? ruta) async {}

Future<List<DocumentoDte>> leerCarpetaDte(String ruta) async => const [];

Future<void> abrirCarpeta(String ruta) async {}
