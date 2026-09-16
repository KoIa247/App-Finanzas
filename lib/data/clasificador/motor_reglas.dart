import '../../core/texto.dart';
import '../../domain/catalogo.dart';
import '../../domain/enums.dart';
import '../parser/contexto.dart';

/// Operadores disponibles en una regla.
typedef Operador = bool Function(String valor, String patron);

final Map<String, Operador> operadores = {
  'contiene': (v, p) => v.contains(p),
  'igual': (v, p) => v == p,
  'empieza': (v, p) => v.startsWith(p),
  'termina': (v, p) => v.endsWith(p),
  'regex': (v, p) {
    try {
      return RegExp(p, caseSensitive: false).hasMatch(v);
    } catch (_) {
      return false;
    }
  },
  'mayor': (v, p) =>
      (double.tryParse(v) ?? 0) > (double.tryParse(p) ?? 0),
  'menor': (v, p) =>
      (double.tryParse(v) ?? 0) < (double.tryParse(p) ?? 0),
};

/// Lo que una regla decidio sobre un movimiento.
class Clasificacion {
  const Clasificacion({
    required this.reglaId,
    this.tipo = '',
    this.categoria = '',
    this.subcategoria = '',
    this.cuentaDestino = '',
    this.recurrente = false,
  });

  final String reglaId;
  final String tipo;
  final String categoria;
  final String subcategoria;
  final String cuentaDestino;
  final bool recurrente;
}

/// El motor de reglas.
///
/// Se construye una vez con las reglas activas ya ordenadas y se reutiliza
/// durante toda una corrida de ingesta: reordenar en cada movimiento seria
/// tirar trabajo a la basura.
class MotorReglas {
  MotorReglas(List<Regla> reglas)
      : _reglas = reglas
            .where((r) => r.activa && r.valor.isNotEmpty)
            .toList(growable: false)
          ..sort((a, b) => a.prioridad.compareTo(b.prioridad));

  final List<Regla> _reglas;

  List<Regla> get reglas => List.unmodifiable(_reglas);

  /// Valor del movimiento contra el que se evalua una regla.
  static String valorCampo(MovimientoCrudo mov, String campo) {
    switch (norm(campo)) {
      case 'COMERCIO':
        return norm(mov.comercio);
      case 'DESCRIPCION':
        return norm(mov.descripcion);
      case 'TIPO':
        return norm(mov.tipo.valor);
      case 'CUENTA':
        return norm(mov.cuentaId);
      case 'MEDIO':
      case 'MEDIOPAGO':
        return norm(mov.medioPago);
      case 'MONEDA':
        return norm(mov.moneda);
      case 'IMPORTE':
        return mov.importe.toString();
      case 'BANCO':
        return norm(mov.banco);
      default:
        return norm(mov.comercio);
    }
  }

  /// Aplica las reglas. Devuelve null si ninguna calza.
  ///
  /// Gana la primera que coincide, por eso el orden de prioridad es el que
  /// decide entre "GOOGLE WORKSPACE" y el comodin "GOOGLE".
  Clasificacion? clasificar(MovimientoCrudo mov) {
    for (final r in _reglas) {
      final fn = operadores[r.operador.toLowerCase()] ?? operadores['contiene']!;
      final valor = valorCampo(mov, r.campo);
      if (valor.isEmpty) continue;
      final patron =
          r.operador.toLowerCase() == 'regex' ? r.valor : norm(r.valor);
      if (fn(valor, patron)) {
        return Clasificacion(
          reglaId: r.id,
          tipo: r.tipoResultado,
          categoria: r.categoria,
          subcategoria: r.subcategoria,
          cuentaDestino: r.cuentaDestino,
          recurrente: r.recurrente,
        );
      }
    }
    return null;
  }

  /// Aplica la clasificacion sobre el movimiento y dice si quedo clasificado.
  bool aplicar(MovimientoCrudo mov, {bool autoCategorizar = true}) {
    if (!autoCategorizar) return false;

    final c = clasificar(mov);
    if (c == null) {
      if (mov.categoria.isEmpty) {
        mov.categoria = 'Sin clasificar';
        mov.subcategoria = 'Sin clasificar';
        if (mov.tipo == TipoMovimiento.gasto ||
            mov.tipo == TipoMovimiento.ingreso) {
          mov.estado = EstadoMovimiento.revisar;
          if (mov.motivoRevision.isEmpty) {
            mov.motivoRevision = MotivoRevision.sinCategoria;
          }
        }
      }
      return false;
    }

    if (c.tipo.isNotEmpty) mov.tipo = TipoMovimiento.desde(c.tipo);
    if (c.categoria.isNotEmpty) mov.categoria = c.categoria;
    if (c.subcategoria.isNotEmpty) mov.subcategoria = c.subcategoria;
    if (c.cuentaDestino.isNotEmpty) mov.cuentaDestinoId = c.cuentaDestino;
    if (c.recurrente) mov.recurrente = true;
    mov.reglaAplicada = c.reglaId;

    // Una transferencia a un tercero nace en REVISAR porque el sistema no sabe
    // si fue gasto, prestamo o aporte. Si una regla tuya ya decidio que es
    // (porque corregiste una anterior del mismo beneficiario), la duda esta
    // resuelta y no tiene sentido volver a preguntarte cada mes.
    if (c.categoria.isNotEmpty &&
        mov.estado == EstadoMovimiento.revisar &&
        mov.cuentaId.isNotEmpty &&
        mov.motivoRevision == MotivoRevision.confirmarTransferencia) {
      mov.estado = EstadoMovimiento.ok;
      mov.motivoRevision = '';
    }
    return true;
  }
}

/// Categoria por defecto segun el tipo, para los movimientos neutros.
void aplicarCategoriaPorTipo(MovimientoCrudo mov) {
  if (mov.categoria.isNotEmpty) return;
  switch (mov.tipo) {
    case TipoMovimiento.transferencia:
      mov.categoria = 'Movimientos internos';
      mov.subcategoria = 'Transferencia entre cuentas';
    case TipoMovimiento.pagoTarjeta:
      mov.categoria = 'Movimientos internos';
      mov.subcategoria = 'Pago de tarjeta';
    case TipoMovimiento.retiroEfectivo:
      mov.categoria = 'Movimientos internos';
      mov.subcategoria = 'Retiro de efectivo';
    case TipoMovimiento.aporteInversion:
      mov.categoria = 'Inversiones';
      mov.subcategoria = 'Aportes';
    case TipoMovimiento.retiroInversion:
      mov.categoria = 'Inversiones';
      mov.subcategoria = 'Retiros';
    case TipoMovimiento.ingreso:
      mov.categoria = 'Ingresos';
      mov.subcategoria = 'Otros';
    default:
      mov.categoria = 'Sin clasificar';
      mov.subcategoria = 'Sin clasificar';
  }
}

/// Construye el patron que aprende una regla a partir de un comercio.
///
/// Usa las primeras 3 palabras significativas para no encasillar la regla por
/// un numero de operacion que solo aparece una vez.
String patronAprendido(String comercio) {
  final completo = norm(comercio);
  if (completo.isEmpty || completo == 'SIN IDENTIFICAR') return '';

  final patron = completo
      .split(' ')
      .take(3)
      .join(' ')
      .replaceAll(RegExp(r'[^A-Z0-9*. ]'), '')
      .trim();
  return patron.length < 3 ? completo : patron;
}
