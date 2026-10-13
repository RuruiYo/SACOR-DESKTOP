import 'dart:convert';
import 'dart:io';

const nombreArchivoConfiguracion = 'sacor_config.json';

Future<Map<String, Object?>?> leerConfiguracionExterna() async {
  final carpetas = {
    File(Platform.resolvedExecutable).parent.path,
    Directory.current.path,
  };

  for (final carpeta in carpetas) {
    try {
      final archivo = File('$carpeta${Platform.pathSeparator}$nombreArchivoConfiguracion');
      if (!await archivo.exists()) continue;

      final texto = await archivo.readAsString();
      final contenido = jsonDecode(texto.startsWith('\uFEFF') ? texto.substring(1) : texto);
      if (contenido is Map<String, Object?>) return {...contenido, '_origen': archivo.path};
    } on Object {
      continue;
    }
  }
  return null;
}
