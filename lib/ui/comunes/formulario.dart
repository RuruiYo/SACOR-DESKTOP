import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../datos/cliente_api.dart';
import '../../nucleo/colores.dart';
import '../../nucleo/dinero.dart';
import '../../nucleo/formatos.dart';
import 'controles.dart';
import 'insignia.dart';
import 'tarjeta.dart';

enum Ancho { medio, completo }

sealed class Campo {
  const Campo(this.clave, this.etiqueta, {this.obligatorio = true, this.ayuda, this.ancho = Ancho.medio});

  final String clave;
  final String etiqueta;
  final bool obligatorio;
  final String? ayuda;
  final Ancho ancho;

  String get etiquetaVisible => obligatorio ? '$etiqueta *' : etiqueta;
}

class CampoTexto extends Campo {
  const CampoTexto(
    super.clave,
    super.etiqueta, {
    super.obligatorio,
    super.ayuda,
    super.ancho,
    this.largo = 150,
    this.lineas = 1,
    this.validar,
    this.sugerencias = const [],
    this.mayusculas = false,
  });

  final int largo;
  final int lineas;
  final String? Function(String valor)? validar;

  final List<String> sugerencias;
  final bool mayusculas;
}

class CampoDinero extends Campo {
  const CampoDinero(super.clave, super.etiqueta, {super.obligatorio, super.ayuda, super.ancho, this.permitirCero = false});

  final bool permitirCero;
}

class CampoNumero extends Campo {
  const CampoNumero(
    super.clave,
    super.etiqueta, {
    super.obligatorio,
    super.ayuda,
    super.ancho,
    this.decimales = 0,
    this.minimo,
    this.maximo,
    this.sufijo,
  });

  final int decimales;
  final double? minimo;
  final double? maximo;
  final String? sufijo;
}

class CampoFecha extends Campo {
  const CampoFecha(super.clave, super.etiqueta, {super.obligatorio, super.ayuda, super.ancho, this.soloMes = false});

  final bool soloMes;
}

class CampoOpciones<T> extends Campo {
  const CampoOpciones(super.clave, super.etiqueta, this.opciones, {super.obligatorio, super.ayuda, super.ancho});

  final List<(T, String)> opciones;
}

class CampoSeleccion extends Campo {
  const CampoSeleccion(super.clave, super.etiqueta, this.opciones,
      {super.obligatorio = false, super.ayuda, super.ancho = Ancho.completo});

  final List<(int, String)> opciones;
}

Future<bool> mostrarFormulario(
  BuildContext context, {
  required String titulo,
  String? subtitulo,
  required List<Campo> campos,
  Map<String, Object?> iniciales = const {},
  String textoGuardar = 'Guardar',
  double ancho = 640,
  Widget? encabezado,
  required Future<void> Function(Map<String, Object?> valores) alGuardar,
}) async {
  final guardado = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _DialogoFormulario(
      titulo: titulo,
      subtitulo: subtitulo,
      campos: campos,
      iniciales: iniciales,
      textoGuardar: textoGuardar,
      ancho: ancho,
      encabezado: encabezado,
      alGuardar: alGuardar,
    ),
  );
  return guardado ?? false;
}

class _DialogoFormulario extends StatefulWidget {
  const _DialogoFormulario({
    required this.titulo,
    required this.subtitulo,
    required this.campos,
    required this.iniciales,
    required this.textoGuardar,
    required this.ancho,
    required this.encabezado,
    required this.alGuardar,
  });

  final String titulo;
  final String? subtitulo;
  final List<Campo> campos;
  final Map<String, Object?> iniciales;
  final String textoGuardar;
  final double ancho;
  final Widget? encabezado;
  final Future<void> Function(Map<String, Object?> valores) alGuardar;

  @override
  State<_DialogoFormulario> createState() => _DialogoFormularioState();
}

class _DialogoFormularioState extends State<_DialogoFormulario> {
  final _formulario = GlobalKey<FormState>();
  final _controladores = <String, TextEditingController>{};
  final _valores = <String, Object?>{};
  bool _ocupado = false;

  AutovalidateMode _validacion = AutovalidateMode.disabled;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final campo in widget.campos) {
      final inicial = widget.iniciales[campo.clave];
      switch (campo) {
        case CampoTexto():
          _controladores[campo.clave] = TextEditingController(text: inicial as String? ?? '');
        case CampoDinero():
          _controladores[campo.clave] =
              TextEditingController(text: inicial is Dinero ? inicial.comoTextoEditable : '');
        case CampoNumero():
          _controladores[campo.clave] = TextEditingController(text: inicial is num ? _numero(inicial) : '');
        case CampoSeleccion():
          _valores[campo.clave] = {...(inicial as Iterable<int>? ?? const <int>[])};
        case CampoFecha() || CampoOpciones():
          _valores[campo.clave] = inicial;
      }
    }
  }

  static String _numero(num valor) =>
      valor == valor.roundToDouble() ? valor.toInt().toString() : valor.toString();

  @override
  void dispose() {
    for (final c in _controladores.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, Object?> _leer() => {
        for (final campo in widget.campos)
          campo.clave: switch (campo) {
            CampoTexto() => () {
                final texto = _controladores[campo.clave]!.text.trim();
                if (texto.isEmpty) return null;
                return campo.mayusculas ? texto.toUpperCase() : texto;
              }(),
            CampoDinero() => Dinero.interpretar(_controladores[campo.clave]!.text) ?? const Dinero.cero(),
            CampoNumero() => () {
                final texto = _controladores[campo.clave]!.text.trim().replaceAll(',', '');
                if (texto.isEmpty) return null;
                return campo.decimales == 0 ? int.tryParse(texto) : double.tryParse(texto);
              }(),
            _ => _valores[campo.clave],
          },
      };

  Future<void> _guardar() async {
    if (_ocupado) return;
    setState(() => _error = null);
    if (!(_formulario.currentState?.validate() ?? false)) {
      setState(() => _validacion = AutovalidateMode.onUserInteraction);
      return;
    }

    setState(() => _ocupado = true);
    try {
      await widget.alGuardar(_leer());
      if (mounted) Navigator.of(context).pop(true);
    } on ApiExcepcion catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } on FormatException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on Object catch (e) {
      debugPrint('Error al guardar: $e');
      if (mounted) setState(() => _error = 'No se pudo guardar. Intente de nuevo.');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DialogoFormulario(
      titulo: widget.titulo,
      subtitulo: widget.subtitulo,
      ancho: widget.ancho,
      contenido: Form(
        key: _formulario,
        autovalidateMode: _validacion,
        child: LayoutBuilder(builder: (context, restricciones) {
          final mitad = (restricciones.maxWidth - 16) / 2;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.encabezado != null) ...[widget.encabezado!, const SizedBox(height: 16)],
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final campo in widget.campos)
                    SizedBox(
                      width: campo.ancho == Ancho.completo ? restricciones.maxWidth : mitad,
                      child: _campo(campo),
                    ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Aviso(tono: TonoInsignia.error, mensaje: _error!),
              ],
            ],
          );
        }),
      ),
      acciones: [
        TextButton(
          onPressed: _ocupado ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        BotonOcupado(texto: widget.textoGuardar, ocupado: _ocupado, alPresionar: _guardar),
      ],
    );
  }

  Widget _campo(Campo campo) {
    switch (campo) {
      case CampoTexto():
        final controlador = _controladores[campo.clave]!;
        return TextFormField(
          controller: controlador,
          maxLength: campo.largo,
          minLines: campo.lineas,
          maxLines: campo.lineas,
          textCapitalization: campo.mayusculas ? TextCapitalization.characters : TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: campo.etiquetaVisible,
            helperText: campo.ayuda,
            helperMaxLines: 2,
            counterText: '',
            suffixIcon: campo.sugerencias.isEmpty
                ? null
                : PopupMenuButton<String>(
                    tooltip: 'Elegir un valor',
                    icon: const Icon(Icons.arrow_drop_down),
                    onSelected: (valor) => controlador.text = valor,
                    itemBuilder: (_) => [
                      for (final s in campo.sugerencias) PopupMenuItem(value: s, child: Text(s)),
                    ],
                  ),
          ),
          validator: (texto) {
            final valor = texto?.trim() ?? '';
            if (valor.isEmpty) return campo.obligatorio ? 'Este dato es obligatorio.' : null;
            return campo.validar?.call(campo.mayusculas ? valor.toUpperCase() : valor);
          },
        );
      case CampoDinero():
        return CampoMonto(
          controlador: _controladores[campo.clave]!,
          etiqueta: campo.etiquetaVisible,
          ayuda: campo.ayuda,
          permitirCero: campo.permitirCero,
          obligatorio: campo.obligatorio,
        );
      case CampoNumero():
        return TextFormField(
          controller: _controladores[campo.clave],
          keyboardType: TextInputType.numberWithOptions(decimal: campo.decimales > 0),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(campo.decimales > 0 ? r'[0-9.,]' : r'[0-9]'))],
          decoration: InputDecoration(
            labelText: campo.etiquetaVisible,
            helperText: campo.ayuda,
            helperMaxLines: 2,
            suffixText: campo.sufijo,
          ),
          validator: (texto) {
            final valor = texto?.trim().replaceAll(',', '') ?? '';
            if (valor.isEmpty) return campo.obligatorio ? 'Este dato es obligatorio.' : null;
            final numero = double.tryParse(valor);
            if (numero == null) return 'Número inválido.';
            final partes = valor.split('.');
            if (partes.length > 1 && partes[1].length > campo.decimales) {
              return 'Máximo ${campo.decimales} decimales.';
            }
            if (campo.minimo != null && numero < campo.minimo!) return 'Debe ser al menos ${_numero(campo.minimo!)}.';
            if (campo.maximo != null && numero > campo.maximo!) return 'No puede pasar de ${_numero(campo.maximo!)}.';
            return null;
          },
        );
      case CampoFecha():
        return FormField<DateTime>(
          initialValue: _valores[campo.clave] as DateTime?,
          validator: (_) => campo.obligatorio && _valores[campo.clave] == null ? 'Elija la fecha.' : null,
          builder: (estado) {
            final fecha = _valores[campo.clave] as DateTime?;
            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () async {
                final elegida = campo.soloMes
                    ? await elegirMes(context, fecha ?? DateTime.now())
                    : await showDatePicker(
                        context: context,
                        initialDate: fecha ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(DateTime.now().year + 2, 12, 31),
                        helpText: campo.etiqueta,
                      );
                if (elegida != null) {
                  setState(() => _valores[campo.clave] = DateTime(elegida.year, elegida.month, elegida.day));
                  estado.didChange(elegida);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: campo.etiquetaVisible,
                  helperText: campo.ayuda,
                  helperMaxLines: 2,
                  errorText: estado.errorText,
                  suffixIcon: fecha != null && !campo.obligatorio
                      ? IconButton(
                          tooltip: 'Quitar fecha',
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            setState(() => _valores[campo.clave] = null);
                            estado.didChange(null);
                          },
                        )
                      : const Icon(Icons.calendar_today_outlined, size: 18),
                ),
                child: Text(
                  fecha == null
                      ? (campo.obligatorio ? '' : 'Sin fecha')
                      : campo.soloMes
                          ? Formatos.mesLargo(fecha.year, fecha.month)
                          : Formatos.fecha(fecha),
                  style: Estilos.cuerpo,
                ),
              ),
            );
          },
        );
      case CampoOpciones():
        return _opciones(campo);
      case CampoSeleccion():
        return FormField<Set<int>>(
          validator: (_) =>
              campo.obligatorio && (_valores[campo.clave] as Set<int>).isEmpty ? 'Elija al menos uno.' : null,
          builder: (estado) {
            final elegidos = _valores[campo.clave] as Set<int>;
            return InputDecorator(
              decoration: InputDecoration(
                labelText: campo.etiquetaVisible,
                helperText: campo.ayuda,
                errorText: estado.errorText,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(top: 8),
              ),
              child: campo.opciones.isEmpty
                  ? const Text('No hay opciones disponibles.', style: Estilos.tenue)
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (id, texto) in campo.opciones)
                          FilterChip(
                            label: Text(texto),
                            selected: elegidos.contains(id),
                            selectedColor: ColoresSacor.verdeSuave,
                            checkmarkColor: ColoresSacor.verdeOscuro,
                            onSelected: (si) => setState(() {
                              si ? elegidos.add(id) : elegidos.remove(id);
                              estado.didChange(elegidos);
                            }),
                          ),
                      ],
                    ),
            );
          },
        );
    }
  }

  Widget _opciones<T>(CampoOpciones<T> campo) {
    final actual = _valores[campo.clave] as T?;
    final existe = campo.opciones.any((o) => o.$1 == actual);
    return DropdownButtonFormField<T>(
      initialValue: existe ? actual : null,
      isExpanded: true,
      menuMaxHeight: 380,
      borderRadius: BorderRadius.circular(8),
      dropdownColor: ColoresSacor.blanco,
      decoration: InputDecoration(labelText: campo.etiquetaVisible, helperText: campo.ayuda, helperMaxLines: 2),
      items: [
        for (final (valor, texto) in campo.opciones)
          DropdownMenuItem<T>(value: valor, child: Text(texto, overflow: TextOverflow.ellipsis)),
      ],
      validator: (valor) => campo.obligatorio && valor == null ? 'Elija una opción.' : null,
      onChanged: (valor) => setState(() => _valores[campo.clave] = valor),
    );
  }
}

Future<DateTime?> elegirMes(BuildContext context, DateTime inicial) {
  return showDialog<DateTime>(
    context: context,
    builder: (contexto) {
      var anio = inicial.year;
      return StatefulBuilder(
        builder: (contexto, actualizar) => AlertDialog(
          title: Row(
            children: [
              IconButton(
                tooltip: 'Año anterior',
                onPressed: () => actualizar(() => anio--),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(child: Text('$anio', textAlign: TextAlign.center)),
              IconButton(
                tooltip: 'Año siguiente',
                onPressed: () => actualizar(() => anio++),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          content: SizedBox(
            width: 320,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var mes = 1; mes <= 12; mes++)
                  SizedBox(
                    width: 96,
                    child: (anio == inicial.year && mes == inicial.month)
                        ? FilledButton(
                            onPressed: () => Navigator.of(contexto).pop(DateTime(anio, mes)),
                            child: Text(Formatos.nombreMes(mes).substring(0, 3)),
                          )
                        : OutlinedButton(
                            onPressed: () => Navigator.of(contexto).pop(DateTime(anio, mes)),
                            child: Text(Formatos.nombreMes(mes).substring(0, 3)),
                          ),
                  ),
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.of(contexto).pop(), child: const Text('Cancelar'))],
        ),
      );
    },
  );
}

Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  String accion = 'Eliminar',
}) async {
  final respuesta = await showDialog<bool>(
    context: context,
    builder: (contexto) => AlertDialog(
      title: Text(titulo),
      content: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Text(mensaje)),
      actions: [
        TextButton(onPressed: () => Navigator.of(contexto).pop(false), child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: ColoresSacor.rojo),
          onPressed: () => Navigator.of(contexto).pop(true),
          child: Text(accion),
        ),
      ],
    ),
  );
  return respuesta ?? false;
}

Future<void> eliminarConConfirmacion(
  BuildContext context, {
  required String que,
  required Future<void> Function() eliminar,
}) async {
  final si = await confirmar(context, titulo: 'Eliminar $que', mensaje: '¿Eliminar $que? No se puede deshacer.');
  if (!si || !context.mounted) return;
  try {
    await eliminar();
    if (context.mounted) notificar(context, 'Se eliminó $que.');
  } on ApiExcepcion catch (e) {
    if (context.mounted) notificar(context, e.mensaje, error: true);
  }
}

abstract final class Validar {
  static final _dui = RegExp(r'^\d{8}-\d$');
  static final _telefono = RegExp(r'^(\+503)?[\s-]?[267]\d{3}[\s-]?\d{4}$');
  static final _correo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? dui(String valor) => _dui.hasMatch(valor) ? null : 'Formato 00000000-0.';
  static String? telefono(String valor) => _telefono.hasMatch(valor) ? null : 'Teléfono de El Salvador (7000-0000).';
  static String? correo(String valor) => _correo.hasMatch(valor) ? null : 'Correo inválido.';
}
