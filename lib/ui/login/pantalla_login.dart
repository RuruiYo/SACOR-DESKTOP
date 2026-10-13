import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../configuracion/configuracion.dart';
import '../../estado/navegacion_estado.dart';
import '../../estado/sesion_estado.dart';
import '../../nucleo/colores.dart';
import '../comunes/insignia.dart';
import '../comunes/tarjeta.dart';
import '../shell/logo.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final _codigo = TextEditingController();
  bool _visible = false;

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _ingresar() async {
    final sesion = context.read<SesionEstado>();
    final navegacion = context.read<NavegacionEstado>();

    final correcto = await sesion.iniciarSesion(_codigo.text);
    if (correcto) {
      navegacion.reiniciar();
    } else {
      _codigo.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<SesionEstado>();
    final configuracion = context.read<Configuracion>();

    return Scaffold(
      backgroundColor: ColoresSacor.fondo,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(40, 36, 40, 32),
                  decoration: BoxDecoration(
                    color: ColoresSacor.blanco,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: ColoresSacor.texto.withValues(alpha: 0.08),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const LogoSacor(tamano: 44),
                      const SizedBox(height: 32),
                      const Text(
                        'Iniciar sesión',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: ColoresSacor.texto),
                      ),
                      const SizedBox(height: 6),
                      const Text('Acceso exclusivo del administrador general.', style: Estilos.secundario),
                      if (configuracion.modoDemo) ...[
                        const SizedBox(height: 16),
                        const Aviso(
                          tono: TonoInsignia.alerta,
                          titulo: 'Modo demostración',
                          mensaje: 'Los datos son ficticios. Código de prueba: 482913.',
                        ),
                      ],
                      if (!configuracion.modoDemo && !configuracion.tieneLlave) ...[
                        const SizedBox(height: 16),
                        const Aviso(
                          tono: TonoInsignia.error,
                          titulo: 'Falta la llave de la API',
                          mensaje: 'Agregue "apiKey" (la llave AppEscritorio que configuró Steven) en '
                              'sacor_config.json, junto a SACOR.Desktop.exe.',
                        ),
                      ],
                      if (sesion.aviso != null && sesion.error == null) ...[
                        const SizedBox(height: 16),
                        Aviso(tono: TonoInsignia.info, mensaje: sesion.aviso!),
                      ],
                      const SizedBox(height: 28),
                      TextField(
                        key: const Key('campo-codigo'),
                        controller: _codigo,
                        autofocus: true,
                        obscureText: !_visible,
                        enableSuggestions: false,
                        autocorrect: false,
                        maxLength: 30,
                        enabled: !sesion.cargando,
                        onSubmitted: (_) => _ingresar(),
                        decoration: InputDecoration(
                          labelText: 'Código de empleado *',
                          helperText: 'El mismo código que usa en la app móvil de SACOR.',
                          counterText: '',
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            tooltip: _visible ? 'Ocultar código' : 'Mostrar código',
                            icon: Icon(_visible ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                            onPressed: () => setState(() => _visible = !_visible),
                          ),
                        ),
                      ),
                      if (sesion.error != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline, size: 18, color: ColoresSacor.rojo),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                sesion.error!,
                                style: const TextStyle(fontSize: 13, color: ColoresSacor.rojoTexto),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 44,
                        child: FilledButton(
                          key: const Key('boton-ingresar'),
                          onPressed: sesion.cargando ? null : _ingresar,
                          child: sesion.cargando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: ColoresSacor.blanco),
                                )
                              : const Text('INGRESAR', style: TextStyle(letterSpacing: 0.6)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Row(
                        children: [
                          Icon(Icons.shield_outlined, size: 16, color: ColoresSacor.textoTenue),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'La sesión se cierra sola tras 30 minutos sin actividad.',
                              style: Estilos.tenue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                configuracion.modoDemo
                    ? 'SACOR Desktop · datos de demostración'
                    : 'Servidor: ${configuracion.urlApi}',
                style: Estilos.tenue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
