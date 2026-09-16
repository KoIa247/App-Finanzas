import 'texto.dart';

/// Convierte `"S/ 1,465.44"`, `"$ 77.71"` o `"1.465,44"` en 1465.44.
///
/// Devuelve null si no encuentra un numero valido. La ambiguedad entre el
/// separador de miles y el decimal se resuelve igual que en el sistema
/// original: gana el ultimo separador que aparece, y "1.465" se lee como miles
/// mientras que "12.50" se lee como decimal.
double? parsearImporte(Object? txt) {
  if (txt == null) return null;
  if (txt is num) return txt.toDouble();
  final crudo = txt.toString().replaceAll(invisibles, '');
  if (crudo.isEmpty) return null;

  final m = RegExp(r'-?\d[\d.,]*').firstMatch(crudo);
  if (m == null) return null;
  var n = m.group(0)!;

  final tieneComa = n.contains(',');
  final tienePunto = n.contains('.');

  if (tieneComa && tienePunto) {
    // El separador decimal es el ultimo que aparece.
    n = n.lastIndexOf(',') > n.lastIndexOf('.')
        ? n.replaceAll('.', '').replaceFirst(',', '.')
        : n.replaceAll(',', '');
  } else if (tieneComa) {
    // "1,465" es miles; "12,50" es decimal.
    n = RegExp(r',\d{3}(\D|$)').hasMatch('$n ')
        ? n.replaceAll(',', '')
        : n.replaceFirst(',', '.');
  } else if (tienePunto) {
    // Solo puntos: "1.465" miles vs "12.50" decimal.
    final partes = n.split('.');
    if (partes.length > 2) {
      n = n.replaceAll('.', '');
    } else if (partes.length == 2 &&
        partes[1].length == 3 &&
        partes[0].length <= 3) {
      n = n.replaceAll('.', '');
    }
  }
  return double.tryParse(n);
}

/// Detecta la moneda en un texto tipo "S/ 61.52" o "$ 4.84".
String detectarMoneda(Object? txt, [String porDefecto = 'PEN']) {
  final s = norm(txt);
  if (RegExp(r'US\$|USD|\$').hasMatch(s) && !RegExp(r'S/\s*\d').hasMatch(s)) {
    return 'USD';
  }
  if (RegExp(r'S/|PEN|SOLES').hasMatch(s)) return 'PEN';
  if (s.contains(r'$')) return 'USD';
  return porDefecto;
}

/// Redondea a [dec] decimales.
double redondear(num n, [int dec = 2]) {
  final f = _pow10(dec);
  return (n * f).round() / f;
}

double _pow10(int e) {
  var r = 1.0;
  for (var i = 0; i < e; i++) {
    r *= 10;
  }
  return r;
}
