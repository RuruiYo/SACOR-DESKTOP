import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

Future<String?> guardarArchivo({
  required String nombreSugerido,
  required List<int> bytes,
  required String descripcion,
  required String extension,
}) async {
  final destino = await getSaveLocation(
    suggestedName: nombreSugerido,
    acceptedTypeGroups: [
      XTypeGroup(label: descripcion, extensions: [extension]),
    ],
  );
  if (destino == null) return null;

  var ruta = destino.path;
  if (!ruta.toLowerCase().endsWith('.$extension')) ruta = '$ruta.$extension';

  await File(ruta).writeAsBytes(Uint8List.fromList(bytes), flush: true);
  return ruta;
}
