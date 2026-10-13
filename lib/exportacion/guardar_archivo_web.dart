import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<String?> guardarArchivo({
  required String nombreSugerido,
  required List<int> bytes,
  required String descripcion,
  required String extension,
}) async {
  final blob = web.Blob([Uint8List.fromList(bytes).toJS].toJS);
  final url = web.URL.createObjectURL(blob);
  final enlace = web.HTMLAnchorElement()
    ..href = url
    ..download = nombreSugerido;
  enlace.click();
  web.URL.revokeObjectURL(url);
  return nombreSugerido;
}
