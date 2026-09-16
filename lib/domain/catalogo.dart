/// Una cuenta o tarjeta.
///
/// Esta lista existe sobre todo para una cosa: conectar los ultimos 4 digitos
/// que vienen en cada correo con la cuenta correcta. No guarda saldos.
class Cuenta {
  const Cuenta({
    required this.id,
    required this.nombre,
    this.banco = '',
    this.tipo = '',
    this.moneda = 'PEN',
    this.ultimos4 = '',
    this.saldoInicial = 0,
    this.fechaSaldoInicial = '',
    this.lineaCredito = 0,
    this.diaCierre,
    this.diaPago,
    this.activa = true,
    this.notas = '',
    this.esPropia = true,
  });

  final String id;
  final String nombre;
  final String banco;
  final String tipo;
  final String moneda;
  final String ultimos4;
  final double saldoInicial;
  final String fechaSaldoInicial;
  final double lineaCredito;
  final int? diaCierre;
  final int? diaPago;
  final bool activa;
  final String notas;

  /// Cuentas que operas pero cuyo dinero NO es tuyo (la del negocio de un
  /// familiar, por ejemplo). Sus operaciones no se registran.
  final bool esPropia;

  bool get esTarjetaCredito => tipo == 'TARJETA_CREDITO';

  Cuenta copyWith({
    String? id,
    String? nombre,
    String? banco,
    String? tipo,
    String? moneda,
    String? ultimos4,
    double? saldoInicial,
    String? fechaSaldoInicial,
    double? lineaCredito,
    int? diaCierre,
    int? diaPago,
    bool? activa,
    String? notas,
    bool? esPropia,
  }) =>
      Cuenta(
        id: id ?? this.id,
        nombre: nombre ?? this.nombre,
        banco: banco ?? this.banco,
        tipo: tipo ?? this.tipo,
        moneda: moneda ?? this.moneda,
        ultimos4: ultimos4 ?? this.ultimos4,
        saldoInicial: saldoInicial ?? this.saldoInicial,
        fechaSaldoInicial: fechaSaldoInicial ?? this.fechaSaldoInicial,
        lineaCredito: lineaCredito ?? this.lineaCredito,
        diaCierre: diaCierre ?? this.diaCierre,
        diaPago: diaPago ?? this.diaPago,
        activa: activa ?? this.activa,
        notas: notas ?? this.notas,
        esPropia: esPropia ?? this.esPropia,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'nombre': nombre,
        'banco': banco,
        'tipo': tipo,
        'moneda': moneda,
        'ultimos4': ultimos4,
        'saldo_inicial': saldoInicial,
        'fecha_saldo_inicial': fechaSaldoInicial,
        'linea_credito': lineaCredito,
        'dia_cierre': diaCierre,
        'dia_pago': diaPago,
        'activa': activa ? 1 : 0,
        'notas': notas,
        'es_propia': esPropia ? 1 : 0,
      };

  factory Cuenta.fromMap(Map<String, Object?> m) => Cuenta(
        id: (m['id'] ?? '') as String,
        nombre: (m['nombre'] ?? '') as String,
        banco: (m['banco'] ?? '') as String,
        tipo: (m['tipo'] ?? '') as String,
        moneda: (m['moneda'] ?? 'PEN') as String,
        ultimos4: (m['ultimos4'] ?? '') as String,
        saldoInicial: (m['saldo_inicial'] as num?)?.toDouble() ?? 0,
        fechaSaldoInicial: (m['fecha_saldo_inicial'] ?? '') as String,
        lineaCredito: (m['linea_credito'] as num?)?.toDouble() ?? 0,
        diaCierre: m['dia_cierre'] as int?,
        diaPago: m['dia_pago'] as int?,
        activa: (m['activa'] as int? ?? 1) == 1,
        notas: (m['notas'] ?? '') as String,
        esPropia: (m['es_propia'] as int? ?? 1) == 1,
      );
}

/// Una categoria con su subcategoria. Juntas forman la unidad de presupuesto.
class Categoria {
  const Categoria({
    required this.categoria,
    required this.subcategoria,
    this.tipoAplicable = 'GASTO',
    this.icono = '',
    this.color = '#94A3B8',
    this.activa = true,
    this.orden = 999,
  });

  final String categoria;
  final String subcategoria;

  /// GASTO | INGRESO | NEUTRO
  final String tipoAplicable;
  final String icono;
  final String color;
  final bool activa;
  final int orden;

  String get clave => '$categoria|$subcategoria';

  String get etiqueta => '$categoria / $subcategoria';

  Categoria copyWith({
    String? categoria,
    String? subcategoria,
    String? tipoAplicable,
    String? icono,
    String? color,
    bool? activa,
    int? orden,
  }) =>
      Categoria(
        categoria: categoria ?? this.categoria,
        subcategoria: subcategoria ?? this.subcategoria,
        tipoAplicable: tipoAplicable ?? this.tipoAplicable,
        icono: icono ?? this.icono,
        color: color ?? this.color,
        activa: activa ?? this.activa,
        orden: orden ?? this.orden,
      );

  Map<String, Object?> toMap() => {
        'categoria': categoria,
        'subcategoria': subcategoria,
        'tipo_aplicable': tipoAplicable,
        'icono': icono,
        'color': color,
        'activa': activa ? 1 : 0,
        'orden': orden,
      };

  factory Categoria.fromMap(Map<String, Object?> m) => Categoria(
        categoria: (m['categoria'] ?? '') as String,
        subcategoria: (m['subcategoria'] ?? '') as String,
        tipoAplicable: (m['tipo_aplicable'] ?? 'GASTO') as String,
        icono: (m['icono'] ?? '') as String,
        color: (m['color'] ?? '#94A3B8') as String,
        activa: (m['activa'] as int? ?? 1) == 1,
        orden: (m['orden'] as int?) ?? 999,
      );
}

/// Una regla de clasificacion. Se evaluan por prioridad ascendente y gana la
/// primera que calza.
class Regla {
  const Regla({
    required this.id,
    this.prioridad = 100,
    this.activa = true,
    this.campo = 'comercio',
    this.operador = 'contiene',
    this.valor = '',
    this.tipoResultado = '',
    this.categoria = '',
    this.subcategoria = '',
    this.cuentaDestino = '',
    this.recurrente = false,
    this.origen = 'MANUAL',
    this.aciertos = 0,
    this.fechaCreacion = '',
  });

  final String id;
  final int prioridad;
  final bool activa;

  /// comercio | descripcion | tipo | cuenta | medio | moneda | importe | banco
  final String campo;

  /// contiene | igual | empieza | termina | regex | mayor | menor
  final String operador;
  final String valor;
  final String tipoResultado;
  final String categoria;
  final String subcategoria;
  final String cuentaDestino;
  final bool recurrente;

  /// SEMILLA | MANUAL | APRENDIDA
  final String origen;
  final int aciertos;
  final String fechaCreacion;

  Regla copyWith({
    String? id,
    int? prioridad,
    bool? activa,
    String? campo,
    String? operador,
    String? valor,
    String? tipoResultado,
    String? categoria,
    String? subcategoria,
    String? cuentaDestino,
    bool? recurrente,
    String? origen,
    int? aciertos,
    String? fechaCreacion,
  }) =>
      Regla(
        id: id ?? this.id,
        prioridad: prioridad ?? this.prioridad,
        activa: activa ?? this.activa,
        campo: campo ?? this.campo,
        operador: operador ?? this.operador,
        valor: valor ?? this.valor,
        tipoResultado: tipoResultado ?? this.tipoResultado,
        categoria: categoria ?? this.categoria,
        subcategoria: subcategoria ?? this.subcategoria,
        cuentaDestino: cuentaDestino ?? this.cuentaDestino,
        recurrente: recurrente ?? this.recurrente,
        origen: origen ?? this.origen,
        aciertos: aciertos ?? this.aciertos,
        fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'prioridad': prioridad,
        'activa': activa ? 1 : 0,
        'campo': campo,
        'operador': operador,
        'valor': valor,
        'tipo_resultado': tipoResultado,
        'categoria': categoria,
        'subcategoria': subcategoria,
        'cuenta_destino': cuentaDestino,
        'recurrente': recurrente ? 1 : 0,
        'origen': origen,
        'aciertos': aciertos,
        'fecha_creacion': fechaCreacion,
      };

  factory Regla.fromMap(Map<String, Object?> m) => Regla(
        id: (m['id'] ?? '') as String,
        prioridad: (m['prioridad'] as int?) ?? 100,
        activa: (m['activa'] as int? ?? 1) == 1,
        campo: (m['campo'] ?? 'comercio') as String,
        operador: (m['operador'] ?? 'contiene') as String,
        valor: (m['valor'] ?? '') as String,
        tipoResultado: (m['tipo_resultado'] ?? '') as String,
        categoria: (m['categoria'] ?? '') as String,
        subcategoria: (m['subcategoria'] ?? '') as String,
        cuentaDestino: (m['cuenta_destino'] ?? '') as String,
        recurrente: (m['recurrente'] as int? ?? 0) == 1,
        origen: (m['origen'] ?? 'MANUAL') as String,
        aciertos: (m['aciertos'] as int?) ?? 0,
        fechaCreacion: (m['fecha_creacion'] ?? '') as String,
      );
}

/// Direccion de correo autorizada. Solo se leen mensajes de estas direcciones.
class Remitente {
  const Remitente({
    required this.remitente,
    this.banco = '',
    this.parser = 'GENERICO',
    this.activo = true,
    this.notas = '',
  });

  final String remitente;
  final String banco;

  /// BCP | GENERICO
  final String parser;
  final bool activo;
  final String notas;

  Remitente copyWith({bool? activo}) => Remitente(
        remitente: remitente,
        banco: banco,
        parser: parser,
        activo: activo ?? this.activo,
        notas: notas,
      );

  Map<String, Object?> toMap() => {
        'remitente': remitente,
        'banco': banco,
        'parser': parser,
        'activo': activo ? 1 : 0,
        'notas': notas,
      };

  factory Remitente.fromMap(Map<String, Object?> m) => Remitente(
        remitente: (m['remitente'] ?? '') as String,
        banco: (m['banco'] ?? '') as String,
        parser: (m['parser'] ?? 'GENERICO') as String,
        activo: (m['activo'] as int? ?? 1) == 1,
        notas: (m['notas'] ?? '') as String,
      );
}
