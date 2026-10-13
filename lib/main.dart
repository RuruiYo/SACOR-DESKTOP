import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app.dart';
import 'configuracion/configuracion.dart';
import 'datos/cliente_api.dart';
import 'datos/fuente_datos.dart';
import 'datos/memoria/fuente_memoria.dart';
import 'datos/memoria/semilla_demo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Intl.defaultLocale = 'es';
  await initializeDateFormatting('es');

  final configuracion = await Configuracion.cargar();
  final FuenteDatos fuente = configuracion.modoDemo
      ? FuenteMemoria(semillaDemo(DateTime.now()))
      : FuenteApi(ClienteApi(configuracion.urlApi, configuracion.llaveApi));

  runApp(SacorApp(configuracion: configuracion, fuente: fuente));
}
