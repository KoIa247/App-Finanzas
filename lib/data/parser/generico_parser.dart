import '../../core/fechas.dart';
import '../../core/numeros.dart';
import '../../core/texto.dart';
import '../../domain/enums.dart';
import 'campos.dart';
import 'contexto.dart';

/// Parser generico, base para bancos que todavia no tienen plantilla propia.
///
/// Intenta encontrar importe, moneda, comercio y fecha con heuristicas. Todo lo
/// que produce queda en estado REVISAR a proposito: adivinar sin avisar es peor
/// que no adivinar.
ResultadoParser parsearGenerico(ContextoCorreo ctx) {
  final texto = ctx.texto.isNotEmpty ? ctx.texto : htmlATexto(ctx.html);
  final f = camposDelCorreo(ctx.html, texto);

  var montoTxt = campo(f, [
    'Monto',
    'Importe',
    'Total',
    'Monto total',
    'Importe de la operacion',
    'Total del consumo',
    'Monto pagado',
    'Monto transferido',
  ]);
  if (montoTxt.isEmpty) {
    final m =
        RegExp(r'((?:S/|US\$|\$|PEN|USD)\s*[\d.,]+)').firstMatch(texto);
    if (m != null) montoTxt = m.group(1)!;
  }

  final imp = parsearImporte(montoTxt);
  if (imp == null) {
    return const ResultadoParser.ignorar('No se encontro un importe');
  }

  final fh = parsearFechaHora(campo(f, ['Fecha y hora', 'Fecha'])) ??
      _fechaDelMensaje(ctx);

  final comercio = limpiarComercio(campo(
      f, ['Empresa', 'Comercio', 'Establecimiento', 'Beneficiario']));
  final asunto = limpiar(ctx.asunto);

  final mov = MovimientoCrudo(
    banco: ctx.banco.isEmpty ? 'Otro' : ctx.banco,
    fecha: fh.fecha,
    hora: fh.hora,
    tipo: TipoMovimiento.gasto,
    importe: imp,
    moneda: detectarMoneda(montoTxt),
    comercio: comercio.isNotEmpty
        ? comercio
        : asunto.substring(0, asunto.length > 60 ? 60 : asunto.length),
    descripcion: 'Detectado con parser generico',
    nroOperacion: limpiar(campo(f, ['Numero de operacion'])),
    estado: EstadoMovimiento.revisar,
    motivoRevision: 'Parser generico: verifica los datos y crea una regla',
  );

  return ResultadoParser.registrar(mov);
}

FechaHora _fechaDelMensaje(ContextoCorreo ctx) {
  final d = ctx.fechaMensaje.toUtc().subtract(const Duration(hours: 5));
  return FechaHora(
    '${pad(d.year, 4)}-${pad(d.month, 2)}-${pad(d.day, 2)}',
    '${pad(d.hour, 2)}:${pad(d.minute, 2)}',
  );
}
