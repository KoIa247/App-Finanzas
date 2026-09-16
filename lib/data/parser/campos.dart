import '../../core/texto.dart';

/// Convierte las tablas "Etiqueta | Valor" del correo en un mapa.
///
/// Las plantillas del BCP son 100% tablas, por eso este metodo es mucho mas
/// estable que buscar frases sueltas dentro del texto.
Map<String, String> extraerCamposTabla(String? html) {
  final map = <String, String>{};
  if (html == null || html.isEmpty) return map;

  final filas =
      RegExp(r'<tr[\s\S]*?</tr>', caseSensitive: false).allMatches(html);
  for (final fila in filas) {
    final celdas = RegExp(r'<td[\s\S]*?</td>', caseSensitive: false)
        .allMatches(fila.group(0)!)
        .toList();
    if (celdas.length < 2) continue;

    final etiqueta = norm(quitarTags(celdas[0].group(0), ' '));
    final valor = quitarTags(celdas[1].group(0), ' | ');
    if (etiqueta.isEmpty || etiqueta.length > 60) continue;
    if (valor.isEmpty || valor == '|') continue;
    map.putIfAbsent(etiqueta, () => valor);
  }
  return map;
}

/// Complementa con lineas del tipo "Etiqueta: Valor" (plantillas antiguas).
Map<String, String> extraerCamposInline(String? texto) {
  final map = <String, String>{};
  if (texto == null || texto.isEmpty) return map;

  for (final linea in texto.split('\n')) {
    final m = RegExp(
      r'^\s*([A-Za-zÀ-ÿ0-9º./ ]{3,45})\s*:\s*(.+?)\s*$',
    ).firstMatch(linea);
    if (m == null) continue;
    final k = norm(m.group(1));
    if (k.isEmpty || map.containsKey(k)) continue;
    map[k] = limpiar(m.group(2));
  }
  return map;
}

/// Busca el primer campo existente entre varios nombres posibles.
String campo(Map<String, String> map, List<String> nombres) {
  for (final nombre in nombres) {
    final v = map[norm(nombre)];
    if (v != null && v.isNotEmpty) return v;
  }
  return '';
}

/// Nombre y ultimos 4 digitos de una cuenta.
class CuentaTexto {
  const CuentaTexto(this.nombre, this.ultimos4);

  final String nombre;
  final String ultimos4;
}

/// `"VISA Oro | **** 3496"` -> nombre "VISA Oro", ultimos4 "3496".
CuentaTexto partirCuenta(String? valor) {
  final v = limpiar(valor);
  if (v.isEmpty) return const CuentaTexto('', '');

  var u4 = '';
  final conAsterisco = RegExp(r'(?:\*+\s*)(\d{4})(?!\d)').firstMatch(v);
  if (conAsterisco != null) {
    u4 = conAsterisco.group(1)!;
  } else if (v.contains('*')) {
    final ultimo = RegExp(r'(\d{4})(?!.*\d)').firstMatch(v);
    if (ultimo != null) u4 = ultimo.group(1)!;
  }

  var nombre = v.split('|').first;
  nombre = nombre
      .replaceAll(RegExp(r'\*+\s*\d{2,4}'), '')
      .replaceAll(RegExp(r'Moneda\s+\w+', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s*\|\s*'), ' ');
  return CuentaTexto(limpiar(nombre), u4);
}

/// Limpia el nombre de comercio que llega del banco.
String limpiarComercio(String? txt) {
  var s = limpiar(txt);
  s = s.replaceAll(RegExp(r'\s*\|\s*'), ' ');
  s = s.replaceAll(RegExp(r'\.$'), '');
  return limpiar(s);
}

/// Une los campos de tabla con los inline, sin que los inline pisen a la tabla.
Map<String, String> camposDelCorreo(String html, String texto) {
  final f = extraerCamposTabla(html);
  final inline = extraerCamposInline(texto);
  inline.forEach((k, v) => f.putIfAbsent(k, () => v));
  return f;
}
