import '../core/fechas.dart';

/// Una meta de ahorro: para que estas guardando y cuanto falta.
///
/// La regla del prototipo, que es la que le da sentido: lo que aportas sale
/// de tu ahorro del mes, no de un presupuesto. Si un mes no alcanza, la meta
/// se queda quieta y no se pinta un numero falso.
class Meta {
  const Meta({
    required this.id,
    required this.nombre,
    this.objetivo = 0,
    this.moneda = 'PEN',
    this.fechaLimite = '',
    this.aporteSugerido = 0,
    this.icono = '',
    this.color = '#1E5A37',
    this.activa = true,
    this.orden = 999,
    this.notas = '',
    this.fechaCreacion = '',
  });

  final String id;
  final String nombre;
  final double objetivo;

  /// Cada moneda lleva sus propias metas: no se convierte nada para sumarlas.
  final String moneda;

  /// `yyyy-MM-dd`. Vacio es una meta sin fecha, que es legitimo: hay cosas
  /// para las que uno ahorra sin plazo.
  final String fechaLimite;

  /// Lo que la pantalla ofrece aportar de un toque.
  final double aporteSugerido;

  final String icono;
  final String color;
  final bool activa;
  final int orden;
  final String notas;
  final String fechaCreacion;

  bool get tieneFecha => fechaLimite.isNotEmpty;

  Meta copyWith({
    String? nombre,
    double? objetivo,
    String? moneda,
    String? fechaLimite,
    double? aporteSugerido,
    String? icono,
    String? color,
    bool? activa,
    int? orden,
    String? notas,
  }) =>
      Meta(
        id: id,
        nombre: nombre ?? this.nombre,
        objetivo: objetivo ?? this.objetivo,
        moneda: moneda ?? this.moneda,
        fechaLimite: fechaLimite ?? this.fechaLimite,
        aporteSugerido: aporteSugerido ?? this.aporteSugerido,
        icono: icono ?? this.icono,
        color: color ?? this.color,
        activa: activa ?? this.activa,
        orden: orden ?? this.orden,
        notas: notas ?? this.notas,
        fechaCreacion: fechaCreacion,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'nombre': nombre,
        'objetivo': objetivo,
        'moneda': moneda,
        'fecha_limite': fechaLimite,
        'aporte_sugerido': aporteSugerido,
        'icono': icono,
        'color': color,
        'activa': activa ? 1 : 0,
        'orden': orden,
        'notas': notas,
        'fecha_creacion': fechaCreacion,
      };

  static Meta fromMap(Map<String, Object?> m) => Meta(
        id: (m['id'] ?? '') as String,
        nombre: (m['nombre'] ?? '') as String,
        objetivo: (m['objetivo'] as num?)?.toDouble() ?? 0,
        moneda: (m['moneda'] ?? 'PEN') as String,
        fechaLimite: (m['fecha_limite'] ?? '') as String,
        aporteSugerido: (m['aporte_sugerido'] as num?)?.toDouble() ?? 0,
        icono: (m['icono'] ?? '') as String,
        color: (m['color'] ?? '#1E5A37') as String,
        activa: ((m['activa'] as num?)?.toInt() ?? 1) == 1,
        orden: (m['orden'] as num?)?.toInt() ?? 999,
        notas: (m['notas'] ?? '') as String,
        fechaCreacion: (m['fecha_creacion'] ?? '') as String,
      );
}

/// Un aporte a una meta. Se guardan uno por uno y no como un saldo: asi la
/// pantalla puede decir cuanto pusiste este mes y una correccion no se lleva
/// por delante el historial.
class AporteMeta {
  const AporteMeta({
    required this.id,
    required this.metaId,
    required this.fecha,
    required this.importe,
    this.moneda = 'PEN',
    this.notas = '',
  });

  final String id;
  final String metaId;
  final String fecha;
  final double importe;
  final String moneda;
  final String notas;

  String get periodo => periodoDe(fecha);

  Map<String, Object?> toMap() => {
        'id': id,
        'meta_id': metaId,
        'fecha': fecha,
        'periodo': periodoDe(fecha),
        'importe': importe,
        'moneda': moneda,
        'notas': notas,
      };

  static AporteMeta fromMap(Map<String, Object?> m) => AporteMeta(
        id: (m['id'] ?? '') as String,
        metaId: (m['meta_id'] ?? '') as String,
        fecha: (m['fecha'] ?? '') as String,
        importe: (m['importe'] as num?)?.toDouble() ?? 0,
        moneda: (m['moneda'] ?? 'PEN') as String,
        notas: (m['notas'] ?? '') as String,
      );
}

/// Una meta con sus cuentas hechas, lista para pintar.
class AvanceMeta {
  const AvanceMeta({
    required this.meta,
    required this.ahorrado,
    required this.aportadoEnPeriodo,
  });

  final Meta meta;

  /// Todo lo aportado desde que existe la meta.
  final double ahorrado;

  /// Lo aportado en el mes que se esta mirando.
  final double aportadoEnPeriodo;

  double get falta => (meta.objetivo - ahorrado).clamp(0, double.infinity);

  double get porcentaje =>
      meta.objetivo > 0 ? (ahorrado / meta.objetivo).clamp(0.0, 1.0) : 0;

  bool get cumplida => meta.objetivo > 0 && ahorrado >= meta.objetivo;

  /// Cuanto habria que poner por mes para llegar a tiempo.
  ///
  /// Null cuando no hay fecha o cuando la fecha ya paso: en los dos casos un
  /// numero aqui seria inventado.
  double? get porMes {
    if (!meta.tieneFecha || cumplida) return null;
    final meses = mesesHasta(meta.fechaLimite);
    if (meses == null || meses <= 0) return null;
    return falta / meses;
  }
}

/// Cuantos meses faltan desde hoy hasta un `yyyy-MM-dd`, contando el actual.
/// Null si la fecha no se entiende o ya paso.
int? mesesHasta(String fecha) {
  if (fecha.length < 7) return null;
  final hoy = hoyLima();
  final a1 = int.tryParse(hoy.substring(0, 4));
  final m1 = int.tryParse(hoy.substring(5, 7));
  final a2 = int.tryParse(fecha.substring(0, 4));
  final m2 = int.tryParse(fecha.substring(5, 7));
  if (a1 == null || m1 == null || a2 == null || m2 == null) return null;
  final n = (a2 - a1) * 12 + (m2 - m1) + 1;
  return n > 0 ? n : null;
}
