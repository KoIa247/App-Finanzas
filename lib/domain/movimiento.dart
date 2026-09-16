import '../core/fechas.dart';
import 'enums.dart';

/// Un movimiento de dinero. Es la entidad central del sistema.
///
/// [importe] va siempre en positivo y en la moneda original; el signo lo
/// determina [tipo]. [importePen] es el mismo monto convertido a soles, que es
/// lo unico con lo que se puede sumar un mes que mezcla dolares.
class Movimiento {
  const Movimiento({
    required this.id,
    required this.fecha,
    this.hora = '',
    this.tipo = TipoMovimiento.gasto,
    this.importe = 0,
    this.moneda = 'PEN',
    this.comercio = '',
    this.descripcion = '',
    this.categoria = '',
    this.subcategoria = '',
    this.banco = '',
    this.cuentaId = '',
    this.medioPago = '',
    this.tipoCambio,
    this.importePen = 0,
    this.fuente = Fuente.manual,
    this.emailId = '',
    this.nroOperacion = '',
    this.hashDedup = '',
    this.estado = EstadoMovimiento.ok,
    this.motivoRevision = '',
    this.recurrente = false,
    this.cuentaDestinoId = '',
    this.movimientoRel = '',
    this.notas = '',
    this.fechaCreacion = '',
    this.fechaModificacion = '',
    this.modificadoPor = '',
  });

  final String id;

  /// `yyyy-MM-dd`, hora de Lima.
  final String fecha;

  /// `HH:mm`.
  final String hora;

  final TipoMovimiento tipo;

  /// Siempre positivo, en la moneda original.
  final double importe;
  final String moneda;
  final String comercio;
  final String descripcion;
  final String categoria;
  final String subcategoria;
  final String banco;
  final String cuentaId;
  final String medioPago;
  final double? tipoCambio;

  /// El importe convertido a soles. Es el campo con el que se suma.
  final double importePen;
  final String fuente;

  /// Id del mensaje de Gmail. Primera capa anti duplicados.
  final String emailId;
  final String nroOperacion;

  /// Huella secundaria anti duplicados.
  final String hashDedup;
  final EstadoMovimiento estado;
  final String motivoRevision;
  final bool recurrente;
  final String cuentaDestinoId;
  final String movimientoRel;
  final String notas;
  final String fechaCreacion;
  final String fechaModificacion;
  final String modificadoPor;

  String get periodo => periodoDe(fecha);

  bool get esVivo => estado != EstadoMovimiento.anulado;

  bool get necesitaRevision => estado == EstadoMovimiento.revisar;

  /// Cuanto suma este movimiento al gasto del mes. Los neutros valen cero.
  double get gastoPen {
    if (!esVivo || tipo.esNeutro) return 0;
    if (tipo == TipoMovimiento.gasto || tipo == TipoMovimiento.comision) {
      return importePen;
    }
    // Una devolucion es un gasto negativo: libera el presupuesto de su
    // categoria en vez de inflar los ingresos del mes.
    if (tipo == TipoMovimiento.devolucion) return -importePen;
    return 0;
  }

  /// Cuanto suma a los ingresos del mes.
  double get ingresoPen =>
      (esVivo && tipo == TipoMovimiento.ingreso) ? importePen : 0;

  String get categoriaCompleta => subcategoria.isEmpty
      ? categoria
      : '$categoria / $subcategoria';

  Movimiento copyWith({
    String? id,
    String? fecha,
    String? hora,
    TipoMovimiento? tipo,
    double? importe,
    String? moneda,
    String? comercio,
    String? descripcion,
    String? categoria,
    String? subcategoria,
    String? banco,
    String? cuentaId,
    String? medioPago,
    double? tipoCambio,
    double? importePen,
    String? fuente,
    String? emailId,
    String? nroOperacion,
    String? hashDedup,
    EstadoMovimiento? estado,
    String? motivoRevision,
    bool? recurrente,
    String? cuentaDestinoId,
    String? movimientoRel,
    String? notas,
    String? fechaCreacion,
    String? fechaModificacion,
    String? modificadoPor,
  }) {
    return Movimiento(
      id: id ?? this.id,
      fecha: fecha ?? this.fecha,
      hora: hora ?? this.hora,
      tipo: tipo ?? this.tipo,
      importe: importe ?? this.importe,
      moneda: moneda ?? this.moneda,
      comercio: comercio ?? this.comercio,
      descripcion: descripcion ?? this.descripcion,
      categoria: categoria ?? this.categoria,
      subcategoria: subcategoria ?? this.subcategoria,
      banco: banco ?? this.banco,
      cuentaId: cuentaId ?? this.cuentaId,
      medioPago: medioPago ?? this.medioPago,
      tipoCambio: tipoCambio ?? this.tipoCambio,
      importePen: importePen ?? this.importePen,
      fuente: fuente ?? this.fuente,
      emailId: emailId ?? this.emailId,
      nroOperacion: nroOperacion ?? this.nroOperacion,
      hashDedup: hashDedup ?? this.hashDedup,
      estado: estado ?? this.estado,
      motivoRevision: motivoRevision ?? this.motivoRevision,
      recurrente: recurrente ?? this.recurrente,
      cuentaDestinoId: cuentaDestinoId ?? this.cuentaDestinoId,
      movimientoRel: movimientoRel ?? this.movimientoRel,
      notas: notas ?? this.notas,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaModificacion: fechaModificacion ?? this.fechaModificacion,
      modificadoPor: modificadoPor ?? this.modificadoPor,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'fecha': fecha,
        'hora': hora,
        'tipo': tipo.valor,
        'importe': importe,
        'moneda': moneda,
        'comercio': comercio,
        'descripcion': descripcion,
        'categoria': categoria,
        'subcategoria': subcategoria,
        'banco': banco,
        'cuenta_id': cuentaId,
        'medio_pago': medioPago,
        'tipo_cambio': tipoCambio,
        'importe_pen': importePen,
        'fuente': fuente,
        'email_id': emailId,
        'nro_operacion': nroOperacion,
        'hash_dedup': hashDedup,
        'estado': estado.valor,
        'motivo_revision': motivoRevision,
        'recurrente': recurrente ? 1 : 0,
        'cuenta_destino_id': cuentaDestinoId,
        'movimiento_rel': movimientoRel,
        'notas': notas,
        'fecha_creacion': fechaCreacion,
        'fecha_modificacion': fechaModificacion,
        'modificado_por': modificadoPor,
        'periodo': periodoDe(fecha),
      };

  factory Movimiento.fromMap(Map<String, Object?> m) => Movimiento(
        id: (m['id'] ?? '') as String,
        fecha: (m['fecha'] ?? '') as String,
        hora: (m['hora'] ?? '') as String,
        tipo: TipoMovimiento.desde(m['tipo']),
        importe: (m['importe'] as num?)?.toDouble() ?? 0,
        moneda: (m['moneda'] ?? 'PEN') as String,
        comercio: (m['comercio'] ?? '') as String,
        descripcion: (m['descripcion'] ?? '') as String,
        categoria: (m['categoria'] ?? '') as String,
        subcategoria: (m['subcategoria'] ?? '') as String,
        banco: (m['banco'] ?? '') as String,
        cuentaId: (m['cuenta_id'] ?? '') as String,
        medioPago: (m['medio_pago'] ?? '') as String,
        tipoCambio: (m['tipo_cambio'] as num?)?.toDouble(),
        importePen: (m['importe_pen'] as num?)?.toDouble() ?? 0,
        fuente: (m['fuente'] ?? Fuente.manual) as String,
        emailId: (m['email_id'] ?? '') as String,
        nroOperacion: (m['nro_operacion'] ?? '') as String,
        hashDedup: (m['hash_dedup'] ?? '') as String,
        estado: EstadoMovimiento.desde(m['estado']),
        motivoRevision: (m['motivo_revision'] ?? '') as String,
        recurrente: (m['recurrente'] as int? ?? 0) == 1,
        cuentaDestinoId: (m['cuenta_destino_id'] ?? '') as String,
        movimientoRel: (m['movimiento_rel'] ?? '') as String,
        notas: (m['notas'] ?? '') as String,
        fechaCreacion: (m['fecha_creacion'] ?? '') as String,
        fechaModificacion: (m['fecha_modificacion'] ?? '') as String,
        modificadoPor: (m['modificado_por'] ?? '') as String,
      );
}
