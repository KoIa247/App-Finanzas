import 'package:flutter/material.dart';

/// Los colores del sistema, tomados del prototipo de Leep.
///
/// Es una paleta calida de papel, no el gris azulado de Material por defecto:
/// una app que miras todos los dias para ver malas noticias sobre tu plata
/// agradece verse tranquila.
///
/// Los dos temas salen del prototipo, que trae los suyos completos en
/// `[data-tema="claro"]` y `[data-tema="oscuro"]`. Los valores de aqui son
/// esos, no una derivacion: la paleta se llama "musgo" y el pliego la fija
/// token por token, incluido el verde de la portada, que en oscuro se
/// ensombrece en vez de aclararse porque encima siempre va texto claro.
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
    required this.marcaTinta,
    required this.portada,
    required this.portadaTinta,
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

  /// El verde de Leep para rellenos: botones, el flotante, la insignia.
  final Color marca;

  /// Lo que va encima de [marca].
  final Color marcaTinta;

  /// El verde de la portada. En oscuro se ensombrece en vez de aclararse,
  /// porque encima siempre va texto claro.
  final Color portada;

  /// Lo que va encima de [portada].
  final Color portadaTinta;

  final Color bueno;
  final Color aviso;
  final Color serio;
  final Color critico;

  /// Paleta categorica para los graficos.
  final List<Color> serie;

  static const claro = Tokens(
    plano: Color(0xFFF5EAD8),
    superficie: Color(0xFFFBF5EC),
    superficie2: Color(0xFFEBDDC5),
    tinta: Color(0xFF201E1D),
    tinta2: Color(0xFF656260),
    apagado: Color(0xFF918D89),
    grilla: Color(0xFFDCD3C4),
    borde: Color(0x24201E1D),
    marca: Color(0xFF1E5A37),
    marcaTinta: Color(0xFFF5EAD8),
    portada: Color(0xFF1E5A37),
    portadaTinta: Color(0xFFF5EAD8),
    bueno: Color(0xFF1E5A37),
    aviso: Color(0xFF8C491A),
    serio: Color(0xFF9E4420),
    critico: Color(0xFF93122E),
    // Las seis paletas del pliego, en su tono claro.
    serie: [
      Color(0xFF1E5A37),
      Color(0xFF0A6360),
      Color(0xFF9E4420),
      Color(0xFF93122E),
      Color(0xFF22306B),
      Color(0xFF33383A),
    ],
  );

  static const oscuro = Tokens(
    plano: Color(0xFF0F1011),
    superficie: Color(0xFF1A1B1D),
    superficie2: Color(0xFF242628),
    tinta: Color(0xFFF1EFEB),
    tinta2: Color(0xFFB5B1AA),
    apagado: Color(0xFF8A8883),
    grilla: Color(0xFF303235),
    borde: Color(0x24F1EFEB),
    marca: Color(0xFF86C79A),
    marcaTinta: Color(0xFF16210F),
    portada: Color(0xFF12391F),
    portadaTinta: Color(0xFFF1EFEB),
    bueno: Color(0xFF9FD4AD),
    aviso: Color(0xFFE0A87E),
    serio: Color(0xFFE0A87E),
    critico: Color(0xFFE39AAC),
    // Las mismas seis paletas, en su tono oscuro.
    serie: [
      Color(0xFF9FD4AD),
      Color(0xFF7FD3CC),
      Color(0xFFE0A87E),
      Color(0xFFE39AAC),
      Color(0xFF9DAEEA),
      Color(0xFFB9C0C4),
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
        foregroundColor: t.marcaTinta,
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
