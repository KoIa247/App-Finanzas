import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../core/fechas.dart';
import 'semilla.dart';

/// La base local. Todo vive en el telefono: nada sale hacia un servidor.
///
/// Sin generacion de codigo a proposito. El esquema es chico y estable, y
/// escribir el SQL a mano evita que arrancar el proyecto dependa de correr
/// build_runner.
class BaseDatos {
  BaseDatos._();

  static final BaseDatos instancia = BaseDatos._();

  static const int _version = 3;

  Database? _db;

  Future<Database> get db async => _db ??= await _abrir();

  Future<Database> _abrir() async {
    final dir = await getDatabasesPath();
    final ruta = p.join(dir, 'leep.db');
    await _heredarDeMateito(dir, ruta);
    return openDatabase(
      ruta,
      version: _version,
      onConfigure: (d) => d.execute('PRAGMA foreign_keys = ON'),
      onCreate: (d, v) async {
        await _crearEsquema(d);
        await _sembrar(d);
      },
      onUpgrade: _migrar,
    );
  }

  /// La app se llamaba mateito y su base era mateito.db. Si las dos bases
  /// comparten carpeta, movemos la vieja para no perder el historial.
  ///
  /// Ojo con el alcance: en el telefono esto solo sirve si el id de la app no
  /// cambio. Al pasar de com.mateito.mateito a com.leep.leep, Android le da a
  /// Leep un sandbox nuevo y mateito.db se queda en el del otro paquete, fuera
  /// de alcance. Sirve entonces para escritorio, pruebas y cualquier instalacion
  /// que haya conservado el id. Pasa una sola vez: si ya hay leep.db, no toca nada.
  Future<void> _heredarDeMateito(String dir, String rutaNueva) async {
    if (await databaseExists(rutaNueva)) return;
    final rutaVieja = p.join(dir, 'mateito.db');
    if (!await databaseExists(rutaVieja)) return;
    await File(rutaVieja).rename(rutaNueva);
  }

  /// Cada salto va aqui con su propio if, nunca un borrar y recrear: la base
  /// del usuario es su historial y no se puede perder.
  Future<void> _migrar(Database d, int desde, int hasta) async {
    if (desde < 2) await _v2MonedaEnPresupuesto(d);
    if (desde < 3) await _v3ColoresDeLeep(d);
  }

  /// v3: las categorias pasan a los colores de Leep.
  ///
  /// La semilla solo corre al crear la base, asi que quien ya tenia la app
  /// instalada se quedaba con la paleta vieja y veia los graficos en morado y
  /// naranja mientras el resto de la app ya era verde.
  ///
  /// Solo se tocan las filas que siguen teniendo el color de fabrica viejo:
  /// si alguien le cambio el color a una categoria, esa eleccion se respeta.
  Future<void> _v3ColoresDeLeep(Database d) async {
    const equivalencias = <String, String>{
      '#F97316': '#9E4420', // Alimentacion
      '#0EA5E9': '#0A6360', // Transporte
      '#8B5CF6': '#22306B', // Vivienda
      '#10B981': '#1E5A37', // Salud
      '#6366F1': '#C87A3E', // Suscripciones
      '#EC4899': '#D4607A', // Entretenimiento
      '#F59E0B': '#E08B5B', // Compras
      '#14B8A6': '#3FB8AE', // Envios a personas
      '#64748B': '#17191A', // Financiero
      '#22C55E': '#86C79A', // Ingresos
      '#3B82F6': '#0E807C', // Inversiones
      '#94A3B8': '#A19786', // Sin clasificar y movimientos internos
    };

    final b = d.batch();
    equivalencias.forEach((viejo, nuevo) {
      b.update(
        'categorias',
        {'color': nuevo},
        where: 'color = ?',
        whereArgs: [viejo],
      );
    });

    // Leep le da tono propio a estas dos dentro de Alimentacion.
    b.update('categorias', {'color': '#E08B5B'},
        where: 'subcategoria = ? AND color = ?',
        whereArgs: ['Delivery', '#9E4420']);
    b.update('categorias', {'color': '#C87A3E'},
        where: 'subcategoria = ? AND color = ?',
        whereArgs: ['Cafeteria', '#9E4420']);

    // El color y el icono de una categoria salen de su primera subcategoria
    // por orden. En Alimentacion esa era Delivery, asi que la categoria entera
    // se pintaba con su tono claro en vez del suyo. El plato va primero.
    b.update('categorias', {'orden': 11},
        where: 'categoria = ? AND subcategoria = ?',
        whereArgs: ['Alimentacion', 'Delivery']);
    b.update('categorias', {'orden': 10},
        where: 'categoria = ? AND subcategoria = ?',
        whereArgs: ['Alimentacion', 'Restaurantes']);

    await b.commit(noResult: true);
  }

  /// v2: la moneda entra en la clave del presupuesto.
  ///
  /// Cada moneda lleva su propio presupuesto, asi que la fila ya no se
  /// identifica por periodo mas categoria: hacen falta las dos cosas y la
  /// moneda. SQLite no sabe cambiar una clave primaria, asi que toca
  /// reconstruir la tabla y copiar.
  ///
  /// Las filas que ya existian se quedan donde estan: nacieron cuando todo se
  /// consolidaba a soles, asi que son presupuesto en soles. La columna ya
  /// traia 'PEN' por defecto, pero se normaliza igual por si alguna quedo
  /// vacia o en nulo.
  Future<void> _v2MonedaEnPresupuesto(Database d) async {
    await d.transaction((tx) async {
      await tx.execute('''
        CREATE TABLE presupuesto_v2 (
          periodo      TEXT NOT NULL,
          categoria    TEXT NOT NULL,
          subcategoria TEXT NOT NULL DEFAULT '',
          moneda       TEXT NOT NULL DEFAULT 'PEN',
          monto        REAL DEFAULT 0,
          notas        TEXT DEFAULT '',
          PRIMARY KEY (periodo, categoria, subcategoria, moneda)
        )
      ''');
      await tx.execute('''
        INSERT OR IGNORE INTO presupuesto_v2
          (periodo, categoria, subcategoria, moneda, monto, notas)
        SELECT periodo, categoria, subcategoria,
               CASE WHEN moneda IS NULL OR moneda = '' THEN 'PEN' ELSE moneda END,
               monto, notas
        FROM presupuesto
      ''');
      await tx.execute('DROP TABLE presupuesto');
      await tx.execute('ALTER TABLE presupuesto_v2 RENAME TO presupuesto');
    });
  }

  Future<void> _crearEsquema(Database d) async {
    final b = d.batch();

    b.execute('''
      CREATE TABLE movimientos (
        id                 TEXT PRIMARY KEY,
        fecha              TEXT NOT NULL,
        hora               TEXT DEFAULT '',
        periodo            TEXT NOT NULL,
        tipo               TEXT NOT NULL,
        importe            REAL NOT NULL DEFAULT 0,
        moneda             TEXT NOT NULL DEFAULT 'PEN',
        comercio           TEXT DEFAULT '',
        descripcion        TEXT DEFAULT '',
        categoria          TEXT DEFAULT '',
        subcategoria       TEXT DEFAULT '',
        banco              TEXT DEFAULT '',
        cuenta_id          TEXT DEFAULT '',
        medio_pago         TEXT DEFAULT '',
        tipo_cambio        REAL,
        importe_pen        REAL NOT NULL DEFAULT 0,
        fuente             TEXT DEFAULT 'MANUAL',
        email_id           TEXT DEFAULT '',
        nro_operacion      TEXT DEFAULT '',
        hash_dedup         TEXT DEFAULT '',
        estado             TEXT NOT NULL DEFAULT 'OK',
        motivo_revision    TEXT DEFAULT '',
        recurrente         INTEGER DEFAULT 0,
        cuenta_destino_id  TEXT DEFAULT '',
        movimiento_rel     TEXT DEFAULT '',
        notas              TEXT DEFAULT '',
        fecha_creacion     TEXT DEFAULT '',
        fecha_modificacion TEXT DEFAULT '',
        modificado_por     TEXT DEFAULT ''
      )
    ''');

    // Los tres indices que sostienen el anti duplicados. Sin ellos, cada correo
    // nuevo obligaria a recorrer todo el historial.
    b.execute('CREATE INDEX ix_mov_periodo ON movimientos(periodo)');
    b.execute('CREATE INDEX ix_mov_fecha ON movimientos(fecha)');
    b.execute('CREATE INDEX ix_mov_email ON movimientos(email_id)');
    b.execute('CREATE INDEX ix_mov_hash ON movimientos(hash_dedup)');
    b.execute('CREATE INDEX ix_mov_estado ON movimientos(estado)');
    b.execute(
        'CREATE INDEX ix_mov_operacion ON movimientos(banco, nro_operacion)');

    b.execute('''
      CREATE TABLE cuentas (
        id                  TEXT PRIMARY KEY,
        nombre              TEXT NOT NULL,
        banco               TEXT DEFAULT '',
        tipo                TEXT DEFAULT '',
        moneda              TEXT DEFAULT 'PEN',
        ultimos4            TEXT DEFAULT '',
        saldo_inicial       REAL DEFAULT 0,
        fecha_saldo_inicial TEXT DEFAULT '',
        linea_credito       REAL DEFAULT 0,
        dia_cierre          INTEGER,
        dia_pago            INTEGER,
        activa              INTEGER DEFAULT 1,
        notas               TEXT DEFAULT '',
        es_propia           INTEGER DEFAULT 1
      )
    ''');
    b.execute('CREATE INDEX ix_cuentas_u4 ON cuentas(ultimos4)');

    b.execute('''
      CREATE TABLE categorias (
        categoria      TEXT NOT NULL,
        subcategoria   TEXT NOT NULL,
        tipo_aplicable TEXT DEFAULT 'GASTO',
        icono          TEXT DEFAULT '',
        color          TEXT DEFAULT '#94A3B8',
        activa         INTEGER DEFAULT 1,
        orden          INTEGER DEFAULT 999,
        PRIMARY KEY (categoria, subcategoria)
      )
    ''');

    b.execute('''
      CREATE TABLE reglas (
        id             TEXT PRIMARY KEY,
        prioridad      INTEGER DEFAULT 100,
        activa         INTEGER DEFAULT 1,
        campo          TEXT DEFAULT 'comercio',
        operador       TEXT DEFAULT 'contiene',
        valor          TEXT DEFAULT '',
        tipo_resultado TEXT DEFAULT '',
        categoria      TEXT DEFAULT '',
        subcategoria   TEXT DEFAULT '',
        cuenta_destino TEXT DEFAULT '',
        recurrente     INTEGER DEFAULT 0,
        origen         TEXT DEFAULT 'MANUAL',
        aciertos       INTEGER DEFAULT 0,
        fecha_creacion TEXT DEFAULT ''
      )
    ''');
    b.execute('CREATE INDEX ix_reglas_prioridad ON reglas(prioridad)');

    b.execute('''
      CREATE TABLE remitentes (
        remitente TEXT PRIMARY KEY,
        banco     TEXT DEFAULT '',
        parser    TEXT DEFAULT 'GENERICO',
        activo    INTEGER DEFAULT 1,
        notas     TEXT DEFAULT ''
      )
    ''');

    b.execute('''
      CREATE TABLE presupuesto (
        periodo      TEXT NOT NULL,
        categoria    TEXT NOT NULL,
        subcategoria TEXT NOT NULL DEFAULT '',
        moneda       TEXT NOT NULL DEFAULT 'PEN',
        monto        REAL DEFAULT 0,
        notas        TEXT DEFAULT '',
        PRIMARY KEY (periodo, categoria, subcategoria, moneda)
      )
    ''');

    b.execute('''
      CREATE TABLE inversiones (
        id              TEXT PRIMARY KEY,
        fecha           TEXT NOT NULL,
        tipo            TEXT DEFAULT 'COMPRA',
        activo          TEXT DEFAULT '',
        cuenta_id       TEXT DEFAULT '',
        cantidad        REAL DEFAULT 0,
        precio_unitario REAL DEFAULT 0,
        importe         REAL DEFAULT 0,
        moneda          TEXT DEFAULT 'USD',
        comision        REAL DEFAULT 0,
        movimiento_rel  TEXT DEFAULT '',
        notas           TEXT DEFAULT '',
        fecha_creacion  TEXT DEFAULT ''
      )
    ''');

    b.execute('''
      CREATE TABLE activos (
        simbolo       TEXT PRIMARY KEY,
        nombre        TEXT DEFAULT '',
        clase         TEXT DEFAULT 'ACCION',
        moneda        TEXT DEFAULT 'USD',
        precio_actual REAL DEFAULT 0,
        fecha_precio  TEXT DEFAULT '',
        fuente_precio TEXT DEFAULT 'MANUAL',
        activo        INTEGER DEFAULT 1
      )
    ''');

    b.execute('''
      CREATE TABLE plantillas_ingreso (
        id             TEXT PRIMARY KEY,
        nombre         TEXT NOT NULL,
        categoria      TEXT DEFAULT 'Ingresos',
        subcategoria   TEXT DEFAULT 'Otros',
        monto_sugerido REAL DEFAULT 0,
        moneda         TEXT DEFAULT 'PEN',
        cuenta_id      TEXT DEFAULT '',
        dia_aproximado INTEGER DEFAULT 0,
        frecuencia     TEXT DEFAULT 'EVENTUAL',
        activo         INTEGER DEFAULT 1,
        orden          INTEGER DEFAULT 99
      )
    ''');

    b.execute('''
      CREATE TABLE patrimonio (
        fecha             TEXT PRIMARY KEY,
        liquidez_pen      REAL DEFAULT 0,
        liquidez_usd      REAL DEFAULT 0,
        deuda_tarjeta_pen REAL DEFAULT 0,
        deuda_tarjeta_usd REAL DEFAULT 0,
        otros_activos_pen REAL DEFAULT 0,
        otros_pasivos_pen REAL DEFAULT 0,
        notas             TEXT DEFAULT '',
        registrado        TEXT DEFAULT 'MANUAL'
      )
    ''');

    b.execute('''
      CREATE TABLE tipo_cambio (
        fecha  TEXT NOT NULL,
        par    TEXT NOT NULL DEFAULT 'USDPEN',
        compra REAL DEFAULT 0,
        venta  REAL DEFAULT 0,
        fuente TEXT DEFAULT '',
        PRIMARY KEY (fecha, par)
      )
    ''');

    b.execute('''
      CREATE TABLE config (
        clave       TEXT PRIMARY KEY,
        valor       TEXT DEFAULT '',
        descripcion TEXT DEFAULT ''
      )
    ''');

    b.execute('''
      CREATE TABLE log (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        nivel     TEXT DEFAULT 'INFO',
        proceso   TEXT DEFAULT '',
        mensaje   TEXT DEFAULT '',
        detalle   TEXT DEFAULT ''
      )
    ''');

    await b.commit(noResult: true);
  }

  Future<void> _sembrar(Database d) async {
    final b = d.batch();

    for (final c in categoriasSemilla) {
      b.insert('categorias', c.toMap());
    }
    for (final r in reglasSemilla) {
      b.insert('reglas', {...r.toMap(), 'fecha_creacion': ahoraLima()});
    }
    for (final r in remitentesSemilla) {
      b.insert('remitentes', r.toMap());
    }
    for (final c in cuentasSemilla) {
      b.insert('cuentas', c.toMap());
    }
    for (final pl in plantillasSemilla) {
      b.insert('plantillas_ingreso', pl.toMap());
    }
    configSemilla.forEach((clave, v) {
      b.insert('config', {
        'clave': clave,
        'valor': v[0],
        'descripcion': v[1],
      });
    });

    await b.commit(noResult: true);
  }

  /// Cierra la base. Solo hace falta en pruebas.
  Future<void> cerrar() async {
    await _db?.close();
    _db = null;
  }

  /// Borra todo y vuelve a sembrar. Es la opcion "empezar de cero".
  Future<void> reiniciar() async {
    final d = await db;
    final tablas = [
      'movimientos', 'cuentas', 'categorias', 'reglas', 'remitentes',
      'presupuesto', 'inversiones', 'activos', 'plantillas_ingreso',
      'patrimonio', 'tipo_cambio', 'config', 'log',
    ];
    final b = d.batch();
    for (final t in tablas) {
      b.delete(t);
    }
    await b.commit(noResult: true);
    await _sembrar(d);
  }
}
