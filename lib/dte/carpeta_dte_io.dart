import 'dart:convert';
import 'dart:io';

import 'documento_dte.dart';

const carpetaDteDisponible = true;

File _archivoPreferencias() {
  final base = Platform.environment['APPDATA'] ?? Platform.environment['HOME'] ?? '.';
  return File([base, 'SACOR', 'preferencias.json'].join(Platform.pathSeparator));
}

Future<String?> carpetaDteElegida() async {
  try {
    final archivo = _archivoPreferencias();
    if (!await archivo.exists()) return null;
    final datos = jsonDecode(await archivo.readAsString());
    final ruta = datos is Map ? datos['carpetaDte'] : null;
    return ruta is String && ruta.trim().isNotEmpty ? ruta : null;
  } on Object {
    return null;
  }
}

Future<void> guardarCarpetaDte(String? ruta) async {
  final archivo = _archivoPreferencias();
  await archivo.parent.create(recursive: true);
  await archivo.writeAsString(jsonEncode({'carpetaDte': ?ruta}));
}

Future<String> carpetaDtePorDefecto() async {
  final separador = Platform.pathSeparator;
  return [await _documentos(), 'SACOR', 'DTE'].join(separador);
}

Future<String> _documentos() async {
  final perfil = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
  final porDefecto = '$perfil${Platform.pathSeparator}Documents';
  if (Platform.isWindows) {
    try {
      final resultado = await Process.run('reg', [
        'query',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders',
        '/v',
        'Personal',
      ]);
      final linea = RegExp(r'Personal\s+REG_SZ\s+(.+)').firstMatch('${resultado.stdout}');
      final ruta = linea?.group(1)?.trim();
      if (ruta != null && ruta.isNotEmpty && await Directory(ruta).exists()) return ruta;
    } on Object {
      return porDefecto;
    }
  }
  return porDefecto;
}

Future<List<DocumentoDte>> leerCarpetaDte(String ruta) async {
  final carpeta = Directory(ruta);
  if (!await carpeta.exists()) await carpeta.create(recursive: true);

  final documentos = <DocumentoDte>[];
  await for (final entrada in carpeta.list()) {
    if (entrada is! File || !entrada.path.toLowerCase().endsWith('.json')) continue;
    final nombre = entrada.uri.pathSegments.last;
    try {
      if (await entrada.length() > 2 * 1024 * 1024) {
        documentos.add(DocumentoDte(archivo: nombre, error: 'El archivo es demasiado grande para ser un DTE.'));
        continue;
      }
      documentos.add(DocumentoDte.interpretar(nombre, await entrada.readAsString()));
    } on FileSystemException {
      documentos.add(DocumentoDte(archivo: nombre, error: 'No se pudo leer el archivo.'));
    } on FormatException {
      documentos.add(DocumentoDte(archivo: nombre, error: 'El archivo no está en UTF-8.'));
    }
  }
  return documentos;
}

Future<void> abrirCarpeta(String ruta) async {
  await Directory(ruta).create(recursive: true);
  if (Platform.isWindows) {
    await Process.start('explorer', [ruta]);
  } else if (Platform.isMacOS) {
    await Process.start('open', [ruta]);
  } else {
    await Process.start('xdg-open', [ruta]);
  }
}
