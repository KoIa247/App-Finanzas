import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/fechas.dart';
import '../repos/dao.dart';

/// Tipo de cambio USD/PEN.
///
/// El orden de preferencia es deliberado: primero lo que ya esta guardado (un
/// gasto de marzo tiene que valuarse con el TC de marzo, no con el de hoy),
/// despues la red, y al final el valor de respaldo. Nunca se falla: un importe
/// sin convertir rompe todas las sumas del mes.
class ServicioTipoCambio {
  ServicioTipoCambio(this._dao, {http.Client? cliente})
      : _http = cliente ?? http.Client();

  final Dao _dao;
  final http.Client _http;

  /// Cache en memoria de la corrida, para no consultar la base por cada correo.
  final Map<String, double> _cache = {};

  /// TC aplicable a una fecha. [respaldo] sale de la configuracion.
  Future<double> para(String fecha, {double respaldo = 3.75}) async {
    final f = normalizarFecha(fecha);
    final enCache = _cache[f];
    if (enCache != null) return enCache;

    final guardado = await _dao.tipoCambioDe(f);
    if (guardado != null) {
      _cache[f] = guardado;
      return guardado;
    }

    // Solo se sale a la red por el TC de hoy. Reconstruir el historico de un
    // dia cualquiera no lo ofrecen las fuentes gratuitas, y adivinarlo con el
    // valor de hoy seria peor que usar el respaldo.
    if (f == hoyLima()) {
      final vivo = await actualizar();
      if (vivo != null) {
        _cache[f] = vivo;
        return vivo;
      }
    }

    _cache[f] = respaldo;
    return respaldo;
  }

  /// Convierte un importe a soles.
  Future<double> aSoles(
    double importe,
    String moneda, {
    required String fecha,
    double? tipoCambio,
    double respaldo = 3.75,
  }) async {
    if (moneda.toUpperCase() == 'PEN') return importe;
    final tc = tipoCambio ?? await para(fecha, respaldo: respaldo);
    return importe * tc;
  }

  /// Busca el TC de hoy y lo guarda. Devuelve null si no hubo forma.
  Future<double?> actualizar() async {
    for (final fuente in _fuentes) {
      try {
        final tc = await fuente.leer(_http);
        if (tc != null && tc > 1 && tc < 10) {
          await _dao.guardarTipoCambio(
            fecha: hoyLima(),
            compra: tc,
            venta: tc,
            fuente: fuente.nombre,
          );
          _cache[hoyLima()] = tc;
          return tc;
        }
      } catch (_) {
        // Se intenta con la siguiente fuente. Que falle el TC no puede tumbar
        // la sincronizacion entera.
      }
    }
    return null;
  }
}

/// Una fuente de tipo de cambio.
class _FuenteTc {
  const _FuenteTc(this.nombre, this.url, this.extraer);

  final String nombre;
  final String url;
  final double? Function(Map<String, dynamic>) extraer;

  Future<double?> leer(http.Client cliente) async {
    final r = await cliente
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 10));
    if (r.statusCode != 200) return null;
    final json = jsonDecode(r.body);
    if (json is! Map<String, dynamic>) return null;
    return extraer(json);
  }
}

/// Saca `rates.PEN` de la respuesta. Las dos fuentes usan la misma forma.
double? _penDeRates(Map<String, dynamic> json) {
  final rates = json['rates'];
  if (rates is! Map) return null;
  final pen = rates['PEN'];
  return pen is num ? pen.toDouble() : null;
}

/// Fuentes gratuitas y sin llave. Se prueban en orden.
const List<_FuenteTc> _fuentes = [
  _FuenteTc(
    'open.er-api.com',
    'https://open.er-api.com/v6/latest/USD',
    _penDeRates,
  ),
  _FuenteTc(
    'frankfurter.app',
    'https://api.frankfurter.app/latest?from=USD&to=PEN',
    _penDeRates,
  ),
];
