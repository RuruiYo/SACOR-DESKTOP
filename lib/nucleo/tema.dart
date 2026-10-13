import 'package:flutter/material.dart';

import 'colores.dart';

abstract final class TemaSacor {
  static const fuente = 'Segoe UI';
  static const radio = 12.0;
  static const radioControl = 8.0;

  static ThemeData claro() {
    final esquema = ColorScheme.fromSeed(
      seedColor: ColoresSacor.verde,
      brightness: Brightness.light,
    ).copyWith(
      primary: ColoresSacor.verde,
      onPrimary: ColoresSacor.blanco,
      primaryContainer: ColoresSacor.verdeSuave,
      onPrimaryContainer: ColoresSacor.verdeOscuro,
      secondary: ColoresSacor.azul,
      error: ColoresSacor.rojo,
      surface: ColoresSacor.blanco,
      onSurface: ColoresSacor.texto,
      onSurfaceVariant: ColoresSacor.textoSecundario,
      outline: ColoresSacor.bordeFuerte,
      outlineVariant: ColoresSacor.borde,
      surfaceContainerLowest: ColoresSacor.blanco,
      surfaceContainerLow: ColoresSacor.blanco,
      surfaceContainer: ColoresSacor.blanco,
      surfaceContainerHigh: ColoresSacor.blanco,
      surfaceContainerHighest: ColoresSacor.fondo,
    );

    final bordeControl = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radioControl),
      borderSide: const BorderSide(color: ColoresSacor.bordeFuerte),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      fontFamily: fuente,
      scaffoldBackgroundColor: ColoresSacor.fondo,
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: ColoresSacor.texto,
        displayColor: ColoresSacor.texto,
        fontFamily: fuente,
      ),
      dividerTheme: const DividerThemeData(color: ColoresSacor.borde, thickness: 1, space: 1),
      cardTheme: CardThemeData(
        color: ColoresSacor.blanco,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radio),
          side: const BorderSide(color: ColoresSacor.borde),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColoresSacor.blanco,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: bordeControl,
        enabledBorder: bordeControl,
        focusedBorder: bordeControl.copyWith(
          borderSide: const BorderSide(color: ColoresSacor.verde, width: 2),
        ),
        errorBorder: bordeControl.copyWith(borderSide: const BorderSide(color: ColoresSacor.rojo)),
        focusedErrorBorder: bordeControl.copyWith(
          borderSide: const BorderSide(color: ColoresSacor.rojo, width: 2),
        ),
        labelStyle: const TextStyle(color: ColoresSacor.textoSecundario),
        floatingLabelStyle: const TextStyle(color: ColoresSacor.verde),
        hintStyle: const TextStyle(color: ColoresSacor.textoTenue),
        helperStyle: const TextStyle(color: ColoresSacor.textoTenue, fontSize: 12),
        prefixIconColor: ColoresSacor.textoTenue,
        suffixIconColor: ColoresSacor.textoTenue,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ColoresSacor.verde,
          foregroundColor: ColoresSacor.blanco,
          disabledBackgroundColor: ColoresSacor.borde,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          textStyle: const TextStyle(fontFamily: fuente, fontWeight: FontWeight.w600, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radioControl)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColoresSacor.texto,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          side: const BorderSide(color: ColoresSacor.bordeFuerte),
          textStyle: const TextStyle(fontFamily: fuente, fontWeight: FontWeight.w600, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radioControl)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColoresSacor.verde,
          textStyle: const TextStyle(fontFamily: fuente, fontWeight: FontWeight.w600, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radioControl)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: ColoresSacor.textoSecundario),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ColoresSacor.blanco,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radio)),
        titleTextStyle: const TextStyle(
          fontFamily: fuente,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: ColoresSacor.texto,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: ColoresSacor.blanco,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radioControl),
          side: const BorderSide(color: ColoresSacor.borde),
        ),
      ),
      menuTheme: const MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(ColoresSacor.blanco),
          surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: ColoresSacor.texto,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: const TextStyle(fontFamily: fuente, color: ColoresSacor.blanco, fontSize: 12),
        waitDuration: const Duration(milliseconds: 400),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ColoresSacor.texto,
        contentTextStyle: const TextStyle(fontFamily: fuente, color: ColoresSacor.blanco),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radioControl)),
        width: 480,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: ColoresSacor.verde,
        unselectedLabelColor: ColoresSacor.textoSecundario,
        indicatorColor: ColoresSacor.verde,
        dividerColor: ColoresSacor.borde,
        labelStyle: TextStyle(fontFamily: fuente, fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: TextStyle(fontFamily: fuente, fontWeight: FontWeight.w500, fontSize: 14),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (estados) => estados.contains(WidgetState.selected) ? ColoresSacor.verdeSuave : ColoresSacor.blanco,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (estados) => estados.contains(WidgetState.selected) ? ColoresSacor.verdeOscuro : ColoresSacor.texto,
          ),
          side: const WidgetStatePropertyAll(BorderSide(color: ColoresSacor.bordeFuerte)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(radioControl)),
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: ColoresSacor.verde),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(ColoresSacor.textoTenue.withValues(alpha: 0.35)),
        radius: const Radius.circular(8),
        thickness: const WidgetStatePropertyAll(8),
      ),
    );
  }
}
