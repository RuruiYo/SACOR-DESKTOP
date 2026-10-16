import 'archivo_configuracion.dart';

class Configuracion {
  const Configuracion({
    required this.urlApi,
    required this.llaveApi,
    required this.modoDemo,
    required this.origen,
  });

  static const _urlCompilacion = String.fromEnvironment('SACOR_API_URL', defaultValue: 'http://localhost:5084');
  static const _llaveCompilacion = String.fromEnvironment('SACOR_API_KEY');
  static const _demoCompilacion = bool.fromEnvironment('SACOR_DEMO');

  final Uri urlApi;

  final String llaveApi;

  final bool modoDemo;

  final String origen;

  bool get tieneLlave => llaveApi.isNotEmpty;

  static Future<Configuracion> cargar() async {
    var url = _urlCompilacion;
    var llave = _llaveCompilacion;
    var demo = _demoCompilacion;
    var origen = 'valores de compilación';

    final archivo = await leerConfiguracionExterna();
    if (archivo != null) {
      String? texto(String clave) {
        final valor = archivo[clave];
        return valor is String && valor.trim().isNotEmpty ? valor.trim() : null;
      }

      url = texto('apiUrl') ?? url;
      llave = texto('apiKey') ?? llave;
      final demoArchivo = archivo['modoDemo'];
      if (demoArchivo is bool) demo = demoArchivo;
      origen = archivo['_origen'] as String? ?? 'archivo de configuración';
    }

    return Configuracion(
      urlApi: Uri.parse(url.replaceAll(RegExp(r'/+$'), '')),
      llaveApi: llave,
      modoDemo: demo,
      origen: origen,
    );
  }
}
