Future<Map<String, Object?>?> leerConfiguracionExterna() async {
  final parametros = Uri.base.queryParameters;
  if (!parametros.containsKey('demo') && !parametros.containsKey('api')) return null;

  return {
    if (parametros['api'] != null) 'apiUrl': parametros['api'],
    if (parametros['demo'] != null) 'modoDemo': parametros['demo'] == '1',
    '_origen': 'parámetros de la dirección',
  };
}
