import 'package:google_sign_in/google_sign_in.dart';

/// El unico permiso que pide la app sobre tu correo: leerlo.
///
/// `gmail.readonly` es un permiso restringido de Google. En consecuencia:
///   - durante el desarrollo y la beta funciona con hasta 100 usuarios de
///     prueba agregados a mano en Google Cloud Console;
///   - para publicar en tiendas hace falta la verificacion de OAuth mas una
///     evaluacion de seguridad anual (CASA).
///
/// La app NUNCA pide permiso de escritura, envio ni borrado. Si algun dia se
/// agrega el etiquetado de correos procesados hara falta `gmail.modify`, que
/// sube el nivel de la evaluacion: conviene pensarlo dos veces.
const String scopeGmail = 'https://www.googleapis.com/auth/gmail.readonly';

/// Sesion de Google del usuario.
class AutenticacionGmail {
  AutenticacionGmail({String? clientIdIos, String? serverClientId})
      : _google = GoogleSignIn(
          scopes: const [scopeGmail, 'email'],
          clientId: clientIdIos,
          serverClientId: serverClientId,
        );

  final GoogleSignIn _google;

  GoogleSignInAccount? get cuenta => _google.currentUser;

  bool get conectado => _google.currentUser != null;

  String get correo => _google.currentUser?.email ?? '';

  String get nombre => _google.currentUser?.displayName ?? '';

  String? get fotoUrl => _google.currentUser?.photoUrl;

  /// Reconecta en silencio si el usuario ya habia entrado antes. Se llama al
  /// arrancar: volver a mostrar la pantalla de login en cada apertura seria
  /// tratar al usuario como si nunca hubiera entrado.
  Future<bool> reconectar() async {
    try {
      final c = await _google.signInSilently();
      return c != null;
    } catch (_) {
      return false;
    }
  }

  /// Abre el dialogo de Google.
  Future<bool> entrar() async {
    try {
      final c = await _google.signIn();
      return c != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> salir() => _google.signOut();

  /// Quita el permiso por completo, no solo la sesion.
  Future<void> desconectar() async {
    try {
      await _google.disconnect();
    } catch (_) {
      await _google.signOut();
    }
  }

  /// Cabeceras autenticadas para hablar con la API de Gmail.
  ///
  /// Devuelve null si no hay sesion: el que llama decide si pedir login o
  /// simplemente no sincronizar.
  Future<Map<String, String>?> cabeceras() async {
    final c = _google.currentUser ?? await _google.signInSilently();
    if (c == null) return null;
    final auth = await c.authentication;
    final token = auth.accessToken;
    if (token == null || token.isEmpty) return null;
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }
}
