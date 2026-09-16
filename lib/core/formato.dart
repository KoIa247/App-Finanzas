import 'package:intl/intl.dart';

/// Formatos de moneda y numero para Peru.
///
/// El sol se escribe "S/ 1,234.56": simbolo delante, coma para miles y punto
/// para decimales, igual que en ingles. Escribirlo al reves es el error
/// clasico de quien asume que todo Latinoamerica usa el formato europeo.
///
/// El locale de intl para 'es_PE' NO da ese formato: devuelve "1.234,56 S/",
/// con el simbolo detras y los separadores cambiados, que es como se escribe
/// en Espana. Por eso se usa la maquinaria numerica de 'en_US', que coincide
/// exactamente con la convencion peruana, y se le pone el simbolo a mano.
final NumberFormat _soles =
    NumberFormat.currency(locale: 'en_US', symbol: 'S/ ', decimalDigits: 2);

final NumberFormat _dolares =
    NumberFormat.currency(locale: 'en_US', symbol: r'$ ', decimalDigits: 2);

final NumberFormat _compacto = NumberFormat('#,##0', 'en_US');

/// Formatea un monto con su simbolo.
String plata(num v, {String moneda = 'PEN', bool conDecimales = true}) {
  final f = moneda.toUpperCase() == 'USD' ? _dolares : _soles;
  if (conDecimales) return f.format(v);
  final simbolo = moneda.toUpperCase() == 'USD' ? r'$ ' : 'S/ ';
  return '$simbolo${_compacto.format(v)}';
}

/// Version corta para titulares: "S/ 12.4k".
String plataCorta(num v, {String moneda = 'PEN'}) {
  final simbolo = moneda.toUpperCase() == 'USD' ? r'$ ' : 'S/ ';
  final abs = v.abs();
  final signo = v < 0 ? '-' : '';
  if (abs >= 1000000) {
    return '$signo$simbolo${(abs / 1000000).toStringAsFixed(1)}M';
  }
  if (abs >= 10000) {
    return '$signo$simbolo${(abs / 1000).toStringAsFixed(1)}k';
  }
  return plata(v, moneda: moneda);
}

/// `0.847` -> `"85%"`
String porcentaje(num v, {int decimales = 0}) =>
    '${(v * 100).toStringAsFixed(decimales)}%';

/// Con signo explicito, para variaciones.
String porcentajeConSigno(num v, {int decimales = 1}) {
  final s = (v * 100).toStringAsFixed(decimales);
  return v >= 0 ? '+$s%' : '$s%';
}

String numero(num v) => _compacto.format(v);
