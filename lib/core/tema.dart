import 'package:flutter/material.dart';

/// Los colores del sistema, tomados del prototipo de Leep.
///
/// Es una paleta calida de papel, no el gris azulado de Material por defecto:
/// una app que miras todos los dias para ver malas noticias sobre tu plata
/// agradece verse tranquila.
///
/// El tema claro sale tal cual del prototipo. El oscuro no: el prototipo es
/// solo claro, asi que esta derivado. La regla al derivarlo fue no invertir
/// nada a ciegas, porque el verde de marca sobre negro no se lee; en oscuro el
/// acento pasa al verde menta, que si contrasta.
class Tokens {
  const Tokens({
    required this.plano,
    required this.superficie,
    required this.superficie2,
    required this.tinta,
    required this.tinta2,
    required this.apagado,
    required this.grilla,
    required this.borde,
    required this.marca,
    required this.bueno,
    required this.aviso,
    required this.serio,
    required this.critico,
    required this.serie,
  });

  final Color plano;
  final Color superficie;
  final Color superficie2;
  final Color tinta;
  final Color tinta2;
  final Color apagado;
  final Color grilla;
  final Color borde;

  /// El verde de Leep. Cambia entre temas a proposito: ver la nota de arriba.
  final Color marca;

  final Color bueno;
  final Color aviso;
  final Color serio;
  final Color critico;

  /// Paleta categorica para los graficos.
  final List<Color> serie;

  static const claro = Tokens(
    plano: Color(0xFFF5EAD8),
    superficie: Color(0xFFF9F4ED),
    superficie2: Color(0xFFEBDDC5),
    tinta: Color(0xFF201E1D),
    tinta2: Color(0xFF656260),
    apagado: Color(0xFF918D89),
    grilla: Color(0xFFDCD3C4),
    borde: Color(0x24201E1D),
    marca: Color(0xFF1E5A37),
    bueno: Color(0xFF1E5A37),
    aviso: Color(0xFFC87A3E),
    serio: Color(0xFF9E4420),
    critico: Color(0xFF93122E),
    serie: [
      Color(0xFF9E4420),
      Color(0xFF0A6360),
      Color(0xFF22306B),
      Color(0xFFC87A3E),
      Color(0xFF1E5A37),
      Color(0xFFD4607A),
      Color(0xFF3FB8AE),
      Color(0xFFE08B5B),
    ],
  );

  static const oscuro = Tokens(
    plano: Color(0xFF17191A),
    superficie: Color(0xFF1F2223),
    superficie2: Color(0xFF282C2D),
    tinta: Color(0xFFF5EAD8),
    tinta2: Color(0xFFB9B0A3),
    apagado: Color(0xFF8A8478),
    grilla: Color(0xFF33383A),
    borde: Color(0x24F5EAD8),
    marca: Color(0xFF86C79A),
    bueno: Color(0xFF86C79A),
    aviso: Color(0xFFE0A45B),
    serio: Color(0xFFE08B5B),
    critico: Color(0xFFE2647E),
    serie: [
      Color(0xFFD1734A),
      Color(0xFF3FB8AE),
      Color(0xFF7C8CD4),
      Color(0xFFE0A45B),
      Color(0xFF86C79A),
      Color(0xFFE38BA2),
      Color(0xFF6FD6CE),
      Color(0xFFEFA97D),
    ],
  );

  /// Color de una categoria a partir del hex que guarda el catalogo.
  static Color desdeHex(String hex, {Color respaldo = const Color(0xFFA19786)}) {
    var h = hex.replaceAll('#', '').trim();
    if (h.length == 6) h = 'FF$h';
    if (h.length != 8) return respaldo;
    final v = int.tryParse(h, radix: 16);
    return v == null ? respaldo : Color(v);
  }
}

/// Acceso a los tokens desde cualquier widget.
extension TokensDeContexto on BuildContext {
  Tokens get tokens => Theme.of(this).brightness == Brightness.dark
      ? Tokens.oscuro
      : Tokens.claro;

  TextTheme get texto => Theme.of(this).textTheme;
}

/// Las dos familias del prototipo. Sora para titulares y cifras, Manrope para
/// el texto corrido. Van empaquetadas en assets/fonts: ver pubspec.
const String fuenteTitular = 'Sora';
const String fuenteTexto = 'Manrope';

/// Verde de marca para superficies llenas: la portada del resumen, el boton
/// flotante, la insignia del cajon.
///
/// Es el mismo en los dos temas, y por eso no sale de los tokens. Encima va
/// texto crema, asi que no puede aclararse en oscuro como si hace `marca`:
/// quedaria crema sobre menta y no se leeria.
const Color verdeLleno = Color(0xFF1E5A37);

/// El crema que va encima de `verdeLleno`. Blanco puro sobre este verde se ve
/// frio al lado del resto de la paleta.
const Color cremaSobreVerde = Color(0xFFF5EAD8);

/// Radios del prototipo: contenedores de 28 a 36, controles tipo pastilla.
/// "Nada con esquina viva."
const double radioTarjeta = 28;
const double radioCampo = 18;
const double radioPastilla = 999;

ThemeData construirTema(Brightness brillo) {
  final t = brillo == Brightness.dark ? Tokens.oscuro : Tokens.claro;

  final base = ThemeData(
    useMaterial3: true,
    brightness: brillo,
    fontFamily: fuenteTexto,
    colorScheme: ColorScheme.fromSeed(
      seedColor: t.marca,
      brightness: brillo,
    ).copyWith(
      primary: t.marca,
      surface: t.plano,
      onSurface: t.tinta,
    ),
    scaffoldBackgroundColor: t.plano,
  );

  // Tabular figures: sin esto los montos bailan de ancho al actualizarse y una
  // columna de numeros se ve torcida.
  const tabular = [FontFeature.tabularFigures()];

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(
        fontFamily: fuenteTitular,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.9,
        color: t.tinta,
        fontFeatures: tabular,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontFamily: fuenteTitular,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: t.tinta,
        fontFeatures: tabular,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontFamily: fuenteTitular,
        fontWeight: FontWeight.w600,
        color: t.tinta,
      ),
      titleSmall: base.textTheme.titleSmall?.copyWith(
        fontFamily: fuenteTitular,
        fontWeight: FontWeight.w600,
        color: t.tinta,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(color: t.tinta2),
      bodySmall: base.textTheme.bodySmall?.copyWith(color: t.apagado),
      labelSmall: base.textTheme.labelSmall?.copyWith(
        color: t.apagado,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: t.plano,
      surfaceTintColor: Colors.transparent,
      foregroundColor: t.tinta,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: fuenteTitular,
        color: t.tinta,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
    ),
    cardTheme: CardThemeData(
      color: t.superficie,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radioTarjeta),
        side: BorderSide(color: t.borde),
      ),
    ),
    dividerTheme: DividerThemeData(color: t.borde, space: 1, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: t.superficie2,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radioCampo),
        borderSide: BorderSide(color: t.borde),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radioCampo),
        borderSide: BorderSide(color: t.borde),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radioCampo),
        borderSide: BorderSide(color: t.marca, width: 1.6),
      ),
      labelStyle: TextStyle(color: t.apagado),
      hintStyle: TextStyle(color: t.apagado),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: t.marca,
        foregroundColor: t.plano,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radioPastilla),
        ),
        textStyle: const TextStyle(
          fontFamily: fuenteTexto,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: t.tinta,
        side: BorderSide(color: t.borde),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radioPastilla),
        ),
        textStyle: const TextStyle(
          fontFamily: fuenteTexto,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: t.marca),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: t.superficie,
      surfaceTintColor: Colors.transparent,
      indicatorColor: t.marca.withValues(alpha: 0.16),
      height: 68,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.tinta2),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: t.superficie2,
      side: BorderSide(color: t.borde),
      labelStyle: TextStyle(color: t.tinta2, fontSize: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radioPastilla),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: t.tinta,
      contentTextStyle: TextStyle(color: t.plano),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radioCampo),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: t.superficie,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radioTarjeta)),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: t.apagado,
      titleTextStyle: TextStyle(
        fontFamily: fuenteTexto,
        color: t.tinta,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      subtitleTextStyle: TextStyle(color: t.apagado, fontSize: 13),
    ),
  );
}
