/// Utilidades de texto. Port directo de `norm_`, `limpiar_`, `quitarTags_` y
/// `htmlATexto_` del sistema original en Apps Script.
///
/// Son la base de todo el parser: el BCP inserta caracteres de ancho cero
/// dentro de sus plantillas, y sin limpiarlos las comparaciones fallan de
/// formas que no se ven a simple vista.
library;

/// Caracteres invisibles que el BCP mete dentro del HTML de sus correos.
/// Espacios de ancho cero, marca de orden de bytes y guion blando.
final RegExp invisibles = RegExp(r'[\u200B-\u200D\uFEFF\u00AD]');

final RegExp _espacios = RegExp(r'\s+');

/// Equivalencias para quitar acentos, por punto de codigo. Dart no trae
/// `normalize('NFD')`, asi que la tabla es explicita. Cubre el castellano, que
/// es lo unico que mandan los bancos peruanos.
const Map<int, String> _acentos = {
  0xE1: 'a', 0xE9: 'e', 0xED: 'i', 0xF3: 'o', 0xFA: 'u', 0xFC: 'u',
  0xF1: 'n', 0xE0: 'a', 0xE8: 'e', 0xEC: 'i', 0xF2: 'o', 0xF9: 'u',
  0xE2: 'a', 0xEA: 'e', 0xEE: 'i', 0xF4: 'o', 0xFB: 'u',
  0xC1: 'A', 0xC9: 'E', 0xCD: 'I', 0xD3: 'O', 0xDA: 'U', 0xDC: 'U',
  0xD1: 'N', 0xC0: 'A', 0xC8: 'E', 0xCC: 'I', 0xD2: 'O', 0xD9: 'U',
};

String _quitarAcentos(String s) {
  final b = StringBuffer();
  for (final unidad in s.runes) {
    b.write(_acentos[unidad] ?? String.fromCharCode(unidad));
  }
  return b.toString();
}

/// Quita acentos, pasa a mayusculas y colapsa espacios. Para comparar.
String norm(Object? txt) {
  if (txt == null) return '';
  final s = _quitarAcentos(txt.toString().replaceAll(invisibles, ''));
  return s.replaceAll(_espacios, ' ').trim().toUpperCase();
}

/// Igual que [norm] pero conserva mayusculas y minusculas y los acentos.
String limpiar(Object? txt) {
  if (txt == null) return '';
  return txt
      .toString()
      .replaceAll(invisibles, '')
      .replaceAll(_espacios, ' ')
      .trim();
}

const Map<String, String> _entidadesHtml = {
  '&nbsp;': ' ',
  '&amp;': '&',
  '&lt;': '<',
  '&gt;': '>',
  '&quot;': '"',
  '&#39;': "'",
  '&apos;': "'",
  '&aacute;': 'a',
  '&eacute;': 'e',
  '&iacute;': 'i',
  '&oacute;': 'o',
  '&uacute;': 'u',
  '&ntilde;': 'n',
  '&uuml;': 'u',
  '&hellip;': '...',
  '&mdash;': '-',
  '&ndash;': '-',
};

String decodificarHtml(String? s) {
  if (s == null || s.isEmpty) return '';
  var out = s.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
    final code = int.tryParse(m.group(1)!);
    return code == null ? ' ' : String.fromCharCode(code);
  });
  out = out.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) {
    final code = int.tryParse(m.group(1)!, radix: 16);
    return code == null ? ' ' : String.fromCharCode(code);
  });
  return out.replaceAllMapped(RegExp(r'&[a-zA-Z#0-9]+;'), (m) {
    final e = m.group(0)!;
    return _entidadesHtml[e] ?? _entidadesHtml[e.toLowerCase()] ?? ' ';
  });
}

/// Quita etiquetas HTML de un fragmento y devuelve texto limpio.
String quitarTags(String? html, [String separadorBr = ' ']) {
  if (html == null || html.isEmpty) return '';
  var s =
      html.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), separadorBr);
  s = s.replaceAll(RegExp(r'<[^>]*>'), '');
  return limpiar(decodificarHtml(s));
}

/// Convierte el HTML completo de un correo a texto plano preservando los
/// saltos logicos. Se usa para las plantillas que no vienen como tabla.
String htmlATexto(String? html) {
  if (html == null || html.isEmpty) return '';
  var s = html;
  s = s.replaceAll(
      RegExp(r'<(script|style|head)[\s\S]*?</\1>', caseSensitive: false), ' ');
  s = s.replaceAll(RegExp(r'<!--[\s\S]*?-->'), ' ');
  s = s.replaceAll(
      RegExp(r'</(p|div|tr|h[1-6]|li)>', caseSensitive: false), '\n');
  s = s.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  s = s.replaceAll(RegExp(r'</td>', caseSensitive: false), ' \t ');
  s = s.replaceAll(RegExp(r'<[^>]*>'), '');
  s = decodificarHtml(s);
  s = s.replaceAll(invisibles, '');
  s = s
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\n{2,}'), '\n')
      .replaceAll(RegExp(r' ?\n ?'), '\n');
  return s.trim();
}

/// Rellena con ceros a la izquierda. Equivalente a `pad_`.
String pad(int n, int largo) {
  final s = n.abs().toString().padLeft(largo, '0');
  return n < 0 ? '-$s' : s;
}
