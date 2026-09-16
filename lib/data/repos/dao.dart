import 'package:sqflite/sqflite.dart';

import '../../core/fechas.dart';
import '../../core/texto.dart';
import '../../domain/catalogo.dart';
import '../../domain/enums.dart';
import '../../domain/finanzas.dart';
import '../../domain/movimiento.dart';
import '../db/base_datos.dart';

/// Filtros de la pantalla de movimientos.
class FiltroMovimientos {
  const FiltroMovimientos({
    this.texto = '',
    this.periodo = '',
    this.categoria = '',
    this.cuentaId = '',
    this.tipo,
    this.estado,
    this.desde = '',
    this.hasta = '',
    this.incluirAnulados = false,
    this.limite = 0,
  });

  final String texto;
  final String periodo;
  final String categoria;
  final String cuentaId;
  final TipoMovimiento? tipo;
  final EstadoMovimiento? estado;
  final String desde;
  final String hasta;
  final bool incluirAnulados;
  final int limite;

  FiltroMovimientos copyWith({
    String? texto,
    String? periodo,
    String? categoria,
    String? cuentaId,
    TipoMovimiento? tipo,
    EstadoMovimiento? estado,
    bool limpiarTipo = false,
    bool limpiarEstado = false,
  }) =>
      FiltroMovimientos(
        texto: texto ?? this.texto,
        periodo: periodo ?? this.periodo,
        categoria: categoria ?? this.categoria,
        cuentaId: cuentaId ?? this.cuentaId,
        tipo: limpiarTipo ? null : (tipo ?? this.tipo),
        estado: limpiarEstado ? null : (estado ?? this.estado),
        desde: desde,
        hasta: hasta,
        incluirAnulados: incluirAnulados,
        limite: limite,
      );
}

/// Acceso a datos. Una clase por conveniencia, pero cada seccion es
/// independiente: nada aqui sabe de widgets.
class Dao {
  Dao(this._base);

  final BaseDatos _base;

  Future<Database> get _db => _base.db;

  // ==========================================================================
  //  MOVIMIENTOS
  // ==========================================================================

  Future<List<Movimiento>> movimientos([
    FiltroMovimientos f = const FiltroMovimientos(),
  ]) async {
    final d = await _db;
    final donde = <String>[];
    final args = <Object?>[];

    if (!f.incluirAnulados) {
      donde.add('estado != ?');
      args.add(EstadoMovimiento.anulado.valor);
    }
    if (f.periodo.isNotEmpty) {
      donde.add('periodo = ?');
      args.add(f.periodo);
    }
    if (f.desde.isNotEmpty) {
      donde.add('fecha >= ?');
      args.add(f.desde);
    }
    if (f.hasta.isNotEmpty) {
      donde.add('fecha <= ?');
      args.add(f.hasta);
    }
    if (f.categoria.isNotEmpty) {
      donde.add('categoria = ?');
      args.add(f.categoria);
    }
    if (f.cuentaId.isNotEmpty) {
      donde.add('(cuenta_id = ? OR cuenta_destino_id = ?)');
      args..add(f.cuentaId)..add(f.cuentaId);
    }
    if (f.tipo != null) {
      donde.add('tipo = ?');
      args.add(f.tipo!.valor);
    }
    if (f.estado != null) {
      donde.add('estado = ?');
      args.add(f.estado!.valor);
    }
    if (f.texto.trim().isNotEmpty) {
      // Se busca sobre varios campos porque el usuario no sabe (ni deberia
      // saber) en cual de ellos quedo guardado lo que recuerda.
      donde.add(
        '(comercio LIKE ? OR descripcion LIKE ? OR notas LIKE ? OR nro_operacion LIKE ?)',
      );
      final like = '%${f.texto.trim()}%';
      args..add(like)..add(like)..add(like)..add(like);
    }

    final filas = await d.query(
      'movimientos',
      where: donde.isEmpty ? null : donde.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'fecha DESC, hora DESC, id DESC',
      limit: f.limite > 0 ? f.limite : null,
    );
    return filas.map(Movimiento.fromMap).toList();
  }

  Future<Movimiento?> movimiento(String id) async {
    final d = await _db;
    final filas =
        await d.query('movimientos', where: 'id = ?', whereArgs: [id], limit: 1);
    return filas.isEmpty ? null : Movimiento.fromMap(filas.first);
  }

  Future<List<Movimiento>> pendientesRevision() async {
    final d = await _db;
    final filas = await d.query(
      'movimientos',
      where: 'estado = ?',
      whereArgs: [EstadoMovimiento.revisar.valor],
      orderBy: 'fecha DESC, id DESC',
    );
    return filas.map(Movimiento.fromMap).toList();
  }

  Future<void> guardarMovimiento(Movimiento m) async {
    final d = await _db;
    await d.insert(
      'movimientos',
      m.copyWith(fechaModificacion: ahoraLima()).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> guardarMovimientos(List<Movimiento> movs) async {
    if (movs.isEmpty) return;
    final d = await _db;
    final b = d.batch();
    for (final m in movs) {
      b.insert('movimientos', m.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await b.commit(noResult: true);
  }

  /// Baja logica: el movimiento no se borra, se marca. Asi el anti duplicados
  /// sigue reconociendo el correo y no lo vuelve a meter en la proxima corrida.
  Future<void> anularMovimiento(String id, {String motivo = ''}) async {
    final d = await _db;
    await d.update(
      'movimientos',
      {
        'estado': EstadoMovimiento.anulado.valor,
        'motivo_revision': motivo,
        'fecha_modificacion': ahoraLima(),
        'modificado_por': 'USUARIO',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> restaurarMovimiento(String id) async {
    final d = await _db;
    await d.update(
      'movimientos',
      {
        'estado': EstadoMovimiento.ok.valor,
        'motivo_revision': '',
        'fecha_modificacion': ahoraLima(),
        'modificado_por': 'USUARIO',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Anula todos los movimientos de una cuenta. Se usa cuando marcas una cuenta
  /// como "no es mi dinero": lo que ya se registro tambien tiene que salir.
  Future<int> anularMovimientosDeCuenta(String cuentaId) async {
    final d = await _db;
    return d.update(
      'movimientos',
      {
        'estado': EstadoMovimiento.anulado.valor,
        'motivo_revision': 'La cuenta se marco como ajena',
        'fecha_modificacion': ahoraLima(),
        'modificado_por': 'SISTEMA',
      },
      where: 'cuenta_id = ? AND estado != ?',
      whereArgs: [cuentaId, EstadoMovimiento.anulado.valor],
    );
  }

  /// Siguiente id correlativo, con el formato MOV-000123.
  Future<int> ultimoNumeroMovimiento() async {
    final d = await _db;
    final r = await d.rawQuery(
      'SELECT MAX(CAST(SUBSTR(id, 5) AS INTEGER)) AS n '
      "FROM movimientos WHERE id LIKE 'MOV-%'",
    );
    return (r.first['n'] as int?) ?? 0;
  }

  /// Los periodos que tienen algun movimiento, del mas reciente al mas viejo.
  Future<List<String>> periodosDisponibles() async {
    final d = await _db;
    final r = await d.rawQuery(
      'SELECT DISTINCT periodo FROM movimientos '
      'WHERE periodo != '' ORDER BY periodo DESC',
    );
    final lista = r.map((f) => f['periodo'] as String).toList();
    final actual = periodoActual();
    if (!lista.contains(actual)) lista.insert(0, actual);
    return lista;
  }

  /// Indices anti duplicados de una corrida. Se cargan de golpe porque
  /// consultarlos correo por correo seria una consulta por mensaje.
  Future<IndiceDedup> indiceDedup() async {
    final d = await _db;
    final filas = await d.query(
      'movimientos',
      columns: ['email_id', 'hash_dedup', 'banco', 'nro_operacion'],
    );
    final porEmail = <String>{};
    final porHash = <String>{};
    final porOperacion = <String>{};
    for (final f in filas) {
      final email = (f['email_id'] ?? '') as String;
      if (email.isNotEmpty) porEmail.add(email);
      final hash = (f['hash_dedup'] ?? '') as String;
      if (hash.isNotEmpty) porHash.add(hash);
      final nro = (f['nro_operacion'] ?? '') as String;
      if (nro.isNotEmpty) {
        porOperacion.add(norm('${f['banco']}|$nro'));
      }
    }
    return IndiceDedup(porEmail, porHash, porOperacion);
  }

  // ==========================================================================
  //  CUENTAS
  // ==========================================================================

  Future<List<Cuenta>> cuentas({bool soloActivas = false}) async {
    final d = await _db;
    final filas = await d.query(
      'cuentas',
      where: soloActivas ? 'activa = 1' : null,
      orderBy: 'tipo, nombre',
    );
    return filas.map(Cuenta.fromMap).toList();
  }

  Future<void> guardarCuenta(Cuenta c) async {
    final d = await _db;
    await d.insert('cuentas', c.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> eliminarCuenta(String id) async {
    final d = await _db;
    await d.delete('cuentas', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================================================
  //  CATEGORIAS
  // ==========================================================================

  Future<List<Categoria>> categorias({bool soloActivas = true}) async {
    final d = await _db;
    final filas = await d.query(
      'categorias',
      where: soloActivas ? 'activa = 1' : null,
      orderBy: 'orden, categoria, subcategoria',
    );
    return filas.map(Categoria.fromMap).toList();
  }

  Future<void> guardarCategoria(Categoria c) async {
    final d = await _db;
    await d.insert('categorias', c.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Renombra una categoria y arrastra el cambio a los movimientos que ya la
  /// usaban y a las reglas que la producian. Sin esto, renombrar partiria el
  /// historial en dos.
  Future<void> renombrarCategoria({
    required String antesCategoria,
    required String antesSubcategoria,
    required Categoria nueva,
  }) async {
    final d = await _db;
    await d.transaction((tx) async {
      await tx.delete(
        'categorias',
        where: 'categoria = ? AND subcategoria = ?',
        whereArgs: [antesCategoria, antesSubcategoria],
      );
      await tx.insert('categorias', nueva.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);

      await tx.update(
        'movimientos',
        {'categoria': nueva.categoria, 'subcategoria': nueva.subcategoria},
        where: 'categoria = ? AND subcategoria = ?',
        whereArgs: [antesCategoria, antesSubcategoria],
      );
      await tx.update(
        'reglas',
        {'categoria': nueva.categoria, 'subcategoria': nueva.subcategoria},
        where: 'categoria = ? AND subcategoria = ?',
        whereArgs: [antesCategoria, antesSubcategoria],
      );
      await tx.update(
        'presupuesto',
        {'categoria': nueva.categoria, 'subcategoria': nueva.subcategoria},
        where: 'categoria = ? AND subcategoria = ?',
        whereArgs: [antesCategoria, antesSubcategoria],
      );
    });
  }

  Future<void> eliminarCategoria(String categoria, String subcategoria) async {
    final d = await _db;
    await d.delete(
      'categorias',
      where: 'categoria = ? AND subcategoria = ?',
      whereArgs: [categoria, subcategoria],
    );
  }

  // ==========================================================================
  //  REGLAS
  // ==========================================================================

  Future<List<Regla>> reglas() async {
    final d = await _db;
    final filas = await d.query('reglas', orderBy: 'prioridad, id');
    return filas.map(Regla.fromMap).toList();
  }

  Future<void> guardarRegla(Regla r) async {
    final d = await _db;
    await d.insert('reglas', r.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> eliminarRegla(String id) async {
    final d = await _db;
    await d.delete('reglas', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> sumarAcierto(String reglaId) async {
    if (reglaId.isEmpty) return;
    final d = await _db;
    await d.rawUpdate(
      'UPDATE reglas SET aciertos = aciertos + 1 WHERE id = ?',
      [reglaId],
    );
  }

  Future<String> siguienteIdRegla() async {
    final d = await _db;
    final r = await d.rawQuery(
      'SELECT MAX(CAST(SUBSTR(id, 5) AS INTEGER)) AS n '
      "FROM reglas WHERE id LIKE 'REG-%'",
    );
    final n = ((r.first['n'] as int?) ?? 0) + 1;
    return 'REG-${pad(n, 3)}';
  }

  // ==========================================================================
  //  REMITENTES
  // ==========================================================================

  Future<List<Remitente>> remitentes({bool soloActivos = false}) async {
    final d = await _db;
    final filas = await d.query(
      'remitentes',
      where: soloActivos ? 'activo = 1' : null,
      orderBy: 'banco, remitente',
    );
    return filas.map(Remitente.fromMap).toList();
  }

  Future<void> guardarRemitente(Remitente r) async {
    final d = await _db;
    await d.insert('remitentes', r.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ==========================================================================
  //  PRESUPUESTO
  // ==========================================================================

  Future<List<LineaPresupuesto>> presupuesto(String periodo) async {
    final d = await _db;
    final filas = await d.query(
      'presupuesto',
      where: 'periodo = ?',
      whereArgs: [periodo],
      orderBy: 'categoria, subcategoria',
    );
    return filas.map(LineaPresupuesto.fromMap).toList();
  }

  Future<void> guardarPresupuesto(
      String periodo, List<LineaPresupuesto> lineas) async {
    final d = await _db;
    await d.transaction((tx) async {
      await tx.delete('presupuesto', where: 'periodo = ?', whereArgs: [periodo]);
      for (final l in lineas) {
        if (l.monto <= 0) continue;
        await tx.insert('presupuesto', l.toMap());
      }
    });
  }

  /// Copia el presupuesto de un mes a otro. No pisa lo que ya exista en el
  /// destino: se asume que si ya escribiste algo ahi, fue a proposito.
  Future<int> copiarPresupuesto(String desde, String hasta) async {
    final origen = await presupuesto(desde);
    if (origen.isEmpty) return 0;
    final actual = await presupuesto(hasta);
    final yaHay = actual.map((l) => l.clave).toSet();

    final nuevas = origen
        .where((l) => !yaHay.contains(l.clave))
        .map((l) => LineaPresupuesto(
              periodo: hasta,
              categoria: l.categoria,
              subcategoria: l.subcategoria,
              moneda: l.moneda,
              monto: l.monto,
              notas: l.notas,
            ))
        .toList();

    if (nuevas.isEmpty) return 0;
    final d = await _db;
    final b = d.batch();
    for (final l in nuevas) {
      b.insert('presupuesto', l.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await b.commit(noResult: true);
    return nuevas.length;
  }

  // ==========================================================================
  //  INGRESOS RECURRENTES
  // ==========================================================================

  Future<List<PlantillaIngreso>> plantillas({bool soloActivas = true}) async {
    final d = await _db;
    final filas = await d.query(
      'plantillas_ingreso',
      where: soloActivas ? 'activo = 1' : null,
      orderBy: 'orden, nombre',
    );
    return filas.map(PlantillaIngreso.fromMap).toList();
  }

  Future<void> guardarPlantilla(PlantillaIngreso p) async {
    final d = await _db;
    await d.insert('plantillas_ingreso', p.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> eliminarPlantilla(String id) async {
    final d = await _db;
    await d.delete('plantillas_ingreso', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================================================
  //  PATRIMONIO
  // ==========================================================================

  Future<List<FotoPatrimonio>> patrimonio({int limite = 24}) async {
    final d = await _db;
    final filas =
        await d.query('patrimonio', orderBy: 'fecha DESC', limit: limite);
    return filas.map(FotoPatrimonio.fromMap).toList();
  }

  Future<FotoPatrimonio?> ultimaFotoPatrimonio() async {
    final lista = await patrimonio(limite: 1);
    return lista.isEmpty ? null : lista.first;
  }

  Future<void> guardarPatrimonio(FotoPatrimonio f) async {
    final d = await _db;
    await d.insert('patrimonio', f.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ==========================================================================
  //  INVERSIONES
  // ==========================================================================

  Future<List<Inversion>> inversiones() async {
    final d = await _db;
    final filas = await d.query('inversiones', orderBy: 'fecha DESC, id DESC');
    return filas.map(Inversion.fromMap).toList();
  }

  Future<void> guardarInversion(Inversion i) async {
    final d = await _db;
    await d.insert('inversiones', i.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> eliminarInversion(String id) async {
    final d = await _db;
    await d.delete('inversiones', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ActivoInversion>> activos() async {
    final d = await _db;
    final filas = await d.query('activos', orderBy: 'simbolo');
    return filas.map(ActivoInversion.fromMap).toList();
  }

  Future<void> guardarActivo(ActivoInversion a) async {
    final d = await _db;
    await d.insert('activos', a.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ==========================================================================
  //  TIPO DE CAMBIO
  // ==========================================================================

  Future<double?> tipoCambioDe(String fecha, {String par = 'USDPEN'}) async {
    final d = await _db;
    // Se acepta el TC mas reciente ANTERIOR a la fecha pedida: los fines de
    // semana y feriados no tienen cotizacion, y un gasto del domingo se valua
    // con el viernes, no con nada.
    final filas = await d.query(
      'tipo_cambio',
      where: 'par = ? AND fecha <= ?',
      whereArgs: [par, fecha],
      orderBy: 'fecha DESC',
      limit: 1,
    );
    if (filas.isEmpty) return null;
    final venta = (filas.first['venta'] as num?)?.toDouble() ?? 0;
    final compra = (filas.first['compra'] as num?)?.toDouble() ?? 0;
    final tc = venta > 0 ? venta : compra;
    return tc > 0 ? tc : null;
  }

  Future<void> guardarTipoCambio({
    required String fecha,
    required double compra,
    required double venta,
    String par = 'USDPEN',
    String fuente = '',
  }) async {
    final d = await _db;
    await d.insert(
      'tipo_cambio',
      {
        'fecha': fecha,
        'par': par,
        'compra': compra,
        'venta': venta,
        'fuente': fuente,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ==========================================================================
  //  CONFIG
  // ==========================================================================

  Future<Map<String, String>> config() async {
    final d = await _db;
    final filas = await d.query('config');
    return {
      for (final f in filas)
        (f['clave'] ?? '') as String: (f['valor'] ?? '') as String,
    };
  }

  Future<void> guardarConfig(String clave, String valor) async {
    final d = await _db;
    final n = await d.update('config', {'valor': valor},
        where: 'clave = ?', whereArgs: [clave]);
    if (n == 0) {
      await d.insert('config', {'clave': clave, 'valor': valor});
    }
  }

  // ==========================================================================
  //  LOG
  // ==========================================================================

  Future<void> registrar(
    String nivel,
    String proceso,
    String mensaje, [
    String detalle = '',
  ]) async {
    final d = await _db;
    await d.insert('log', {
      'timestamp': ahoraLima(),
      'nivel': nivel,
      'proceso': proceso,
      'mensaje': mensaje,
      'detalle': detalle,
    });
    // El log es para diagnostico, no es historial: se recorta solo para que no
    // crezca sin limite en el telefono.
    await d.rawDelete(
      'DELETE FROM log WHERE id NOT IN '
      '(SELECT id FROM log ORDER BY id DESC LIMIT 500)',
    );
  }

  Future<List<Map<String, Object?>>> log({int limite = 100}) async {
    final d = await _db;
    return d.query('log', orderBy: 'id DESC', limit: limite);
  }
}

/// Las tres capas anti duplicados, precargadas para una corrida de ingesta.
class IndiceDedup {
  const IndiceDedup(this.porEmail, this.porHash, this.porOperacion);

  /// Capa 1: el id del mensaje de Gmail. La mas fuerte.
  final Set<String> porEmail;

  /// Capa 3: huella de banco + dia + importe + comercio + tarjeta.
  final Set<String> porHash;

  /// Capa 2: banco + numero de operacion del banco.
  final Set<String> porOperacion;
}
