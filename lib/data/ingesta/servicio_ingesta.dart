import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../core/fechas.dart';
import '../../core/numeros.dart';
import '../../core/texto.dart';
import '../../domain/catalogo.dart';
import '../../domain/enums.dart';
import '../../domain/movimiento.dart';
import '../clasificador/motor_reglas.dart';
import '../fx/tipo_cambio.dart';
import '../gmail/cliente_gmail.dart';
import '../parser/contexto.dart';
import '../parser/parsers.dart';
import '../repos/dao.dart';
import 'cuentas_ajenas.dart';

/// Lo que paso en una sincronizacion.
class ResultadoSync {
  ResultadoSync();

  int revisados = 0;
  int registrados = 0;
  int revisar = 0;
  int duplicados = 0;
  int ignorados = 0;
  int errores = 0;
  int ajenos = 0;
  double ajenosMonto = 0;
  bool truncado = false;
  String? error;

  final List<String> detalles = [];

  bool get huboAlgo => registrados > 0;

  String get resumen {
    if (error != null) return 'Error: $error';
    final b = StringBuffer()
      ..writeln('Correos revisados: $revisados')
      ..writeln('Movimientos registrados: $registrados')
      ..writeln('Pendientes de revision: $revisar')
      ..writeln('Duplicados evitados: $duplicados')
      ..writeln('Avisos ignorados: $ignorados')
      ..write('Errores de lectura: $errores');
    if (ajenos > 0) {
      b.write('\n\nNo se registraron $ajenos operacion(es) por '
          'S/ ${ajenosMonto.toStringAsFixed(2)}: salen de cuentas marcadas '
          'como "no es mi dinero".');
    }
    if (truncado) {
      b.write('\n\nSe alcanzo el limite de la corrida. '
          'Vuelve a sincronizar para continuar.');
    }
    return b.toString();
  }
}

/// La tuberia completa: Gmail -> parser -> anti duplicados -> base local.
class ServicioIngesta {
  ServicioIngesta({
    required this.dao,
    required this.gmail,
    required this.fx,
  });

  final Dao dao;
  final ClienteGmail gmail;
  final ServicioTipoCambio fx;

  /// Sincroniza los ultimos [dias] dias.
  Future<ResultadoSync> sincronizar({int? dias}) async {
    final config = await dao.config();
    final ventana =
        dias ?? int.tryParse(config['dias_busqueda_incremental'] ?? '5') ?? 5;
    final desde = DateTime.now().subtract(Duration(days: ventana));
    return _correr(
      desde: desde,
      hasta: null,
      config: config,
    );
  }

  /// Procesa un rango historico concreto.
  Future<ResultadoSync> sincronizarHistorico(
    DateTime desde,
    DateTime hasta,
  ) async =>
      _correr(desde: desde, hasta: hasta, config: await dao.config());

  Future<ResultadoSync> _correr({
    required DateTime desde,
    required DateTime? hasta,
    required Map<String, String> config,
  }) async {
    final res = ResultadoSync();

    try {
      final remitentes = await dao.remitentes(soloActivos: true);
      if (remitentes.isEmpty) {
        res.error = 'No hay remitentes activos. Revisa Ajustes.';
        return res;
      }

      final cuentas = await dao.cuentas();
      final motor = MotorReglas(await dao.reglas());
      final indice = await dao.indiceDedup();
      final cfgParser = _configParser(config);
      final autoCategorizar = (config['auto_categorizar'] ?? 'SI') == 'SI';
      final respaldoTc =
          double.tryParse(config['tc_por_defecto'] ?? '3.75') ?? 3.75;
      final tope =
          int.tryParse(config['max_correos_por_corrida'] ?? '150') ?? 150;

      final consulta = _consulta(remitentes, desde, hasta);
      final ids = await gmail.buscar(consulta, tope: tope);
      if (ids.length >= tope) res.truncado = true;

      // Se piden de golpe los correlativos para no consultar la base por cada
      // movimiento nuevo.
      var correlativo = await dao.ultimoNumeroMovimiento();
      final nuevos = <Movimiento>[];
      final reglasAcertadas = <String>[];

      final porRemitente = {
        for (final r in remitentes) r.remitente.toLowerCase(): r,
      };

      for (final id in ids) {
        // Capa 1 del anti duplicados: el id del mensaje. Es la mas fuerte y la
        // mas barata, asi que va antes de descargar nada.
        if (indice.porEmail.contains(id)) {
          res.duplicados++;
          continue;
        }

        MensajeGmail? msg;
        try {
          msg = await gmail.mensaje(id);
        } catch (e) {
          res.errores++;
          res.detalles.add('No se pudo descargar un correo: $e');
          continue;
        }
        if (msg == null) continue;
        res.revisados++;

        final remitente = porRemitente[msg.remitente];
        if (remitente == null) {
          res.ignorados++;
          continue;
        }

        final ctx = ContextoCorreo(
          parser: remitente.parser,
          banco: remitente.banco,
          asunto: msg.asunto,
          html: msg.html,
          texto: msg.texto,
          fechaMensaje: msg.fecha,
          idMensaje: msg.id,
          config: cfgParser,
        );

        final r = parsearMensaje(ctx);
        if (r.accion == AccionParser.ignorar) {
          res.ignorados++;
          res.detalles.add('Ignorado: ${msg.asunto} · ${r.motivo}');
          continue;
        }
        if (r.accion == AccionParser.error || r.movimiento == null) {
          res.errores++;
          res.detalles.add('Error: ${msg.asunto} · ${r.motivo}');
          continue;
        }

        final mov = r.movimiento!;

        // --- Politica de tarjeta de debito ---------------------------------
        if (_descartarPorDebito(mov, cfgParser)) {
          res.ignorados++;
          continue;
        }

        // --- Resolucion de cuenta ------------------------------------------
        mov.cuentaId = resolverCuenta(
          cuentas,
          mov.cuentaU4,
          tipoHint: mov.cuentaTipo,
          moneda: mov.moneda,
        );
        if (mov.cuentaDestinoId.isEmpty && mov.cuentaDestinoU4.isNotEmpty) {
          mov.cuentaDestinoId = resolverCuenta(
            cuentas,
            mov.cuentaDestinoU4,
            tipoHint: mov.cuentaDestinoTipo,
            moneda: mov.moneda,
          );
        }

        // --- Plata que no es mia -------------------------------------------
        // VA ANTES del desvio a la cuenta de envios a proposito: si primero se
        // reasignara a Efectivo, una operacion de la cuenta ajena que no llego
        // a resolverse pasaria a ser un gasto tuyo en efectivo, que es justo lo
        // que esto viene a impedir.
        final ajeno = evaluarAjeno(cuentas, mov);
        if (ajeno.descartar) {
          res.ignorados++;
          res.ajenos++;
          res.ajenosMonto = redondear(res.ajenosMonto +
              await fx.aSoles(mov.importe, mov.moneda,
                  fecha: mov.fecha,
                  tipoCambio: mov.tipoCambio,
                  respaldo: respaldoTc));
          res.detalles.add('No es tu plata: ${msg.asunto} · ${ajeno.motivo}');
          continue;
        }
        if (ajeno.hayAjuste) aplicarAjusteAjeno(mov, ajeno);

        // Yape y Plin van a su propia cuenta en vez de a la tarjeta por la que
        // viajaron. Las transferencias a terceros SI conservan su cuenta de
        // origen real cuando el correo la trae; solo caen aqui si no se resolvio.
        if (esEnvioAPersona(mov) && mov.cuentaId.isEmpty) {
          if (buscarCuenta(cuentas, cfgParser.cuentaEnvios) != null) {
            mov.cuentaId = cfgParser.cuentaEnvios;
          }
        }

        if (mov.cuentaId.isEmpty && mov.tipo != TipoMovimiento.ingreso) {
          if (mov.estado == EstadoMovimiento.ok) {
            mov.estado = EstadoMovimiento.revisar;
          }
          mov.agregarMotivo(MotivoRevision.sinCuenta +
              (mov.cuentaU4.isNotEmpty ? ' ****${mov.cuentaU4}' : ''));
        }

        // --- Clasificacion ---------------------------------------------------
        motor.aplicar(mov, autoCategorizar: autoCategorizar);
        aplicarCategoriaPorTipo(mov);

        // --- Conversion a soles ----------------------------------------------
        mov.importePen ??= await fx.aSoles(
          mov.importe,
          mov.moneda,
          fecha: mov.fecha,
          tipoCambio: mov.tipoCambio,
          respaldo: respaldoTc,
        );
        if (mov.moneda != 'PEN' && mov.tipoCambio == null) {
          mov.tipoCambio =
              redondear(await fx.para(mov.fecha, respaldo: respaldoTc), 4);
        }

        // --- Duplicados: capa 2 (nro de operacion) y capa 3 (huella) ---------
        final claveOp = mov.nroOperacion.isNotEmpty
            ? norm('${mov.banco}|${mov.nroOperacion}')
            : '';
        if (claveOp.isNotEmpty && indice.porOperacion.contains(claveOp)) {
          res.duplicados++;
          continue;
        }

        final hash = huellaMovimiento(mov);
        if (indice.porHash.contains(hash)) {
          res.duplicados++;
          continue;
        }

        // --- Devoluciones: enlazar con el gasto original ----------------------
        if (mov.tipo == TipoMovimiento.devolucion) {
          final orig = await _buscarGastoOriginal(mov);
          if (orig != null) {
            mov.movimientoRel = orig.id;
            // Solo se cierra la revision si lo unico pendiente era enlazar la
            // devolucion. Si ademas no se reconocio la cuenta, eso sigue
            // necesitando tu ojo y no se puede tapar.
            if (mov.motivoRevision == MotivoRevision.vincularDevolucion) {
              mov.estado = EstadoMovimiento.ok;
              mov.motivoRevision = '';
            }
            mov.descripcion += ' (revierte ${orig.id})';
            // Hereda la categoria del gasto que revierte: una devolucion de
            // Rappi es un gasto negativo de Alimentacion, no un ingreso, y asi
            // libera el presupuesto de la categoria correcta.
            if (orig.categoria.isNotEmpty) {
              mov.categoria = orig.categoria;
              mov.subcategoria = orig.subcategoria;
            }
          }
        }

        correlativo++;
        nuevos.add(_aMovimiento(mov, id: 'MOV-${pad(correlativo, 6)}',
            emailId: msg.id, hash: hash));

        indice.porEmail.add(msg.id);
        if (claveOp.isNotEmpty) indice.porOperacion.add(claveOp);
        indice.porHash.add(hash);

        res.registrados++;
        if (mov.estado == EstadoMovimiento.revisar) res.revisar++;
        if (mov.reglaAplicada.isNotEmpty) {
          reglasAcertadas.add(mov.reglaAplicada);
        }
      }

      await dao.guardarMovimientos(nuevos);
      for (final r in reglasAcertadas) {
        await dao.sumarAcierto(r);
      }
      await dao.registrar('INFO', 'sincronizar', res.resumen);
    } catch (e) {
      res.error = e.toString();
      await dao.registrar('ERROR', 'sincronizar', e.toString());
    }

    return res;
  }

  // ==========================================================================
  //  AUXILIARES
  // ==========================================================================

  ConfigParser _configParser(Map<String, String> c) => ConfigParser(
        politicaTerceros:
            PoliticaTerceros.desde(c['transferencias_terceros']),
        tercerosSiempreRegistrar: _lista(c['terceros_siempre_registrar']),
        registrarDebito: (c['registrar_debito'] ?? 'NO') == 'SI',
        debitoSiempreRegistrar: _lista(c['debito_siempre_registrar']),
        cuentaEfectivo: c['cuenta_efectivo'] ?? 'EFECTIVO',
        cuentaEnvios: c['cuenta_envios'] ?? 'EFECTIVO',
      );

  List<String> _lista(String? v) => (v ?? '')
      .split(',')
      .map((x) => x.trim())
      .where((x) => x.isNotEmpty)
      .toList();

  /// De fabrica solo se registran los consumos con tarjeta de credito.
  ///
  /// Los Plin son la excepcion que viene puesta: no son una compra con la
  /// tarjeta, es plata que le mandas a una persona, y el banco los notifica por
  /// el mismo canal que un consumo de debito.
  bool _descartarPorDebito(MovimientoCrudo mov, ConfigParser cfg) {
    if (cfg.registrarDebito) return false;
    if (mov.medioPago != MedioPago.tarjetaDebito) return false;
    final comercio = norm(mov.comercio);
    final excepcion = cfg.debitoSiempreRegistrar
        .map(norm)
        .where((x) => x.isNotEmpty)
        .any(comercio.contains);
    return !excepcion;
  }

  /// Busca el gasto que una devolucion revierte.
  ///
  /// Se exige mismo importe, misma moneda, comercio con el mismo prefijo y
  /// menos de 90 dias de diferencia. Sin las cuatro condiciones, una devolucion
  /// podria engancharse con el gasto equivocado y cambiarle la categoria.
  Future<Movimiento?> _buscarGastoOriginal(MovimientoCrudo dev) async {
    final prefijo = norm(dev.comercio);
    final corto =
        prefijo.substring(0, prefijo.length > 12 ? 12 : prefijo.length);

    final candidatos = await dao.movimientos(FiltroMovimientos(
      tipo: TipoMovimiento.gasto,
      desde: _restarDias(dev.fecha, 90),
      hasta: dev.fecha,
    ));

    final calzan = candidatos.where((m) {
      if ((m.importe - dev.importe).abs() > 0.02) return false;
      if (norm(m.moneda) != norm(dev.moneda)) return false;
      if (corto.isNotEmpty && !norm(m.comercio).startsWith(corto)) return false;
      return true;
    }).toList();

    if (calzan.isEmpty) return null;
    calzan.sort((a, b) => b.fecha.compareTo(a.fecha));
    return calzan.first;
  }

  String _restarDias(String fecha, int dias) {
    final d = DateTime.tryParse(normalizarFecha(fecha));
    if (d == null) return '';
    final r = d.subtract(Duration(days: dias));
    return '${pad(r.year, 4)}-${pad(r.month, 2)}-${pad(r.day, 2)}';
  }

  /// Arma la consulta de busqueda de Gmail.
  String _consulta(
    List<Remitente> remitentes,
    DateTime desde,
    DateTime? hasta,
  ) {
    final froms = remitentes.map((r) => 'from:${r.remitente}').join(' OR ');
    final b = StringBuffer('($froms)');
    b.write(' after:${_gmailFecha(desde)}');
    if (hasta != null) {
      // Gmail interpreta `before:` como exclusivo, asi que se suma un dia para
      // que el ultimo dia del rango si entre.
      b.write(' before:${_gmailFecha(hasta.add(const Duration(days: 1)))}');
    }
    return b.toString();
  }

  String _gmailFecha(DateTime d) =>
      '${pad(d.year, 4)}/${pad(d.month, 2)}/${pad(d.day, 2)}';

  Movimiento _aMovimiento(
    MovimientoCrudo m, {
    required String id,
    required String emailId,
    required String hash,
  }) =>
      Movimiento(
        id: id,
        fecha: m.fecha,
        hora: m.hora,
        tipo: m.tipo,
        importe: redondear(m.importe),
        moneda: m.moneda,
        comercio: m.comercio,
        descripcion: m.descripcion,
        categoria: m.categoria,
        subcategoria: m.subcategoria,
        banco: m.banco,
        cuentaId: m.cuentaId,
        medioPago: m.medioPago,
        tipoCambio: m.tipoCambio,
        importePen: redondear(m.importePen ?? m.importe),
        fuente: Fuente.email,
        emailId: emailId,
        nroOperacion: m.nroOperacion,
        hashDedup: hash,
        estado: m.estado,
        motivoRevision: m.motivoRevision,
        recurrente: m.recurrente,
        cuentaDestinoId: m.cuentaDestinoId,
        movimientoRel: m.movimientoRel,
        notas: m.notas,
        fechaCreacion: ahoraLima(),
        fechaModificacion: ahoraLima(),
        modificadoPor: 'SISTEMA',
      );
}

/// Huella secundaria: mismo banco, dia, importe, moneda, comercio y tarjeta.
///
/// Es la tercera capa anti duplicados. Atrapa el caso en que el banco reenvia
/// el mismo aviso desde otro mensaje, que el id de Gmail no detecta.
String huellaMovimiento(MovimientoCrudo mov) {
  final comercio = norm(mov.comercio);
  final partes = [
    norm(mov.banco),
    mov.fecha,
    redondear(mov.importe).toStringAsFixed(2),
    norm(mov.moneda),
    comercio.substring(0, comercio.length > 25 ? 25 : comercio.length),
    mov.cuentaU4,
    norm(mov.tipo.valor),
  ].join('|');
  return md5.convert(utf8.encode(partes)).toString();
}
