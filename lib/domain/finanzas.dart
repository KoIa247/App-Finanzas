/// Una linea de presupuesto: cuanto pensabas gastar en una categoria este mes.
class LineaPresupuesto {
  const LineaPresupuesto({
    required this.periodo,
    required this.categoria,
    this.subcategoria = '',
    this.moneda = 'PEN',
    this.monto = 0,
    this.notas = '',
  });

  final String periodo;
  final String categoria;
  final String subcategoria;
  final String moneda;
  final double monto;
  final String notas;

  String get clave => '$categoria|$subcategoria';

  LineaPresupuesto copyWith({double? monto, String? notas}) =>
      LineaPresupuesto(
        periodo: periodo,
        categoria: categoria,
        subcategoria: subcategoria,
        moneda: moneda,
        monto: monto ?? this.monto,
        notas: notas ?? this.notas,
      );

  Map<String, Object?> toMap() => {
        'periodo': periodo,
        'categoria': categoria,
        'subcategoria': subcategoria,
        'moneda': moneda,
        'monto': monto,
        'notas': notas,
      };

  factory LineaPresupuesto.fromMap(Map<String, Object?> m) => LineaPresupuesto(
        periodo: (m['periodo'] ?? '') as String,
        categoria: (m['categoria'] ?? '') as String,
        subcategoria: (m['subcategoria'] ?? '') as String,
        moneda: (m['moneda'] ?? 'PEN') as String,
        monto: (m['monto'] as num?)?.toDouble() ?? 0,
        notas: (m['notas'] ?? '') as String,
      );
}

/// Como va una categoria contra lo que le presupuestaste.
class AvancePresupuesto {
  const AvancePresupuesto({
    required this.categoria,
    required this.subcategoria,
    required this.presupuestado,
    required this.gastado,
    this.icono = '',
    this.color = '#94A3B8',
  });

  final String categoria;
  final String subcategoria;
  final double presupuestado;
  final double gastado;
  final String icono;
  final String color;

  double get disponible => presupuestado - gastado;

  double get porcentaje =>
      presupuestado > 0 ? (gastado / presupuestado).clamp(0.0, 4.0) : 0;

  bool get excedido => gastado > presupuestado && presupuestado > 0;

  String get etiqueta =>
      subcategoria.isEmpty ? categoria : '$categoria / $subcategoria';
}

/// Foto consolidada de tu posicion.
///
/// La actualizas tu, no se calcula sola: los correos no cubren todos tus
/// movimientos (el banco no notifica el abono del sueldo ni el gasto en
/// efectivo), asi que un saldo derivado solo de ellos siempre estaria mal.
class FotoPatrimonio {
  const FotoPatrimonio({
    required this.fecha,
    this.liquidezPen = 0,
    this.liquidezUsd = 0,
    this.deudaTarjetaPen = 0,
    this.deudaTarjetaUsd = 0,
    this.otrosActivosPen = 0,
    this.otrosPasivosPen = 0,
    this.notas = '',
    this.registrado = 'MANUAL',
  });

  final String fecha;
  final double liquidezPen;
  final double liquidezUsd;
  final double deudaTarjetaPen;
  final double deudaTarjetaUsd;
  final double otrosActivosPen;
  final double otrosPasivosPen;
  final String notas;
  final String registrado;

  /// Patrimonio neto en soles. [tc] es el tipo de cambio del dia.
  double netoPen(double tc, {double inversionesPen = 0}) {
    final activos =
        liquidezPen + liquidezUsd * tc + otrosActivosPen + inversionesPen;
    final pasivos = deudaTarjetaPen + deudaTarjetaUsd * tc + otrosPasivosPen;
    return activos - pasivos;
  }

  Map<String, Object?> toMap() => {
        'fecha': fecha,
        'liquidez_pen': liquidezPen,
        'liquidez_usd': liquidezUsd,
        'deuda_tarjeta_pen': deudaTarjetaPen,
        'deuda_tarjeta_usd': deudaTarjetaUsd,
        'otros_activos_pen': otrosActivosPen,
        'otros_pasivos_pen': otrosPasivosPen,
        'notas': notas,
        'registrado': registrado,
      };

  factory FotoPatrimonio.fromMap(Map<String, Object?> m) => FotoPatrimonio(
        fecha: (m['fecha'] ?? '') as String,
        liquidezPen: (m['liquidez_pen'] as num?)?.toDouble() ?? 0,
        liquidezUsd: (m['liquidez_usd'] as num?)?.toDouble() ?? 0,
        deudaTarjetaPen: (m['deuda_tarjeta_pen'] as num?)?.toDouble() ?? 0,
        deudaTarjetaUsd: (m['deuda_tarjeta_usd'] as num?)?.toDouble() ?? 0,
        otrosActivosPen: (m['otros_activos_pen'] as num?)?.toDouble() ?? 0,
        otrosPasivosPen: (m['otros_pasivos_pen'] as num?)?.toDouble() ?? 0,
        notas: (m['notas'] ?? '') as String,
        registrado: (m['registrado'] ?? 'MANUAL') as String,
      );
}

/// Plantilla de ingreso: lo unico que el banco NO notifica por correo.
/// Un toque en la app registra el movimiento con la fecha de hoy.
class PlantillaIngreso {
  const PlantillaIngreso({
    required this.id,
    required this.nombre,
    this.categoria = 'Ingresos',
    this.subcategoria = 'Otros',
    this.montoSugerido = 0,
    this.moneda = 'PEN',
    this.cuentaId = '',
    this.diaAproximado = 0,
    this.frecuencia = 'EVENTUAL',
    this.activo = true,
    this.orden = 99,
  });

  final String id;
  final String nombre;
  final String categoria;
  final String subcategoria;
  final double montoSugerido;
  final String moneda;
  final String cuentaId;
  final int diaAproximado;

  /// MENSUAL | SEMESTRAL | ANUAL | EVENTUAL
  final String frecuencia;
  final bool activo;
  final int orden;

  PlantillaIngreso copyWith({
    String? nombre,
    String? categoria,
    String? subcategoria,
    double? montoSugerido,
    String? moneda,
    String? cuentaId,
    int? diaAproximado,
    String? frecuencia,
    bool? activo,
    int? orden,
  }) =>
      PlantillaIngreso(
        id: id,
        nombre: nombre ?? this.nombre,
        categoria: categoria ?? this.categoria,
        subcategoria: subcategoria ?? this.subcategoria,
        montoSugerido: montoSugerido ?? this.montoSugerido,
        moneda: moneda ?? this.moneda,
        cuentaId: cuentaId ?? this.cuentaId,
        diaAproximado: diaAproximado ?? this.diaAproximado,
        frecuencia: frecuencia ?? this.frecuencia,
        activo: activo ?? this.activo,
        orden: orden ?? this.orden,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'nombre': nombre,
        'categoria': categoria,
        'subcategoria': subcategoria,
        'monto_sugerido': montoSugerido,
        'moneda': moneda,
        'cuenta_id': cuentaId,
        'dia_aproximado': diaAproximado,
        'frecuencia': frecuencia,
        'activo': activo ? 1 : 0,
        'orden': orden,
      };

  factory PlantillaIngreso.fromMap(Map<String, Object?> m) => PlantillaIngreso(
        id: (m['id'] ?? '') as String,
        nombre: (m['nombre'] ?? '') as String,
        categoria: (m['categoria'] ?? 'Ingresos') as String,
        subcategoria: (m['subcategoria'] ?? 'Otros') as String,
        montoSugerido: (m['monto_sugerido'] as num?)?.toDouble() ?? 0,
        moneda: (m['moneda'] ?? 'PEN') as String,
        cuentaId: (m['cuenta_id'] ?? '') as String,
        diaAproximado: (m['dia_aproximado'] as int?) ?? 0,
        frecuencia: (m['frecuencia'] ?? 'EVENTUAL') as String,
        activo: (m['activo'] as int? ?? 1) == 1,
        orden: (m['orden'] as int?) ?? 99,
      );
}

/// Una operacion de inversion (compra, venta o aporte).
class Inversion {
  const Inversion({
    required this.id,
    required this.fecha,
    this.tipo = 'COMPRA',
    this.activo = '',
    this.cuentaId = '',
    this.cantidad = 0,
    this.precioUnitario = 0,
    this.importe = 0,
    this.moneda = 'USD',
    this.comision = 0,
    this.movimientoRel = '',
    this.notas = '',
    this.fechaCreacion = '',
  });

  final String id;
  final String fecha;

  /// COMPRA | VENTA | DIVIDENDO | POSICION_INICIAL
  final String tipo;
  final String activo;
  final String cuentaId;
  final double cantidad;
  final double precioUnitario;
  final double importe;
  final String moneda;
  final double comision;
  final String movimientoRel;
  final String notas;
  final String fechaCreacion;

  Map<String, Object?> toMap() => {
        'id': id,
        'fecha': fecha,
        'tipo': tipo,
        'activo': activo,
        'cuenta_id': cuentaId,
        'cantidad': cantidad,
        'precio_unitario': precioUnitario,
        'importe': importe,
        'moneda': moneda,
        'comision': comision,
        'movimiento_rel': movimientoRel,
        'notas': notas,
        'fecha_creacion': fechaCreacion,
      };

  factory Inversion.fromMap(Map<String, Object?> m) => Inversion(
        id: (m['id'] ?? '') as String,
        fecha: (m['fecha'] ?? '') as String,
        tipo: (m['tipo'] ?? 'COMPRA') as String,
        activo: (m['activo'] ?? '') as String,
        cuentaId: (m['cuenta_id'] ?? '') as String,
        cantidad: (m['cantidad'] as num?)?.toDouble() ?? 0,
        precioUnitario: (m['precio_unitario'] as num?)?.toDouble() ?? 0,
        importe: (m['importe'] as num?)?.toDouble() ?? 0,
        moneda: (m['moneda'] ?? 'USD') as String,
        comision: (m['comision'] as num?)?.toDouble() ?? 0,
        movimientoRel: (m['movimiento_rel'] ?? '') as String,
        notas: (m['notas'] ?? '') as String,
        fechaCreacion: (m['fecha_creacion'] ?? '') as String,
      );
}

/// Un instrumento en el que inviertes, con su ultimo precio conocido.
class ActivoInversion {
  const ActivoInversion({
    required this.simbolo,
    this.nombre = '',
    this.clase = 'ACCION',
    this.moneda = 'USD',
    this.precioActual = 0,
    this.fechaPrecio = '',
    this.fuentePrecio = 'MANUAL',
    this.activo = true,
  });

  final String simbolo;
  final String nombre;
  final String clase;
  final String moneda;
  final double precioActual;
  final String fechaPrecio;
  final String fuentePrecio;
  final bool activo;

  Map<String, Object?> toMap() => {
        'simbolo': simbolo,
        'nombre': nombre,
        'clase': clase,
        'moneda': moneda,
        'precio_actual': precioActual,
        'fecha_precio': fechaPrecio,
        'fuente_precio': fuentePrecio,
        'activo': activo ? 1 : 0,
      };

  factory ActivoInversion.fromMap(Map<String, Object?> m) => ActivoInversion(
        simbolo: (m['simbolo'] ?? '') as String,
        nombre: (m['nombre'] ?? '') as String,
        clase: (m['clase'] ?? 'ACCION') as String,
        moneda: (m['moneda'] ?? 'USD') as String,
        precioActual: (m['precio_actual'] as num?)?.toDouble() ?? 0,
        fechaPrecio: (m['fecha_precio'] ?? '') as String,
        fuentePrecio: (m['fuente_precio'] ?? 'MANUAL') as String,
        activo: (m['activo'] as int? ?? 1) == 1,
      );
}

/// Posicion consolidada en un activo, calculada a partir de las operaciones.
class PosicionInversion {
  const PosicionInversion({
    required this.simbolo,
    required this.nombre,
    required this.cantidad,
    required this.costoTotal,
    required this.valorActual,
    required this.moneda,
  });

  final String simbolo;
  final String nombre;
  final double cantidad;
  final double costoTotal;
  final double valorActual;
  final String moneda;

  double get ganancia => valorActual - costoTotal;

  double get rendimiento => costoTotal > 0 ? ganancia / costoTotal : 0;

  double get precioPromedio => cantidad > 0 ? costoTotal / cantidad : 0;
}

/// Una suscripcion detectada a partir del historial de cargos.
class Suscripcion {
  const Suscripcion({
    required this.comercio,
    this.categoria = '',
    this.subcategoria = '',
    this.importePromedio = 0,
    this.importeUltimo = 0,
    this.monedaOriginal = 'PEN',
    this.importeOriginal = 0,
    this.meses = 0,
    this.cargos = 0,
    this.variacion = 0,
    this.ultimoCargo = '',
    this.diasSinCobrar = 0,
    this.diaAproximado = 1,
    this.origen = 'PATRON',
    this.estado = 'ACTIVA',
  });

  final String comercio;
  final String categoria;
  final String subcategoria;

  /// Siempre en soles: es lo unico con lo que se puede proyectar el anio.
  final double importePromedio;
  final double importeUltimo;
  final String monedaOriginal;
  final double importeOriginal;
  final int meses;
  final int cargos;

  /// Coeficiente de variacion del importe, en porcentaje.
  final double variacion;
  final String ultimoCargo;
  final int diasSinCobrar;
  final int diaAproximado;

  /// MANUAL | REGLA | PATRON
  final String origen;

  /// ACTIVA | POSIBLE_BAJA
  final String estado;

  bool get activa => estado == 'ACTIVA';

  double get costoAnual => importePromedio * 12;
}
