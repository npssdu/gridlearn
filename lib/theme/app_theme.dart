import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Lenguaje de diseño de GridLearn, derivado del logo (ver `docs/DISENO.md`).
///
/// * **Azul marino** (`navy`): el cuerpo del icono y "Grid". Es el color de
///   texto, de las acciones principales y de las superficies oscuras.
/// * **Fichas** `sky`, `amber`, `teal`: los tres colores de la fila central
///   del logo (A, birrete, B). Se usan para señalar y diferenciar.
/// * **Naranja** (`orange`): "Learn". Es el acento: la llamada a la acción.
/// * **Contorno** `navySoft`: las celdas vacías del logo.
class AppColors {
  // Marca (valores medidos del logo)
  static const navy = Color(0xFF1F325C);
  static const navyDeep = Color(0xFF16254A);
  static const navySoft = Color(0xFF3F5B8B);
  static const sky = Color(0xFF43B0EB);
  static const amber = Color(0xFFFFB322);
  static const teal = Color(0xFF41C9AF);
  static const orange = Color(0xFFFF7512);

  // Extensiones de la paleta para llegar a 6 filas distintas (mismo brillo y
  // saturación que las fichas del logo).
  static const periwinkle = Color(0xFF7B8CEA);
  static const rose = Color(0xFFF2698E);

  // Celeste suave (fondos, chips, foco)
  static const sky50 = Color(0xFFEEF7FD);
  static const sky100 = Color(0xFFDCEEFB);
  static const sky300 = Color(0xFF8CCBF2);
  static const sky500 = sky;

  // Neutros fríos con el matiz del azul marino
  static const slate50 = Color(0xFFF4F6FA);
  static const slate100 = Color(0xFFEBEEF5);
  static const slate200 = Color(0xFFDCE1EC);
  static const slate300 = Color(0xFFC3CAD9);
  static const slate400 = Color(0xFF94A0BB);
  static const slate500 = Color(0xFF5F6E8F);
  static const slate600 = Color(0xFF4A5A7E);
  static const slate700 = Color(0xFF34466E);
  static const slate900 = navy;

  // Semánticos
  static const success = Color(0xFF138A73);
  static const warning = Color(0xFFB45309);
  static const danger = Color(0xFFD6336C);

  // Compatibilidad con nombres anteriores de la paleta
  static const brand50 = sky50;
  static const brand100 = sky100;
  static const brand300 = sky300;
  static const brand500 = sky;
  static const brand600 = navy;
  static const brand700 = navy;
  static const accent400 = Color(0xFFFF9340);
  static const accent500 = orange;
}

/// Radios: las esquinas redondeadas del logo (≈21 % del lado en el icono y
/// ≈22 % en las fichas) llevadas a cada componente.
class AppRadii {
  static const double tile = 14; // casillas de la grilla, fichas
  static const double control = 14; // botones y campos
  static const double card = 24; // tarjetas y diálogos
  static const double pill = 999;
}

class AppTheme {
  static bool _useGoogleFonts = true;

  /// [useGoogleFonts] se desactiva en las pruebas para no pedir fuentes a la red.
  static ThemeData build({bool useGoogleFonts = true}) {
    _useGoogleFonts = useGoogleFonts;
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.navy,
      onPrimary: Colors.white,
      primaryContainer: AppColors.sky100,
      onPrimaryContainer: AppColors.navy,
      secondary: AppColors.orange,
      onSecondary: Colors.white,
      tertiary: AppColors.teal,
      onTertiary: AppColors.navy,
      error: AppColors.danger,
      onError: Colors.white,
      surface: Colors.white,
      onSurface: AppColors.navy,
      surfaceContainerHighest: AppColors.slate100,
      outline: AppColors.slate300,
      outlineVariant: AppColors.slate200,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
    );
    // Nunito: sans redondeada, parecida a la de la palabra "GridLearn".
    final textTheme = useGoogleFonts ? GoogleFonts.nunitoTextTheme(base.textTheme) : base.textTheme;
    final RoundedRectangleBorder controlShape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.control));
    const buttonStyle = TextStyle(fontWeight: FontWeight.w800, fontSize: 14);
    final buttonText = useGoogleFonts ? GoogleFonts.nunito(textStyle: buttonStyle) : buttonStyle;

    return base.copyWith(
      textTheme: textTheme.apply(bodyColor: AppColors.navy, displayColor: AppColors.navy),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.slate200,
          disabledForegroundColor: AppColors.slate400,
          shape: controlShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          side: const BorderSide(color: AppColors.slate300),
          shape: controlShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.navySoft,
          shape: controlShape,
          textStyle: buttonText,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(controlShape),
          textStyle: WidgetStatePropertyAll(buttonText),
          side: const WidgetStatePropertyAll(BorderSide(color: AppColors.slate300)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.navy : Colors.white,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? Colors.white : AppColors.navy,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        hintStyle: const TextStyle(color: AppColors.slate400),
        labelStyle: const TextStyle(color: AppColors.slate500),
        border: _border(AppColors.slate300),
        enabledBorder: _border(AppColors.slate300),
        focusedBorder: _border(AppColors.sky, width: 2),
        errorBorder: _border(AppColors.danger),
        focusedErrorBorder: _border(AppColors.danger, width: 2),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.card)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.control)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.navy,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.control)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.sky),
      iconTheme: const IconThemeData(color: AppColors.navy),
    );
  }

  /// Títulos: Nunito en peso extra, como la palabra del logo.
  static TextStyle heading(
    double size, {
    FontWeight weight = FontWeight.w800,
    Color? color,
  }) {
    final style = TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.navy,
      height: 1.15,
    );
    return _useGoogleFonts ? GoogleFonts.nunito(textStyle: style) : style;
  }

  static OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.control),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
