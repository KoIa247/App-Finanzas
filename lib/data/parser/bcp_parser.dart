import '../../core/fechas.dart';
import '../../core/numeros.dart';
import '../../core/texto.dart';
import '../../domain/enums.dart';
import 'campos.dart';
import 'contexto.dart';

/// Asuntos que NO representan un movimiento de dinero.
final List<RegExp> _bcpIgnorar = [
  RegExp('SE RECHAZO TU COMPRA'),
  RegExp('RECHAZAD'),
  RegExp('CONFIGURACION DE TARJETA'),
  RegExp('TOKEN DIGITAL'),
  RegExp('AFILIACION'),
  RegExp('APPLE PAY'),
  RegExp('FAVORITO'),
  RegExp('ACTUALIZACION DE DATOS'),
  RegExp('ESTADO DE CUENTA'),
  RegExp('CLAVE'),
  RegExp('BLOQUEO'),
  RegExp('DESBLOQUEO'),
  RegExp('CAMBIO DE CLAVE'),
  RegExp('ENCUESTA'),
  RegExp('PROMOCION'),
  RegExp('BENEFICIO'),
];

/// Parser del BCP. Cubre las 9 plantillas que manda el Servicio de
/// Notificaciones.
///
/// Port fiel de `parserBCP_`. Cada bloque corresponde a una plantilla distinta
/// del banco, y el orden importa: se evaluan de la mas especifica a la mas
/// general.
ResultadoParser parsearBcp(ContextoCorreo ctx) {
  final asunto = norm(ctx.asunto);
  final texto = ctx.texto.isNotEmpty ? ctx.texto : htmlATexto(ctx.html);
  final textoN = norm(texto);

  for (final patron in _bcpIgnorar) {
    if (patron.hasMatch(asunto)) {
      return const ResultadoParser.ignorar(
          'Aviso informativo, no es un movimiento');
    }
  }

  final f = camposDelCorreo(ctx.html, texto);

  final operacion = norm(campo(f, ['Operacion realizada', 'Operacion']));
  final fh = parsearFechaHora(campo(f, ['Fecha y hora', 'Fecha'])) ??
      _fechaDelMensaje(ctx);
  final nroOp = limpiar(campo(
      f, ['Numero de operacion', 'Nro de operacion', 'N de operacion']));

  MovimientoCrudo base() => MovimientoCrudo(
        banco: 'BCP',
        fecha: fh.fecha,
        hora: fh.hora,
        nroOperacion: nroOp,
        moneda: 'PEN',
      );

  // --- 1. CONSUMO CON TARJETA (credito o debito) ---------------------------
  if (RegExp('CONSUMO TARJETA DE CREDITO').hasMatch(operacion) ||
      RegExp('CONSUMO TARJETA DE DEBITO').hasMatch(operacion) ||
      RegExp('REALIZASTE UN CONSUMO').hasMatch(asunto) ||
      RegExp('REALIZASTE UN CONSUMO').hasMatch(textoN)) {
    final esCredito = RegExp('CREDITO').hasMatch(operacion) ||
        RegExp('TARJETA DE CREDITO').hasMatch(asunto) ||
        RegExp('CON TU TARJETA DE CREDITO').hasMatch(textoN);

    var montoTxt = campo(f, [
      'Total del consumo',
      'Monto del consumo',
      'Importe de la operacion',
      'Monto',
    ]);
    var comercio = limpiarComercio(
        campo(f, ['Empresa', 'Comercio', 'Establecimiento']));

    if (comercio.isEmpty) {
      final mc = RegExp(
        r'consumo de\s+[^\s]+\s*[\d.,]+\s+con tu\s+.*?\s+en\s+(.+?)(?:\.\s|\.$|\n)',
        caseSensitive: false,
      ).firstMatch(texto);
      if (mc != null) comercio = limpiarComercio(mc.group(1));
    }
    if (montoTxt.isEmpty) {
      final mm = RegExp(r'consumo de\s+((?:S/|US\$|\$)\s*[\d.,]+)',
              caseSensitive: false)
          .firstMatch(texto);
      if (mm != null) montoTxt = mm.group(1)!;
    }

    final imp = parsearImporte(montoTxt);
    if (imp == null) {
      return const ResultadoParser.error(
          'No se pudo leer el importe del consumo');
    }

    final tarjeta = partirCuenta(campo(f, [
      'Numero de tarjeta de credito',
      'Numero de tarjeta de debito',
      'Tarjeta',
    ]));

    // Un Plin viaja por el canal de la tarjeta de debito, pero no es una compra
    // con la tarjeta: es plata que le mandas a una persona. Se marca como PLIN
    // para que no se mezcle con los consumos de la Credimas.
    final esPlin = RegExp(r'^PLIN[\s\-]').hasMatch(norm(comercio));

    final mov = base()
      ..tipo = TipoMovimiento.gasto
      ..importe = imp
      ..moneda = detectarMoneda(montoTxt)
      ..comercio = comercio.isEmpty ? 'Sin identificar' : comercio
      ..descripcion = esPlin
          ? 'Plin enviado'
          : 'Consumo ${esCredito ? 'tarjeta de credito' : 'tarjeta de debito'} BCP'
      ..medioPago =
          esPlin ? MedioPago.plin : (esCredito ? MedioPago.tarjetaCredito : MedioPago.tarjetaDebito)
      ..cuentaU4 = esPlin ? '' : tarjeta.ultimos4
      ..u4Origen = tarjeta.ultimos4
      ..cuentaTipo =
          esCredito ? TipoCuenta.tarjetaCredito : TipoCuenta.tarjetaDebito
      ..esCredito = esCredito;

    return ResultadoParser.registrar(mov);
  }

  // --- 2. PAGO DE TARJETA DE CREDITO PROPIA --------------------------------
  if (RegExp('PAGO DE TARJETA PROPIA').hasMatch(operacion) ||
      RegExp('PAGO DE TARJETA DE CREDITO').hasMatch(asunto)) {
    final montoPag = campo(f, ['Monto pagado', 'Total pagado', 'Monto']);
    final impPago = parsearImporte(montoPag);
    if (impPago == null) {
      return const ResultadoParser.error('No se pudo leer el monto pagado');
    }

    final tc = parsearImporte(campo(f, ['Tipo de cambio']));
    final totalPen = parsearImporte(
        campo(f, ['Total cobrado al tipo de cambio', 'Total cobrado']));
    final origen = partirCuenta(campo(f, ['Desde', 'Cuenta de cargo']));
    final destino = partirCuenta(campo(f, ['Pagado a', 'Tarjeta']));
    final monPago = detectarMoneda(montoPag);

    final mov = base()
      ..tipo = TipoMovimiento.pagoTarjeta
      ..importe = impPago
      ..moneda = monPago
      ..tipoCambio = tc
      ..importePen = monPago == 'PEN' ? impPago : totalPen
      ..comercio = destino.nombre.isEmpty ? 'Tarjeta BCP' : destino.nombre
      ..descripcion = 'Pago de tarjeta ${destino.nombre} desde '
          '${origen.nombre.isEmpty ? 'cuenta BCP' : origen.nombre}'
      ..medioPago = MedioPago.transferencia
      ..cuentaU4 = origen.ultimos4
      ..cuentaTipo = 'CUENTA'
      ..cuentaDestinoU4 = destino.ultimos4
      ..cuentaDestinoTipo = TipoCuenta.tarjetaCredito
      ..categoria = 'Movimientos internos'
      ..subcategoria = 'Pago de tarjeta';

    return ResultadoParser.registrar(mov);
  }

  // --- 3. TRANSFERENCIA ENTRE MIS CUENTAS ----------------------------------
  if (RegExp('TRANSFERENCIA ENTRE MIS CUENTAS').hasMatch(operacion) ||
      RegExp('ENTRE MIS CUENTAS').hasMatch(asunto)) {
    final mt = campo(f, ['Monto transferido', 'Total transferido', 'Monto']);
    final imp = parsearImporte(mt);
    if (imp == null) {
      return const ResultadoParser.error(
          'No se pudo leer el monto transferido');
    }
    final origen = partirCuenta(campo(f, ['Desde']));
    final destino = partirCuenta(campo(f, ['Enviado a', 'Hacia', 'Destino']));

    final mov = base()
      ..tipo = TipoMovimiento.transferencia
      ..importe = imp
      ..moneda = detectarMoneda(mt)
      ..comercio = destino.nombre.isEmpty ? 'Cuenta propia' : destino.nombre
      ..descripcion = 'Transferencia entre cuentas propias: '
          '${origen.nombre.isEmpty ? '?' : origen.nombre} -> '
          '${destino.nombre.isEmpty ? '?' : destino.nombre}'
      ..medioPago = MedioPago.transferencia
      ..cuentaU4 = origen.ultimos4
      ..cuentaTipo = 'CUENTA'
      ..cuentaDestinoU4 = destino.ultimos4
      ..cuentaDestinoTipo = 'CUENTA'
      ..categoria = 'Movimientos internos'
      ..subcategoria = 'Transferencia entre cuentas';

    return ResultadoParser.registrar(mov);
  }

  // --- 4. TRANSFERENCIA A TERCEROS -----------------------------------------
  // Politica configurable:
  //   ignorar (por defecto) . no se registra nada
  //   neutro                . se registra como movimiento interno, no gasto
  //   gasto                 . se registra como gasto y pasa por revision
  if (RegExp('TRANSFERENCIA A TERCEROS').hasMatch(operacion) ||
      RegExp('A TERCEROS').hasMatch(asunto) ||
      RegExp('TRANSFERENCIA INTERBANCARIA').hasMatch(operacion)) {
    final mt = campo(f, ['Monto transferido', 'Total transferido', 'Monto']);
    final imp = parsearImporte(mt);
    if (imp == null) {
      return const ResultadoParser.error(
          'No se pudo leer el monto transferido');
    }
    final origen = partirCuenta(campo(f, ['Desde']));
    final destino =
        partirCuenta(campo(f, ['Enviado a', 'Beneficiario', 'Destino']));
    final mensaje = limpiar(campo(f, ['Mensaje', 'Concepto']));
    final beneficiario = destino.nombre.isEmpty ? 'Tercero' : destino.nombre;

    final politica = ctx.config.politicaTerceros;
    if (politica == PoliticaTerceros.ignorar &&
        !_esExcepcion(
            '$beneficiario | $mensaje', ctx.config.tercerosSiempreRegistrar)) {
      return ResultadoParser.ignorar(
        'Transferencia a terceros a $beneficiario '
        '(configurada para no registrarse)',
      );
    }

    final comoGasto = politica == PoliticaTerceros.gasto;
    final mov = base()
      ..tipo = comoGasto ? TipoMovimiento.gasto : TipoMovimiento.transferencia
      ..importe = imp
      ..moneda = detectarMoneda(mt)
      ..comercio = beneficiario
      ..descripcion =
          'Transferencia a terceros${mensaje.isEmpty ? '' : ' - $mensaje'}'
      ..medioPago = MedioPago.transferencia
      ..cuentaU4 = origen.ultimos4
      ..cuentaTipo = 'CUENTA'
      // Los digitos del beneficiario se conservan: normalmente no coinciden con
      // ninguna cuenta tuya, pero cuando si lo hacen (te transfieres desde una
      // cuenta que operas pero no es tuya) es la unica forma de saber que ese
      // dinero acaba de pasar a ser tuyo.
      ..cuentaDestinoU4 = destino.ultimos4
      ..categoria = comoGasto ? '' : 'Movimientos internos'
      ..subcategoria = comoGasto ? '' : 'Transferencia a terceros'
      ..estado = comoGasto ? EstadoMovimiento.revisar : EstadoMovimiento.ok
      ..motivoRevision =
          comoGasto ? MotivoRevision.confirmarTransferencia : '';

    return ResultadoParser.registrar(mov);
  }

  // --- 5. YAPE -------------------------------------------------------------
  if (RegExp('YAPEO').hasMatch(operacion) ||
      RegExp('YAPEO').hasMatch(asunto) ||
      RegExp('YAPE').hasMatch(operacion)) {
    final recibido = RegExp('RECIBISTE UN YAPEO').hasMatch(textoN) ||
        RegExp('RECEPCION DE YAPEO').hasMatch(asunto) ||
        f.containsKey(norm('Monto recibido'));

    final mt = campo(
        f,
        recibido
            ? ['Monto recibido', 'Monto']
            : ['Monto enviado', 'Monto yapeado', 'Monto']);
    final imp = parsearImporte(mt);
    if (imp == null) {
      return const ResultadoParser.error(
          'No se pudo leer el monto del yapeo');
    }

    var contraparte = limpiar(campo(
        f,
        recibido
            ? ['Enviado por', 'Remitente']
            : ['Enviado a', 'Destinatario']));
    if (contraparte.isEmpty) {
      final my = RegExp(
        r'yapeo de\s+[^\s]+\s*[\d.,]+\s+(?:de|a)\s+(.+?)(?:\.\s|\.$|\n)',
        caseSensitive: false,
      ).firstMatch(texto);
      if (my != null) contraparte = limpiar(my.group(1));
    }

    final mov = base()
      ..tipo = recibido ? TipoMovimiento.ingreso : TipoMovimiento.gasto
      ..importe = imp
      ..moneda = detectarMoneda(mt)
      ..comercio = contraparte.isEmpty ? 'Yape' : contraparte
      ..descripcion = recibido ? 'Yapeo recibido' : 'Yapeo enviado'
      ..medioPago = MedioPago.yape
      ..categoria = recibido ? 'Ingresos' : 'Envios a personas'
      ..subcategoria = recibido ? 'Transferencias recibidas' : 'Amigos';

    return ResultadoParser.registrar(mov);
  }

  // --- 6. RETIRO EN CAJERO -------------------------------------------------
  if (RegExp('RETIRO').hasMatch(operacion) ||
      RegExp('RETIRO EN UN CAJERO').hasMatch(asunto)) {
    final mt = campo(f, ['Total retirado', 'Monto retirado', 'Monto']);
    final imp = parsearImporte(mt);
    if (imp == null) {
      return const ResultadoParser.error('No se pudo leer el monto retirado');
    }
    final comision =
        parsearImporte(campo(f, ['Comision por operacion', 'Comision'])) ?? 0;
    final tarjeta =
        partirCuenta(campo(f, ['Numero de tarjeta de debito', 'Tarjeta']));

    final mov = base()
      ..tipo = TipoMovimiento.retiroEfectivo
      ..importe = imp
      ..moneda = detectarMoneda(mt)
      ..comercio = 'Cajero BCP'
      ..descripcion = 'Retiro de efectivo en cajero'
          '${comision > 0 ? ' (comision $comision)' : ''}'
      ..medioPago = MedioPago.efectivo
      ..cuentaU4 = tarjeta.ultimos4
      ..cuentaTipo = TipoCuenta.tarjetaDebito
      ..cuentaDestinoId = ctx.config.cuentaEfectivo
      ..comision = comision
      ..categoria = 'Movimientos internos'
      ..subcategoria = 'Retiro de efectivo';

    return ResultadoParser.registrar(mov);
  }

  // --- 7. TRANSFERENCIA DESDE CAJERO ---------------------------------------
  if (RegExp('TRANSFERENCIA EN UN CAJERO').hasMatch(asunto) ||
      RegExp('TRANSFERENCIA EN CAJERO').hasMatch(operacion)) {
    final mt = campo(f, ['Total transferido', 'Monto transferido', 'Monto']);
    final imp = parsearImporte(mt);
    if (imp == null) {
      return const ResultadoParser.error('No se pudo leer el monto');
    }
    final destino = limpiar(campo(f, ['Enviado a', 'Destino']));

    final mov = base()
      ..tipo = TipoMovimiento.transferencia
      ..importe = imp
      ..moneda = detectarMoneda(mt)
      ..comercio = destino.isEmpty ? 'Transferencia en cajero' : destino
      ..descripcion = 'Transferencia realizada en cajero automatico'
      ..medioPago = MedioPago.transferencia
      ..estado = EstadoMovimiento.revisar
      ..motivoRevision = 'Confirma la cuenta destino';

    return ResultadoParser.registrar(mov);
  }

  // --- 8. DEVOLUCION -------------------------------------------------------
  if (RegExp('DEVOLUCION').hasMatch(operacion) ||
      RegExp('DEVOLUCION').hasMatch(asunto) ||
      RegExp('SE HA DEVUELTO EL MONTO').hasMatch(textoN)) {
    var mt = campo(f, ['Total devuelto', 'Monto devuelto', 'Monto']);
    if (mt.isEmpty) {
      final md = RegExp(r'devuelto el monto de\s+((?:S/|US\$|\$)\s*[\d.,]+)',
              caseSensitive: false)
          .firstMatch(texto);
      if (md != null) mt = md.group(1)!;
    }
    final imp = parsearImporte(mt);
    if (imp == null) {
      return const ResultadoParser.error('No se pudo leer el monto devuelto');
    }
    final comercio = limpiarComercio(campo(f, ['Empresa', 'Comercio']));
    final esCredito = campo(f, ['Numero de tarjeta de credito']).isNotEmpty;

    final mov = base()
      ..tipo = TipoMovimiento.devolucion
      ..importe = imp
      ..moneda = detectarMoneda(mt)
      ..comercio = comercio.isEmpty ? 'Devolucion BCP' : comercio
      ..descripcion = 'Devolucion de una operacion'
      ..medioPago =
          esCredito ? MedioPago.tarjetaCredito : MedioPago.tarjetaDebito
      ..cuentaU4 = partirCuenta(campo(f, [
        'Numero de tarjeta de debito',
        'Numero de tarjeta de credito',
        'Tarjeta',
      ])).ultimos4
      ..categoria = 'Ingresos'
      ..subcategoria = 'Reembolsos'
      ..estado = EstadoMovimiento.revisar
      ..motivoRevision = MotivoRevision.vincularDevolucion;

    return ResultadoParser.registrar(mov);
  }

  // --- 9. PAGO DE SERVICIOS ------------------------------------------------
  if (RegExp('PAGO DE SERVICIOS').hasMatch(operacion) ||
      RegExp('PAGO DE SERVICIO').hasMatch(asunto)) {
    var mt = campo(f, [
      'Importe',
      'Monto pagado',
      'Total pagado',
      'Monto',
      'Importe total',
    ]);
    var imp = parsearImporte(mt);
    if (imp == null) {
      final ms = RegExp(r'((?:S/|US\$|\$)\s*[\d.,]+)').firstMatch(texto);
      if (ms != null) {
        mt = ms.group(1)!;
        imp = parsearImporte(mt);
      }
    }
    if (imp == null) {
      return const ResultadoParser.error(
          'No se pudo leer el importe del servicio');
    }
    final empresa = limpiarComercio(campo(f, ['Empresa', 'Institucion']));
    final servicio = limpiar(campo(f, ['Servicio', 'Concepto']));

    final mov = base()
      ..tipo = TipoMovimiento.gasto
      ..importe = imp
      ..moneda = detectarMoneda(mt)
      ..comercio = empresa.isEmpty ? 'Pago de servicio' : empresa
      ..descripcion =
          'Pago de servicios${servicio.isEmpty ? '' : ' - $servicio'}'
      ..medioPago = MedioPago.transferencia
      ..cuentaU4 =
          partirCuenta(campo(f, ['Desde', 'Cuenta de cargo'])).ultimos4
      ..cuentaTipo = 'CUENTA';

    return ResultadoParser.registrar(mov);
  }

  // --- Sin plantilla reconocida --------------------------------------------
  final pista = operacion.isEmpty ? asunto : operacion;
  return ResultadoParser.ignorar(
    'Plantilla BCP no reconocida: '
    '${pista.substring(0, pista.length > 80 ? 80 : pista.length)}',
  );
}

bool _esExcepcion(String texto, List<String> lista) {
  // Minimo 3 caracteres: un fragmento de 2 matchearia medio catalogo.
  final patrones =
      lista.map(norm).where((x) => x.length >= 2).toList(growable: false);
  if (patrones.isEmpty) return false;
  final t = norm(texto);
  return patrones.any(t.contains);
}

FechaHora _fechaDelMensaje(ContextoCorreo ctx) {
  final d = ctx.fechaMensaje.toUtc().subtract(const Duration(hours: 5));
  return FechaHora(
    '${pad(d.year, 4)}-${pad(d.month, 2)}-${pad(d.day, 2)}',
    '${pad(d.hour, 2)}:${pad(d.minute, 2)}',
  );
}
