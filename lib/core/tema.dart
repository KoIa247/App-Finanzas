import 'package:flutter/material.dart';

/// Los colores del sistema, tomados del prototipo.
///
/// Es una paleta calida de papel, no el gris azulado de Material por defecto:
/// una app que miras todos los dias para ver malas noticias sobre tu plata
/// agradece verse tranquila.
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

  final Color bueno;
  final Color aviso;
  final Color serio;
  final Color critico;

  /// Paleta categorica para los graficos.
  final List<Color> serie;

  static const claro = Tokens(
    plano: Color(0xFFF9F9F7),
    superficie: Color(0xFFFCFCFB),
    superficie2: Color(0xFFF2F2EF),
    tinta: Color(0xFF0B0B0B),
    tinta2: Color(0xFF52514E),
    apagado: Color(0xFF898781),
    grilla: Color(0xFFE1E0D9),
    borde: Color(0x1A0B0B0B),
    bueno: Color(0xFF0CA30C),
    aviso: Color(0xFFFAB219),
    serio: Color(0xFFEC835A),
    critico: Color(0xFFD03B3B),
    serie: [
      Color(0xFF2A78D6),
      Color(0xFFEB6834),
      Color(0xFF1BAF7A),
      Color(0xFFEDA100),
      Color(0xFFE87BA4),
      Color(0xFF008300),
      Color(0xFF4A3AA7),
      Color(0xFFE34948),
    ],
  );

  static const oscuro = Tokens(
    plano: Color(0xFF0D0D0D),
    superficie: Color(0xFF1A1A19),
    superficie2: Color(0xFF242422),
    tinta: Color(0xFFFFFFFF),
    tinta2: Color(0xFFC3C2B7),
    apagado: Color(0xFF898781),
    grilla: Color(0xFF2C2C2A),
    borde: Color(0x1AFFFFFF),
    bueno: Color(0xFF0CA30C),
    aviso: Color(0xFFFAB219),
    serio: Color(0xFFEC835A),
    critico: Color(0xFFE66767),
    serie: [
      Color(0xFF3987E5),
      Color(0xFFD95926),
      Color(0xFF199E70),
      Color(0xFFC98500),
      Color(0xFFD55181),
      Color(0xFF008300),
      Color(0xFF9085E9),
      Color(0xFFE66767),
    ],
  );

  /// Color de una categoria a partir del hex que guarda el catalogo.
  static Color desdeHex(String hex, {Color respaldo = const Color(0xFF94A3B8)}) {
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

/// El azul de la marca.
const Color marca = Color(0xFF0A47F0);

ThemeData construirTema(Brightness brillo) {
  final t = brillo == Brightness.dark ? Tokens.oscuro : Tokens.claro;

  final base = ThemeData(
    useMaterial3: true,
    brightness: brillo,
    colorScheme: ColorScheme.fromSeed(
      seedColor: marca,
      brightness: brillo,
    ).copyWith(
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
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: t.tinta,
        fontFeatures: tabular,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: t.tinta,
        fontFeatures: tabular,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: t.tinta,
      ),
      titleSmall: base.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: t.tinta,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(color: t.tinta2),
      bodySmall: base.textTheme.bodySmall?.copyWith(color: t.apagado),
      labelSmall: base.textTheme.labelSmall?.copyWith(
        color: t.apagado,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
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
        color: t.tinta,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: t.superficie,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: t.borde),
      ),
    ),
    dividerTheme: DividerThemeData(color: t.borde, space: 1, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: t.superficie2,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: t.borde),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: t.borde),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: marca, width: 1.6),
      ),
      labelStyle: TextStyle(color: t.apagado),
      hintStyle: TextStyle(color: t.apagado),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: marca,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: t.tinta,
        side: BorderSide(color: t.borde),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: marca),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: t.superficie,
      surfaceTintColor: Colors.transparent,
      indicatorColor: marca.withValues(alpha: 0.12),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: t.tinta,
      contentTextStyle: TextStyle(color: t.plano),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: t.superficie,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: t.apagado,
      titleTextStyle: TextStyle(
        color: t.tinta,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      subtitleTextStyle: TextStyle(color: t.apagado, fontSize: 13),
    ),
  );
}
