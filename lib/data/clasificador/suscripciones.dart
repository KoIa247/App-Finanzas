import 'dart:math' as math;

import '../../core/fechas.dart';
import '../../core/numeros.dart';
import '../../core/texto.dart';
import '../../domain/enums.dart';
import '../../domain/finanzas.dart';
import '../../domain/movimiento.dart';

/// Variacion maxima del importe para que un cargo parezca suscripcion.
const double subCvMax = 0.15;

/// Cargos por mes. Una suscripcion cobra ~1; un supermercado 4 o 5.
const double subCargosMesMax = 1.35;

/// Dias de desvio respecto al dia habitual del mes.
const int subDiaTolerancia = 6;

/// Sin cobrar por mas de esto, se considera posible baja.
const int subDiasInactiva = 45;

/// Detecta suscripciones a partir del historial de gastos.
///
/// Dos caminos independientes, en este orden:
///
///   1. POR REGLA. Si una regla marco el movimiento como recurrente (Netflix,
///      Spotify, Anthropic, Apple...), es una suscripcion y punto. Basta un
///      cargo: es una lista curada, no se adivina nada.
///
///   2. POR PATRON. Para lo que ninguna regla marco, se busca la firma de una
///      suscripcion: aparece en 3+ meses, cobra ~1 vez al mes, el importe casi
///      no cambia y siempre cerca del mismo dia. Los cuatro filtros juntos son
///      lo que separa Netflix de "voy a Wong todos los meses".
List<Suscripcion> detectarSuscripciones(
  List<Movimiento> movimientos, {
  String? hoy,
  List<String> forzadas = const [],
  List<String> excluidas = const [],
}) {
  final referencia = hoy ?? hoyLima();
  final si = forzadas.map(norm).where((x) => x.length >= 3).toList();
  final no = excluidas.map(norm).where((x) => x.length >= 3).toList();

  // Se agrupa por las dos primeras palabras del comercio: el banco agrega
  // sufijos distintos al mismo servicio de un mes a otro.
  final porComercio = <String, List<Movimiento>>{};
  for (final m in movimientos) {
    if (m.tipo != TipoMovimiento.gasto || !m.esVivo) continue;
    final k = norm(m.comercio).split(' ').take(2).join(' ');
    if (k.isEmpty) continue;
    porComercio.putIfAbsent(k, () => []).add(m);
  }

  final out = <Suscripcion>[];

  porComercio.forEach((clave, lista) {
    final meses = lista.map((m) => periodoDe(m.fecha)).toSet();
    final nMeses = meses.length;

    final importes = lista
        .map((m) => m.importePen != 0 ? m.importePen : m.importe)
        .toList(growable: false);
    final prom = importes.reduce((a, b) => a + b) / importes.length;
    final varianza = importes
            .map((x) => math.pow(x - prom, 2).toDouble())
            .reduce((a, b) => a + b) /
        importes.length;
    final cv = prom > 0 ? math.sqrt(varianza) / prom : 0.0;

    final dias = lista
        .map((m) => int.tryParse(normalizarFecha(m.fecha).substring(8, 10)) ?? 1)
        .toList(growable: false);

    // El dia del mes es circular: el 30 y el 1 estan a 1 dia, no a 29. Por eso
    // el promedio aritmetico no sirve (30 y 1 promedian 15). Se prueba cada dia
    // observado como referencia y gana el que deja a todos mas cerca.
    var diaHabitual = dias.first;
    var desvioDia = 99;
    for (final candidato in dias) {
      var peor = 0;
      for (final d in dias) {
        final dist = (candidato - d).abs();
        peor = math.max(peor, math.min(dist, 30 - dist));
      }
      if (peor < desvioDia) {
        desvioDia = peor;
        diaHabitual = candidato;
      }
    }

    final cargosPorMes = lista.length / math.max(nMeses, 1);
    final ultimoNombre = lista.last.comercio;

    // --- camino 0: lo que tu dijiste manda sobre todo lo demas -------------
    if (_enLista(ultimoNombre, no) || _enLista(clave, no)) return;
    final forzada = _enLista(ultimoNombre, si) || _enLista(clave, si);

    // --- camino 1: una regla ya dijo que es suscripcion -------------------
    final porRegla = lista.any((m) => m.recurrente);

    // --- camino 2: la firma de una suscripcion ----------------------------
    final porPatron = nMeses >= 3 &&
        cargosPorMes <= subCargosMesMax &&
        cv <= subCvMax &&
        desvioDia <= subDiaTolerancia;

    if (!forzada && !porRegla && !porPatron) return;

    final ordenados = [...lista]
      ..sort((a, b) => normalizarFecha(a.fecha).compareTo(normalizarFecha(b.fecha)));
    final ultimo = ordenados.last;
    final fechaUltimo = normalizarFecha(ultimo.fecha);
    final diasSin = diasEntre(fechaUltimo, referencia);

    out.add(Suscripcion(
      comercio: ultimo.comercio,
      categoria: ultimo.categoria,
      subcategoria: ultimo.subcategoria,
      // El promedio sale de importePen: SIEMPRE en soles. Etiquetarlo con la
      // moneda del cargo original haria que una suscripcion de $ 10.99 se
      // mostrara como "$ 41.21" y el total anual saliera multiplicado por 14.
      importePromedio: redondear(prom),
      importeUltimo: redondear(
          ultimo.importePen != 0 ? ultimo.importePen : ultimo.importe),
      monedaOriginal: ultimo.moneda,
      importeOriginal: redondear(ultimo.importe),
      meses: nMeses,
      cargos: lista.length,
      variacion: redondear(cv * 100, 1),
      ultimoCargo: fechaUltimo,
      diasSinCobrar: diasSin,
      diaAproximado: diaHabitual,
      origen: forzada ? 'MANUAL' : (porRegla ? 'REGLA' : 'PATRON'),
      estado: diasSin > subDiasInactiva ? 'POSIBLE_BAJA' : 'ACTIVA',
    ));
  });

  // Primero las activas, y dentro de cada grupo por importe.
  out.sort((a, b) {
    if (a.estado != b.estado) return a.estado == 'ACTIVA' ? -1 : 1;
    return b.importePromedio.compareTo(a.importePromedio);
  });
  return out;
}

bool _enLista(String comercio, List<String> lista) {
  final c = norm(comercio);
  return lista.any(c.contains);
}
