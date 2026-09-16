import 'bcp_parser.dart';
import 'contexto.dart';
import 'generico_parser.dart';

/// Registro de parsers disponibles, por nombre.
const Map<String, ResultadoParser Function(ContextoCorreo)> parsers = {
  'BCP': parsearBcp,
  'GENERICO': parsearGenerico,
};

/// Punto de entrada. Elige el parser segun el remitente y atrapa cualquier
/// fallo para que un correo raro no tumbe la sincronizacion entera.
ResultadoParser parsearMensaje(ContextoCorreo ctx) {
  final fn = parsers[ctx.parser] ?? parsearGenerico;
  try {
    return fn(ctx);
  } catch (e) {
    return ResultadoParser.error(e.toString());
  }
}
