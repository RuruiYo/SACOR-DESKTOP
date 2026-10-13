import 'package:web/web.dart' as web;

Future<void> abrirEnlace(Uri enlace) async {
  web.window.open(enlace.toString(), '_blank');
}
