String? numeroWhatsapp(String? telefono) {
  final digitos = (telefono ?? '').replaceAll(RegExp(r'\D'), '');
  if (digitos.length == 8) return '503$digitos';
  if (digitos.length == 11 && digitos.startsWith('503')) return digitos;
  return null;
}

String primerNombre(String nombre) {
  final partes = nombre.trim().split(RegExp(r'\s+'));
  return partes.isEmpty ? nombre : partes.first;
}

Uri? enlaceWhatsapp(String? telefono, String mensaje) {
  final numero = numeroWhatsapp(telefono);
  if (numero == null) return null;
  return Uri.parse('https://wa.me/$numero?text=${Uri.encodeComponent(mensaje)}');
}

String saludoCotizacion(String nombre, String? servicio, int id) =>
    'Hola ${primerNombre(nombre)}, le saluda SACOR sobre su solicitud de '
    '${servicio == null ? 'servicio' : servicio.toLowerCase()} (cotización #$id).';

String saludoPostulacion(String nombre, String puesto, int id) =>
    'Hola ${primerNombre(nombre)}, le saluda SACOR sobre su postulación para '
    '${puesto.toLowerCase()} (solicitud #$id).';
