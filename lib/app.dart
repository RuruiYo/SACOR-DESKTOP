import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'configuracion/configuracion.dart';
import 'datos/fuente_datos.dart';
import 'estado/almacen.dart';
import 'estado/navegacion_estado.dart';
import 'estado/periodo_estado.dart';
import 'estado/sesion_estado.dart';
import 'nucleo/tema.dart';
import 'ui/login/pantalla_login.dart';
import 'ui/shell/shell.dart';

class SacorApp extends StatelessWidget {
  const SacorApp({super.key, required this.configuracion, required this.fuente, this.reloj});

  final Configuracion configuracion;
  final FuenteDatos fuente;

  final DateTime Function()? reloj;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<Configuracion>.value(value: configuracion),
        ChangeNotifierProvider<AlmacenSacor>(create: (_) => AlmacenSacor(fuente)),
        ChangeNotifierProvider<SesionEstado>(
          create: (contexto) => SesionEstado(contexto.read<AlmacenSacor>(), reloj: reloj),
        ),
        ChangeNotifierProvider<PeriodoEstado>(create: (_) => PeriodoEstado(reloj: reloj)),
        ChangeNotifierProvider<NavegacionEstado>(create: (_) => NavegacionEstado()),
      ],
      child: MaterialApp(
        title: 'SACOR Desktop',
        debugShowCheckedModeBanner: false,
        theme: TemaSacor.claro(),
        locale: const Locale('es'),
        supportedLocales: const [Locale('es'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const _Inicio(),
      ),
    );
  }
}

class _Inicio extends StatelessWidget {
  const _Inicio();

  @override
  Widget build(BuildContext context) {
    final autenticado = context.select<SesionEstado, bool>((s) => s.autenticado);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: autenticado ? const Shell(key: ValueKey('shell')) : const PantallaLogin(key: ValueKey('login')),
    );
  }
}
