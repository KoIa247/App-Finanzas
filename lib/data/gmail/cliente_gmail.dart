import 'dart:convert';

import 'package:http/http.dart' as http;

import 'autenticacion.dart';

/// Un correo ya descargado y desarmado.
class MensajeGmail {
  const MensajeGmail({
    required this.id,
    required this.threadId,
    required this.remitente,
    required this.asunto,
    required this.fecha,
    required this.html,
    required this.texto,
  });

  final String id;
  final String threadId;
  final String remitente;
  final String asunto;
  final DateTime fecha;
  final String html;
  final String texto;
}

/// Cliente minimo de la API de Gmail.
///
/// Se habla REST a mano en vez de traer el paquete `googleapis` entero: son
/// dos endpoints, y mantener la superficie chica hace que la revision de
/// seguridad de Google sea mucho mas facil de argumentar.
class ClienteGmail {
  ClienteGmail(this._auth, {http.Client? cliente})
      : _http = cliente ?? http.Client();

  final AutenticacionGmail _auth;
  final http.Client _http;

  static const _base = 'https://gmail.googleapis.com/gmail/v1/users/me';

  /// Busca los ids de los mensajes que calzan con [consulta].
  ///
  /// [tope] corta la corrida: Gmail pagina de 100 en 100 y una bandeja con
  /// anios de correos agotaria la cuota en una sola sincronizacion.
  Future<List<String>> buscar(String consulta, {int tope = 150}) async {
    final cab = await _auth.cabeceras();
    if (cab == null) return const [];

    final ids = <String>[];
    String? pagina;

    do {
      final uri = Uri.parse('$_base/messages').replace(queryParameters: {
        'q': consulta,
        'maxResults': '100',
        if (pagina != null) 'pageToken': pagina,
      });
      final r = await _http.get(uri, headers: cab).timeout(
            const Duration(seconds: 30),
          );
      if (r.statusCode != 200) {
        throw GmailExcepcion(r.statusCode, r.body);
      }
      final json = jsonDecode(r.body) as Map<String, dynamic>;
      final lista = (json['messages'] as List?) ?? const [];
      for (final m in lista) {
        ids.add((m as Map)['id'] as String);
        if (ids.length >= tope) return ids;
      }
      pagina = json['nextPageToken'] as String?;
    } while (pagina != null && ids.length < tope);

    return ids;
  }

  /// Descarga un mensaje completo y lo desarma.
  Future<MensajeGmail?> mensaje(String id) async {
    final cab = await _auth.cabeceras();
    if (cab == null) return null;

    final uri = Uri.parse('$_base/messages/$id')
        .replace(queryParameters: {'format': 'full'});
    final r =
        await _http.get(uri, headers: cab).timeout(const Duration(seconds: 30));
    if (r.statusCode != 200) throw GmailExcepcion(r.statusCode, r.body);

    final json = jsonDecode(r.body) as Map<String, dynamic>;
    final payload = (json['payload'] as Map<String, dynamic>?) ?? const {};
    final cabeceras = _cabeceras(payload);

    final cuerpos = <String, String>{};
    _recorrer(payload, cuerpos);

    final ms = int.tryParse('${json['internalDate']}') ?? 0;
    return MensajeGmail(
      id: (json['id'] ?? id) as String,
      threadId: (json['threadId'] ?? '') as String,
      remitente: _correoDe(cabeceras['from'] ?? ''),
      asunto: cabeceras['subject'] ?? '',
      fecha: ms > 0
          ? DateTime.fromMillisecondsSinceEpoch(ms)
          : DateTime.now(),
      html: cuerpos['text/html'] ?? '',
      texto: cuerpos['text/plain'] ?? '',
    );
  }

  Map<String, String> _cabeceras(Map<String, dynamic> payload) {
    final out = <String, String>{};
    for (final h in (payload['headers'] as List?) ?? const []) {
      final m = h as Map;
      out[(m['name'] as String).toLowerCase()] = (m['value'] ?? '') as String;
    }
    return out;
  }

  /// Recorre el arbol MIME y se queda con el primer cuerpo de cada tipo.
  ///
  /// Los correos de los bancos son multipart/alternative: traen una version en
  /// texto y otra en HTML del mismo aviso. Se guardan las dos porque el parser
  /// usa la tabla del HTML y cae al texto cuando la plantilla no es tabular.
  void _recorrer(Map<String, dynamic> parte, Map<String, String> out) {
    final mime = (parte['mimeType'] ?? '') as String;
    final body = parte['body'] as Map<String, dynamic>?;
    final datos = body?['data'] as String?;

    if (datos != null && datos.isNotEmpty && !out.containsKey(mime)) {
      final decodificado = _decodificar(datos);
      if (decodificado.isNotEmpty) out[mime] = decodificado;
    }

    for (final hijo in (parte['parts'] as List?) ?? const []) {
      _recorrer(hijo as Map<String, dynamic>, out);
    }
  }

  /// Gmail codifica en base64url y omite el relleno.
  String _decodificar(String datos) {
    try {
      var s = datos.replaceAll('-', '+').replaceAll('_', '/');
      final resto = s.length % 4;
      if (resto > 0) s = s.padRight(s.length + (4 - resto), '=');
      return utf8.decode(base64.decode(s), allowMalformed: true);
    } catch (_) {
      return '';
    }
  }

  /// `"Notificaciones BCP <notificaciones@bcp.com.pe>"` -> el correo solo.
  String _correoDe(String from) {
    final m = RegExp(r'<([^>]+)>').firstMatch(from);
    return (m != null ? m.group(1)! : from).trim().toLowerCase();
  }
}

class GmailExcepcion implements Exception {
  const GmailExcepcion(this.codigo, this.cuerpo);

  final int codigo;
  final String cuerpo;

  /// 401 y 403 son "tu sesion caduco o te falta el permiso", no un error de red.
  bool get esDePermisos => codigo == 401 || codigo == 403;

  @override
  String toString() => esDePermisos
      ? 'Gmail rechazo el acceso ($codigo). Vuelve a conectar tu cuenta.'
      : 'Gmail respondio $codigo';
}
