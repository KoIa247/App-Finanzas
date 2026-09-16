import 'texto.dart';

/// Meses en castellano, completos y abreviados, tal como los escribe el BCP.
const Map<String, int> mesesEs = {
  'ENERO': 0, 'FEBRERO': 1, 'MARZO': 2, 'ABRIL': 3, 'MAYO': 4, 'JUNIO': 5,
  'JULIO': 6, 'AGOSTO': 7, 'SETIEMBRE': 8, 'SEPTIEMBRE': 8, 'OCTUBRE': 9,
  'NOVIEMBRE': 10, 'DICIEMBRE': 11,
  'ENE': 0, 'FEB': 1, 'MAR': 2, 'ABR': 3, 'MAY': 4, 'JUN': 5, 'JUL': 6,
  'AGO': 7, 'SET': 8, 'SEP': 8, 'OCT': 9, 'NOV': 10, 'DIC': 11,
};

const List<String> mesesCortos = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'set', 'oct', 'nov', 'dic',
];

const List<String> mesesLargos = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'setiembre', 'octubre', 'noviembre', 'diciembre',
];

/// Resultado de leer una fecha del correo.
class FechaHora {
  const FechaHora(this.fecha, this.hora);

  /// Formato `yyyy-MM-dd`.
  final String fecha;

  /// Formato `HH:mm`.
  final String hora;
}

/// Parsea las fechas que usa el BCP.
///
/// Formatos soportados:
///   "29 de julio de 2026 - 09:32 PM"
///   "Lunes, 26 Enero 2026 - 08:36 AM"
///   "03/12/2025 - 01:52 PM"
///   "16/06/2026 14:20"
///   "2026-06-16 14:20"
FechaHora? parsearFechaHora(Object? txt) {
  if (txt == null) return null;
  final s = limpiar(txt.toString()).replaceAll('\u00A0', ' ');
  if (s.isEmpty) return null;

  int? dia;
  int? mes;
  int? anio;

  final conNombre = RegExp(
    r'(\d{1,2})\s*(?:de\s+)?([A-Za-z\u00C0-\u00FF]{3,12})\s*(?:de\s+)?(\d{4})',
  ).firstMatch(s);
  if (conNombre != null) {
    final nm = norm(conNombre.group(2));
    if (mesesEs.containsKey(nm)) {
      dia = int.tryParse(conNombre.group(1)!);
      mes = mesesEs[nm];
      anio = int.tryParse(conNombre.group(3)!);
    }
  }

  if (dia == null) {
    final barras = RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})').firstMatch(s);
    if (barras != null) {
      dia = int.tryParse(barras.group(1)!);
      mes = (int.tryParse(barras.group(2)!) ?? 1) - 1;
      anio = int.tryParse(barras.group(3)!);
    }
  }

  if (dia == null) {
    final iso = RegExp(r'(\d{4})-(\d{2})-(\d{2})').firstMatch(s);
    if (iso != null) {
      anio = int.tryParse(iso.group(1)!);
      mes = (int.tryParse(iso.group(2)!) ?? 1) - 1;
      dia = int.tryParse(iso.group(3)!);
    }
  }

  if (dia == null || mes == null || anio == null) return null;

  var hh = 0;
  var mi = 0;
  final h = RegExp(
    r'(\d{1,2}):(\d{2})(?::\d{2})?\s*(AM|PM|a\.m\.|p\.m\.)?',
    caseSensitive: false,
  ).firstMatch(s);
  if (h != null) {
    hh = int.tryParse(h.group(1)!) ?? 0;
    mi = int.tryParse(h.group(2)!) ?? 0;
    final ampm = h.group(3) == null ? '' : norm(h.group(3)).replaceAll('.', '');
    if (ampm == 'PM' && hh < 12) hh += 12;
    if (ampm == 'AM' && hh == 12) hh = 0;
  }

  return FechaHora(
    '${pad(anio, 4)}-${pad(mes + 1, 2)}-${pad(dia, 2)}',
    '${pad(hh, 2)}:${pad(mi, 2)}',
  );
}

/// Normaliza cualquier fecha a `yyyy-MM-dd`.
String normalizarFecha(Object? valor) {
  if (valor == null) return '';
  if (valor is DateTime) {
    return '${pad(valor.year, 4)}-${pad(valor.month, 2)}-${pad(valor.day, 2)}';
  }
  final s = valor.toString().trim();
  if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(s)) return s.substring(0, 10);
  return parsearFechaHora(s)?.fecha ?? '';
}

/// `2026-06-16` -> `2026-06`
String periodoDe(String fecha) =>
    fecha.length >= 7 ? fecha.substring(0, 7) : '';

/// Periodo del mes anterior. `2026-01` -> `2025-12`
String periodoAnterior(String periodo) {
  final p = periodo.split('-');
  if (p.length < 2) return periodo;
  var anio = int.tryParse(p[0]) ?? 0;
  var mes = (int.tryParse(p[1]) ?? 1) - 1;
  if (mes < 1) {
    mes = 12;
    anio--;
  }
  return '${pad(anio, 4)}-${pad(mes, 2)}';
}

String _periodoSiguiente(String periodo) {
  final p = periodo.split('-');
  if (p.length < 2) return periodo;
  var anio = int.tryParse(p[0]) ?? 0;
  var mes = (int.tryParse(p[1]) ?? 1) + 1;
  if (mes > 12) {
    mes = 1;
    anio++;
  }
  return '${pad(anio, 4)}-${pad(mes, 2)}';
}

/// Suma [n] meses (negativo para restar) a un periodo `yyyy-MM`.
String periodoSumar(String periodo, int n) {
  var r = periodo;
  for (var i = 0; i < n.abs(); i++) {
    r = n < 0 ? periodoAnterior(r) : _periodoSiguiente(r);
  }
  return r;
}

/// Dias que separan dos fechas `yyyy-MM-dd`.
int diasEntre(String a, String b) {
  final da = DateTime.tryParse(normalizarFecha(a));
  final db = DateTime.tryParse(normalizarFecha(b));
  if (da == null || db == null) return 0;
  return db.difference(da).inDays.abs();
}

/// Cuantos dias tiene ese mes. Contempla anios bisiestos.
int diasDelMes(int anio, int mes) {
  const largos = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  if (mes == 2 && ((anio % 4 == 0 && anio % 100 != 0) || anio % 400 == 0)) {
    return 29;
  }
  return (mes >= 1 && mes <= 12) ? largos[mes - 1] : 30;
}

/// Peru no usa horario de verano, asi que UTC-5 fijo es exacto todo el anio.
DateTime _ahoraLima() => DateTime.now().toUtc().subtract(const Duration(hours: 5));

/// Hoy en Lima, como `yyyy-MM-dd`.
String hoyLima() {
  final d = _ahoraLima();
  return '${pad(d.year, 4)}-${pad(d.month, 2)}-${pad(d.day, 2)}';
}

/// Hora actual de Lima como `HH:mm`.
String horaLima() {
  final d = _ahoraLima();
  return '${pad(d.hour, 2)}:${pad(d.minute, 2)}';
}

/// Marca de tiempo completa de Lima, `yyyy-MM-dd HH:mm:ss`.
String ahoraLima() {
  final d = _ahoraLima();
  return '${pad(d.year, 4)}-${pad(d.month, 2)}-${pad(d.day, 2)} '
      '${pad(d.hour, 2)}:${pad(d.minute, 2)}:${pad(d.second, 2)}';
}

/// Periodo actual `yyyy-MM` en Lima.
String periodoActual() => hoyLima().substring(0, 7);

/// "2026-06" -> "junio 2026"
String periodoLegible(String periodo) {
  final p = periodo.split('-');
  if (p.length < 2) return periodo;
  final mes = int.tryParse(p[1]) ?? 1;
  return '${mesesLargos[(mes - 1).clamp(0, 11)]} ${p[0]}';
}

/// "2026-06" -> "jun 2026"
String periodoCorto(String periodo) {
  final p = periodo.split('-');
  if (p.length < 2) return periodo;
  final mes = int.tryParse(p[1]) ?? 1;
  return '${mesesCortos[(mes - 1).clamp(0, 11)]} ${p[0]}';
}

/// "2026-06-16" -> "16 jun"
String fechaCorta(String fecha) {
  final f = normalizarFecha(fecha);
  if (f.length < 10) return fecha;
  final mes = int.tryParse(f.substring(5, 7)) ?? 1;
  final dia = int.tryParse(f.substring(8, 10)) ?? 1;
  return '$dia ${mesesCortos[(mes - 1).clamp(0, 11)]}';
}
