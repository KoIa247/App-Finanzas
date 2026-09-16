import '../../core/fechas.dart';
import '../../core/numeros.dart';
import '../../core/texto.dart';
import '../../domain/catalogo.dart';
import '../../domain/enums.dart';
import '../../domain/finanzas.dart';
import '../../domain/movimiento.dart';
import '../clasificador/motor_reglas.dart';
import '../clasificador/suscripciones.dart';
import '../fx/tipo_cambio.dart';
import '../parser/contexto.dart';
import 'dao.dart';
import 'vistas.dart';

/// La capa que la interfaz consume. Toma datos del [Dao] y los convierte en las
/// vistas que cada pantalla necesita.
class Repositorio {
  Repositorio(this.dao, this.fx);

  final Dao dao;
  final ServicioTipoCambio fx;

  // ==========================================================================
  //  DASHBOARD
  // ==========================================================================

  Future<DatosDashboard> dashboard(String periodo) async {
    final config = await dao.config();
    final respaldoTc =
        double.tryParse(config['tc_por_defecto'] ?? '3.75') ?? 3.75;
    final tc = await fx.para(hoyLima(), respaldo: respaldoTc);

    final cuentas = await dao.cuentas();
    final categorias = await dao.categorias();
    final delMes = await dao.movimientos(FiltroMovimientos(periodo: periodo));
    final todos = await dao.movimientos();

    final ingresos = _suma(delMes, (m) => m.ingresoPen);
    final gastos = _suma(delMes, (m) => m.gastoPen);

    final lineas = await dao.presupuesto(periodo);
    final presupuestado = lineas.fold(0.0, (a, l) => a + l.monto);

    return DatosDashboard(
      periodo: periodo,
      ingresos: redondear(ingresos),
      gastos: redondear(gastos),
      presupuestado: redondear(presupuestado),
      porCategoria: _porCategoria(delMes, categorias),
      porMedio: _porMedio(delMes, cuentas),
      evolucion: _evolucion(todos, periodo, 12),
      ultimos: delMes.take(8).toList(),
      posicion: await _posicion(tc),
      avances: await avancesPresupuesto(periodo),
      proximosPagos: _proximosPagos(cuentas, delMes),
      suscripciones: detectarSuscripciones(
        todos,
        forzadas: _lista(config['suscripciones_si']),
        excluidas: _lista(config['suscripciones_no']),
      ),
      cobertura: _cobertura(delMes, periodo),
      pendientes: (await dao.pendientesRevision()).length,
    );
  }

  double _suma(List<Movimiento> movs, double Function(Movimiento) f) =>
      movs.fold(0.0, (a, m) => a + f(m));

  List<String> _lista(String? v) => (v ?? '')
      .split(',')
      .map((x) => x.trim())
      .where((x) => x.isNotEmpty)
      .toList();

  List<CorteCategoria> _porCategoria(
    List<Movimiento> movs,
    List<Categoria> categorias,
  ) {
    final colores = <String, String>{};
    final iconos = <String, String>{};
    for (final c in categorias) {
      colores.putIfAbsent(c.categoria, () => c.color);
      iconos.putIfAbsent(c.categoria, () => c.icono);
    }

    final totales = <String, double>{};
    final cuentas = <String, int>{};
    for (final m in movs) {
      final g = m.gastoPen;
      if (g == 0) continue;
      final k = m.categoria.isEmpty ? 'Sin clasificar' : m.categoria;
      totales[k] = (totales[k] ?? 0) + g;
      cuentas[k] = (cuentas[k] ?? 0) + 1;
    }

    final out = totales.entries
        .where((e) => e.value > 0)
        .map((e) => CorteCategoria(
              categoria: e.key,
              monto: redondear(e.value),
              color: colores[e.key] ?? '#94A3B8',
              icono: iconos[e.key] ?? '',
              movimientos: cuentas[e.key] ?? 0,
            ))
        .toList()
      ..sort((a, b) => b.monto.compareTo(a.monto));
    return out;
  }

  /// Cuanto consumiste con cada medio de pago.
  ///
  /// Los pagos de tarjeta y las transferencias entre cuentas propias no cuentan
  /// aqui porque no son consumo: mover plata de un bolsillo a otro no es gastar.
  List<ConsumoMedio> _porMedio(List<Movimiento> movs, List<Cuenta> cuentas) {
    final totales = <String, double>{};
    final conteo = <String, int>{};

    for (final m in movs) {
      if (m.gastoPen <= 0) continue;
      final k = m.cuentaId.isEmpty ? '(sin cuenta)' : m.cuentaId;
      totales[k] = (totales[k] ?? 0) + m.gastoPen;
      conteo[k] = (conteo[k] ?? 0) + 1;
    }

    final porId = {for (final c in cuentas) c.id: c};
    final out = totales.entries.map((e) {
      final c = porId[e.key];
      return ConsumoMedio(
        cuentaId: e.key,
        nombre: c?.nombre ?? 'Sin cuenta asignada',
        tipo: c?.tipo ?? '',
        monto: redondear(e.value),
        ultimos4: c?.ultimos4 ?? '',
        movimientos: conteo[e.key] ?? 0,
        lineaCredito: c?.lineaCredito ?? 0,
        diaPago: c?.diaPago,
      );
    }).toList()
      ..sort((a, b) => b.monto.compareTo(a.monto));
    return out;
  }

  List<PuntoMes> _evolucion(List<Movimiento> movs, String hasta, int n) {
    final periodos = <String>[];
    var p = hasta;
    for (var i = 0; i < n; i++) {
      periodos.insert(0, p);
      p = periodoAnterior(p);
    }

    final ingresos = <String, double>{};
    final gastos = <String, double>{};
    for (final m in movs) {
      final k = m.periodo;
      ingresos[k] = (ingresos[k] ?? 0) + m.ingresoPen;
      gastos[k] = (gastos[k] ?? 0) + m.gastoPen;
    }

    return periodos
        .map((k) => PuntoMes(
              periodo: k,
              ingresos: redondear(ingresos[k] ?? 0),
              gastos: redondear(gastos[k] ?? 0),
            ))
        .toList();
  }

  /// Los pagos de tarjeta que se vienen, ordenados por cercania.
  List<ProximoPago> _proximosPagos(
    List<Cuenta> cuentas,
    List<Movimiento> delMes,
  ) {
    final hoy = hoyLima();
    final dia = int.tryParse(hoy.substring(8, 10)) ?? 1;
    final anio = int.tryParse(hoy.substring(0, 4)) ?? 2026;
    final mes = int.tryParse(hoy.substring(5, 7)) ?? 1;
    final largoMes = diasDelMes(anio, mes);

    final consumo = <String, double>{};
    for (final m in delMes) {
      if (m.gastoPen <= 0 || m.cuentaId.isEmpty) continue;
      consumo[m.cuentaId] = (consumo[m.cuentaId] ?? 0) + m.gastoPen;
    }

    final out = cuentas
        .where((c) => c.esTarjetaCredito && c.activa && (c.diaPago ?? 0) > 0)
        .map((c) {
      final diaPago = c.diaPago!;
      // Si el dia de pago de este mes ya paso, el proximo es el del mes que
      // viene: se cuentan los dias que faltan para cerrar el mes mas ese dia.
      final faltan =
          diaPago >= dia ? diaPago - dia : (largoMes - dia) + diaPago;
      return ProximoPago(
        cuentaId: c.id,
        nombre: c.nombre,
        diaPago: diaPago,
        diasRestantes: faltan,
        consumoDelMes: redondear(consumo[c.id] ?? 0),
      );
    }).toList()
      ..sort((a, b) => a.diasRestantes.compareTo(b.diasRestantes));
    return out;
  }

  Cobertura _cobertura(List<Movimiento> movs, String periodo) {
    final anio = int.tryParse(periodo.substring(0, 4)) ?? 2026;
    final mes =
        periodo.length >= 7 ? (int.tryParse(periodo.substring(5, 7)) ?? 1) : 1;
    final hoy = hoyLima();

    // Para el mes en curso solo cuentan los dias transcurridos: reprocharle al
    // usuario que le falten los correos del 25 cuando hoy es 9 seria absurdo.
    final total = periodo == periodoActual()
        ? (int.tryParse(hoy.substring(8, 10)) ?? 1)
        : diasDelMes(anio, mes);

    final dias = movs.map((m) => m.fecha).toSet();
    final porCorreo = movs.where((m) => m.fuente == Fuente.email).length;

    return Cobertura(
      diasConMovimiento: dias.length,
      diasDelPeriodo: total,
      movimientosPorCorreo: porCorreo,
      movimientosManuales: movs.length - porCorreo,
    );
  }

  Future<PosicionConsolidada> _posicion(double tc) async {
    final foto = await dao.ultimaFotoPatrimonio();
    final inversiones = await posiciones();
    final invPen = inversiones.fold(0.0, (a, p) {
      final v = p.valorActual;
      return a + (p.moneda == 'PEN' ? v : v * tc);
    });

    if (foto == null) {
      return PosicionConsolidada(
        fecha: '',
        liquidezPen: 0,
        deudaPen: 0,
        inversionesPen: redondear(invPen),
        neto: redondear(invPen),
        tipoCambio: tc,
        hayFoto: false,
      );
    }

    final liquidez = foto.liquidezPen + foto.liquidezUsd * tc;
    final deuda = foto.deudaTarjetaPen +
        foto.deudaTarjetaUsd * tc +
        foto.otrosPasivosPen;

    return PosicionConsolidada(
      fecha: foto.fecha,
      liquidezPen: redondear(liquidez + foto.otrosActivosPen),
      deudaPen: redondear(deuda),
      inversionesPen: redondear(invPen),
      neto: redondear(foto.netoPen(tc, inversionesPen: invPen)),
      tipoCambio: tc,
      notas: foto.notas,
    );
  }

  // ==========================================================================
  //  PRESUPUESTO
  // ==========================================================================

  Future<List<AvancePresupuesto>> avancesPresupuesto(String periodo) async {
    final lineas = await dao.presupuesto(periodo);
    final movs = await dao.movimientos(FiltroMovimientos(periodo: periodo));
    final categorias = await dao.categorias();

    final estilo = {for (final c in categorias) c.categoria: c};

    // El gasto se acumula por categoria y tambien por categoria+subcategoria,
    // porque una linea de presupuesto puede apuntar a cualquiera de las dos.
    final porCategoria = <String, double>{};
    final porSub = <String, double>{};
    for (final m in movs) {
      final g = m.gastoPen;
      if (g == 0) continue;
      porCategoria[m.categoria] = (porCategoria[m.categoria] ?? 0) + g;
      porSub['${m.categoria}|${m.subcategoria}'] =
          (porSub['${m.categoria}|${m.subcategoria}'] ?? 0) + g;
    }

    return lineas.map((l) {
      final gastado = l.subcategoria.isEmpty
          ? (porCategoria[l.categoria] ?? 0)
          : (porSub[l.clave] ?? 0);
      final c = estilo[l.categoria];
      return AvancePresupuesto(
        categoria: l.categoria,
        subcategoria: l.subcategoria,
        presupuestado: l.monto,
        gastado: redondear(gastado),
        icono: c?.icono ?? '',
        color: c?.color ?? '#94A3B8',
      );
    }).toList()
      ..sort((a, b) => b.porcentaje.compareTo(a.porcentaje));
  }

  /// Las categorias en las que gastaste sin haberles puesto presupuesto.
  Future<List<CorteCategoria>> gastoSinPresupuesto(String periodo) async {
    final lineas = await dao.presupuesto(periodo);
    final conPresupuesto = lineas.map((l) => l.categoria).toSet();
    final movs = await dao.movimientos(FiltroMovimientos(periodo: periodo));
    final categorias = await dao.categorias();

    final todos = _porCategoria(movs, categorias);
    return todos
        .where((c) => !conPresupuesto.contains(c.categoria))
        .toList();
  }

  // ==========================================================================
  //  INGRESOS
  // ==========================================================================

  Future<DistribucionIngreso> distribucionIngresos(String periodo) async {
    final movs = await dao.movimientos(FiltroMovimientos(periodo: periodo));
    final ingresos = _suma(movs, (m) => m.ingresoPen);
    final gastos = _suma(movs, (m) => m.gastoPen);
    final inversion = movs
        .where((m) => m.tipo == TipoMovimiento.aporteInversion)
        .fold(0.0, (a, m) => a + m.importePen);

    return DistribucionIngreso(
      ingresos: redondear(ingresos),
      gastos: redondear(gastos),
      inversion: redondear(inversion),
    );
  }

  /// Registra un ingreso a partir de una plantilla.
  Future<Movimiento> registrarIngreso({
    required PlantillaIngreso plantilla,
    required double monto,
    String? fecha,
    String notas = '',
  }) async {
    final config = await dao.config();
    final respaldoTc =
        double.tryParse(config['tc_por_defecto'] ?? '3.75') ?? 3.75;
    final f = fecha ?? hoyLima();
    final n = await dao.ultimoNumeroMovimiento() + 1;

    final mov = Movimiento(
      id: 'MOV-${pad(n, 6)}',
      fecha: f,
      hora: horaLima(),
      tipo: TipoMovimiento.ingreso,
      importe: redondear(monto),
      moneda: plantilla.moneda,
      comercio: plantilla.nombre,
      descripcion: 'Ingreso registrado desde la app',
      categoria: plantilla.categoria,
      subcategoria: plantilla.subcategoria,
      cuentaId: plantilla.cuentaId,
      medioPago: MedioPago.transferencia,
      importePen: redondear(await fx.aSoles(monto, plantilla.moneda,
          fecha: f, respaldo: respaldoTc)),
      fuente: Fuente.manual,
      notas: notas,
      fechaCreacion: ahoraLima(),
      fechaModificacion: ahoraLima(),
      modificadoPor: 'USUARIO',
    );

    await dao.guardarMovimiento(mov);
    return mov;
  }

  // ==========================================================================
  //  MOVIMIENTOS MANUALES
  // ==========================================================================

  /// Crea un movimiento a mano (el gasto en efectivo es el caso tipico).
  Future<Movimiento> crearMovimiento({
    required TipoMovimiento tipo,
    required double importe,
    required String comercio,
    String moneda = 'PEN',
    String categoria = '',
    String subcategoria = '',
    String cuentaId = '',
    String medioPago = MedioPago.efectivo,
    String descripcion = '',
    String notas = '',
    String? fecha,
  }) async {
    final config = await dao.config();
    final respaldoTc =
        double.tryParse(config['tc_por_defecto'] ?? '3.75') ?? 3.75;
    final f = fecha ?? hoyLima();
    final n = await dao.ultimoNumeroMovimiento() + 1;

    // Un gasto manual sin categoria pasa igual por las reglas: si escribiste
    // "Wong" no tiene sentido preguntarte de que categoria es.
    var cat = categoria;
    var sub = subcategoria;
    if (cat.isEmpty) {
      final motor = MotorReglas(await dao.reglas());
      final crudo = MovimientoCrudo(
        comercio: comercio,
        descripcion: descripcion,
        tipo: tipo,
        importe: importe,
        moneda: moneda,
        medioPago: medioPago,
        cuentaId: cuentaId,
      );
      motor.aplicar(crudo);
      aplicarCategoriaPorTipo(crudo);
      cat = crudo.categoria;
      sub = crudo.subcategoria;
    }

    final mov = Movimiento(
      id: 'MOV-${pad(n, 6)}',
      fecha: f,
      hora: horaLima(),
      tipo: tipo,
      importe: redondear(importe),
      moneda: moneda,
      comercio: comercio,
      descripcion: descripcion,
      categoria: cat,
      subcategoria: sub,
      cuentaId: cuentaId,
      medioPago: medioPago,
      importePen: redondear(
          await fx.aSoles(importe, moneda, fecha: f, respaldo: respaldoTc)),
      fuente: Fuente.manual,
      notas: notas,
      fechaCreacion: ahoraLima(),
      fechaModificacion: ahoraLima(),
      modificadoPor: 'USUARIO',
    );

    await dao.guardarMovimiento(mov);
    return mov;
  }

  /// Guarda una correccion del usuario y aprende de ella.
  ///
  /// Este es el ciclo que hace que el sistema mejore solo: corriges una vez la
  /// categoria de un comercio y la proxima vez ya llega bien clasificado.
  Future<void> corregirMovimiento(
    Movimiento original, {
    required String categoria,
    required String subcategoria,
    TipoMovimiento? tipo,
    bool? recurrente,
    String? comercio,
    double? importe,
    String? notas,
    bool aprender = true,
  }) async {
    final config = await dao.config();
    final respaldoTc =
        double.tryParse(config['tc_por_defecto'] ?? '3.75') ?? 3.75;

    final nuevoImporte = importe ?? original.importe;
    final actualizado = original.copyWith(
      categoria: categoria,
      subcategoria: subcategoria,
      tipo: tipo ?? original.tipo,
      recurrente: recurrente ?? original.recurrente,
      comercio: comercio ?? original.comercio,
      importe: redondear(nuevoImporte),
      importePen: redondear(await fx.aSoles(nuevoImporte, original.moneda,
          fecha: original.fecha,
          tipoCambio: original.tipoCambio,
          respaldo: respaldoTc)),
      notas: notas ?? original.notas,
      // Corregir la categoria resuelve justamente la duda que lo trajo a la
      // bandeja, asi que el movimiento sale de revision.
      estado: EstadoMovimiento.ok,
      motivoRevision: '',
      fechaModificacion: ahoraLima(),
      modificadoPor: 'USUARIO',
    );

    await dao.guardarMovimiento(actualizado);
    if (aprender) {
      await aprenderDeCorreccion(actualizado);
    }
  }

  /// Crea o actualiza la regla del comercio corregido.
  Future<String?> aprenderDeCorreccion(Movimiento m) async {
    final patron = patronAprendido(m.comercio);
    if (patron.isEmpty) return null;

    final existentes = await dao.reglas();
    for (final r in existentes) {
      if (norm(r.campo) == 'COMERCIO' && norm(r.valor) == patron) {
        await dao.guardarRegla(r.copyWith(
          categoria: m.categoria,
          subcategoria: m.subcategoria,
          recurrente: m.recurrente,
          activa: true,
        ));
        return r.id;
      }
    }

    final id = await dao.siguienteIdRegla();
    await dao.guardarRegla(Regla(
      id: id,
      // Prioridad 1: lo que tu corregiste manda sobre cualquier regla de fabrica.
      prioridad: 1,
      campo: 'comercio',
      operador: 'contiene',
      valor: patron,
      categoria: m.categoria,
      subcategoria: m.subcategoria,
      recurrente: m.recurrente,
      origen: 'APRENDIDA',
      fechaCreacion: ahoraLima(),
    ));
    return id;
  }

  /// Reaplica las reglas a lo que quedo sin clasificar o esperando confirmacion.
  ///
  /// Devuelve cuantos movimientos cambiaron.
  Future<int> reclasificar() async {
    final motor = MotorReglas(await dao.reglas());
    final pendientes = await dao.movimientos();
    var cambios = 0;
    final actualizados = <Movimiento>[];

    for (final m in pendientes) {
      final sinCategoria =
          m.categoria.isEmpty || m.categoria == 'Sin clasificar';
      // Tambien se reprocesa lo que quedo esperando que confirmes si una
      // transferencia fue gasto: si desde entonces creaste una regla para ese
      // beneficiario, esta pasada la resuelve. Sin esto la bandeja nunca se
      // vaciaba.
      final esperandoConfirmar =
          m.estado == EstadoMovimiento.revisar &&
              m.motivoRevision == MotivoRevision.confirmarTransferencia &&
              m.cuentaId.isNotEmpty;
      if (!sinCategoria && !esperandoConfirmar) continue;

      final crudo = MovimientoCrudo(
        comercio: m.comercio,
        descripcion: m.descripcion,
        tipo: m.tipo,
        cuentaId: m.cuentaId,
        medioPago: m.medioPago,
        moneda: m.moneda,
        importe: m.importe,
        banco: m.banco,
      );
      final c = motor.clasificar(crudo);
      if (c == null || c.categoria.isEmpty) continue;

      final resuelto = m.estado == EstadoMovimiento.revisar &&
          (m.motivoRevision.startsWith('Sin categoria') || esperandoConfirmar);

      actualizados.add(m.copyWith(
        categoria: c.categoria,
        subcategoria: c.subcategoria,
        tipo: c.tipo.isEmpty ? m.tipo : TipoMovimiento.desde(c.tipo),
        recurrente: c.recurrente || m.recurrente,
        estado: resuelto ? EstadoMovimiento.ok : m.estado,
        motivoRevision: resuelto ? '' : m.motivoRevision,
        fechaModificacion: ahoraLima(),
        modificadoPor: 'REGLA:${c.reglaId}',
      ));
      cambios++;
    }

    await dao.guardarMovimientos(actualizados);
    await dao.registrar(
        'INFO', 'reclasificar', '$cambios movimientos actualizados');
    return cambios;
  }

  /// Divide un movimiento en varias partes (una compra que fue de dos rubros).
  Future<void> dividirMovimiento(
    Movimiento original,
    List<({double importe, String categoria, String subcategoria})> partes,
  ) async {
    if (partes.isEmpty) return;
    final suma = partes.fold(0.0, (a, p) => a + p.importe);
    if ((suma - original.importe).abs() > 0.05) {
      throw ArgumentError(
        'Las partes suman ${suma.toStringAsFixed(2)} y el movimiento es '
        '${original.importe.toStringAsFixed(2)}.',
      );
    }

    var n = await dao.ultimoNumeroMovimiento();
    final proporcion =
        original.importe > 0 ? original.importePen / original.importe : 1;
    final nuevos = <Movimiento>[];

    for (final p in partes) {
      n++;
      nuevos.add(original.copyWith(
        id: 'MOV-${pad(n, 6)}',
        importe: redondear(p.importe),
        importePen: redondear(p.importe * proporcion),
        categoria: p.categoria,
        subcategoria: p.subcategoria,
        movimientoRel: original.id,
        estado: EstadoMovimiento.ok,
        motivoRevision: '',
        descripcion: '${original.descripcion} (parte de ${original.id})',
        fechaModificacion: ahoraLima(),
        modificadoPor: 'USUARIO',
      ));
    }

    await dao.guardarMovimientos(nuevos);
    await dao.anularMovimiento(original.id,
        motivo: 'Dividido en ${partes.length} partes');
  }

  // ==========================================================================
  //  INVERSIONES
  // ==========================================================================

  /// Consolida las operaciones en posiciones por activo.
  Future<List<PosicionInversion>> posiciones() async {
    final ops = await dao.inversiones();
    if (ops.isEmpty) return const [];
    final activos = {for (final a in await dao.activos()) a.simbolo: a};

    final cantidades = <String, double>{};
    final costos = <String, double>{};

    for (final o in ops) {
      final signo = o.tipo == 'VENTA' ? -1.0 : 1.0;
      cantidades[o.activo] = (cantidades[o.activo] ?? 0) + signo * o.cantidad;
      costos[o.activo] =
          (costos[o.activo] ?? 0) + signo * (o.importe + o.comision);
    }

    final out = <PosicionInversion>[];
    cantidades.forEach((simbolo, cantidad) {
      if (cantidad.abs() < 0.000001) return;
      final a = activos[simbolo];
      final precio = a?.precioActual ?? 0;
      out.add(PosicionInversion(
        simbolo: simbolo,
        nombre: a?.nombre ?? simbolo,
        cantidad: cantidad,
        costoTotal: redondear(costos[simbolo] ?? 0),
        // Sin precio actual se usa el costo: mostrar cero haria ver una perdida
        // total que no existe.
        valorActual:
            redondear(precio > 0 ? cantidad * precio : (costos[simbolo] ?? 0)),
        moneda: a?.moneda ?? 'USD',
      ));
    });

    out.sort((a, b) => b.valorActual.compareTo(a.valorActual));
    return out;
  }

  /// Registra la posicion que ya tenias, sin reconstruir cada compra.
  Future<void> posicionInicial({
    required String simbolo,
    required String nombre,
    required double invertido,
    required double valorHoy,
    String moneda = 'USD',
    String cuentaId = '',
  }) async {
    final f = hoyLima();
    // La cantidad es sintetica: se toma 1 "unidad" cuyo precio es el valor de
    // hoy. Asi el rendimiento sale exacto sin inventar un numero de acciones.
    await dao.guardarActivo(ActivoInversion(
      simbolo: simbolo,
      nombre: nombre,
      moneda: moneda,
      precioActual: valorHoy,
      fechaPrecio: f,
      fuentePrecio: 'MANUAL',
    ));
    await dao.guardarInversion(Inversion(
      id: 'INV-${DateTime.now().millisecondsSinceEpoch}',
      fecha: f,
      tipo: 'POSICION_INICIAL',
      activo: simbolo,
      cuentaId: cuentaId,
      cantidad: 1,
      precioUnitario: invertido,
      importe: invertido,
      moneda: moneda,
      notas: 'Posicion que ya tenias al empezar a usar la app',
      fechaCreacion: ahoraLima(),
    ));
  }
}
