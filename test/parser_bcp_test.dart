import 'package:flutter_test/flutter_test.dart';
import 'package:mateito/data/parser/contexto.dart';
import 'package:mateito/data/parser/parsers.dart';
import 'package:mateito/domain/enums.dart';

/// Arma un correo del BCP con la tabla "Etiqueta | Valor" que usan todas sus
/// plantillas reales.
String tablaBcp(Map<String, String> campos) {
  final filas = campos.entries
      .map((e) => '<tr><td>${e.key}</td><td>${e.value}</td></tr>')
      .join();
  return '<html><body><table>$filas</table></body></html>';
}

ContextoCorreo correo({
  required String asunto,
  required String html,
  String texto = '',
  ConfigParser config = const ConfigParser(),
}) =>
    ContextoCorreo(
      parser: 'BCP',
      banco: 'BCP',
      asunto: asunto,
      html: html,
      texto: texto,
      fechaMensaje: DateTime(2026, 7, 29, 21, 32),
      idMensaje: 'msg-1',
      config: config,
    );

void main() {
  group('consumo con tarjeta', () {
    test('lee un consumo con tarjeta de credito', () {
      final r = parsearMensaje(correo(
        asunto: 'Realizaste un consumo con tu Tarjeta de Credito',
        html: tablaBcp({
          'Operacion realizada': 'Consumo Tarjeta de Credito',
          'Fecha y hora': '29 de julio de 2026 - 09:32 PM',
          'Empresa': 'NETFLIX.COM',
          'Total del consumo': 'S/ 44.90',
          'Numero de tarjeta de credito': 'VISA Oro | **** 3496',
          'Numero de operacion': '123456',
        }),
      ));

      expect(r.accion, AccionParser.registrar);
      final m = r.movimiento!;
      expect(m.tipo, TipoMovimiento.gasto);
      expect(m.importe, 44.90);
      expect(m.moneda, 'PEN');
      expect(m.comercio, 'NETFLIX.COM');
      expect(m.medioPago, MedioPago.tarjetaCredito);
      expect(m.cuentaU4, '3496');
      expect(m.fecha, '2026-07-29');
      expect(m.nroOperacion, '123456');
    });

    test('un consumo en dolares conserva su moneda', () {
      final r = parsearMensaje(correo(
        asunto: 'Realizaste un consumo con tu Tarjeta de Credito',
        html: tablaBcp({
          'Operacion realizada': 'Consumo Tarjeta de Credito',
          'Empresa': 'ANTHROPIC',
          'Total del consumo': r'US$ 20.00',
          'Numero de tarjeta de credito': 'VISA Oro | **** 3496',
        }),
      ));

      final m = r.movimiento!;
      expect(m.moneda, 'USD');
      expect(m.importe, 20.0);
    });

    test('un Plin no se carga a la tarjeta por la que viajo', () {
      // El Plin llega por el canal de la tarjeta de debito, pero no es una
      // compra: es plata que le mandas a una persona.
      final r = parsearMensaje(correo(
        asunto: 'Realizaste un consumo con tu Tarjeta de Debito',
        html: tablaBcp({
          'Operacion realizada': 'Consumo Tarjeta de Debito',
          'Empresa': 'PLIN- JUAN PEREZ',
          'Total del consumo': 'S/ 50.00',
          'Numero de tarjeta de debito': 'Credimas | **** 1476',
        }),
      ));

      final m = r.movimiento!;
      expect(m.medioPago, MedioPago.plin);
      expect(m.cuentaU4, isEmpty, reason: 'no se carga a la tarjeta');
      expect(m.u4Origen, '1476',
          reason: 'pero los digitos se conservan para detectar cuentas ajenas');
    });
  });

  group('otras plantillas', () {
    test('pago de tarjeta propia es neutro', () {
      final r = parsearMensaje(correo(
        asunto: 'Pago de Tarjeta de Credito',
        html: tablaBcp({
          'Operacion realizada': 'Pago de Tarjeta Propia',
          'Monto pagado': 'S/ 1,465.44',
          'Desde': 'Cuenta Clasica | **** 1099',
          'Pagado a': 'VISA Oro | **** 3496',
        }),
      ));

      final m = r.movimiento!;
      expect(m.tipo, TipoMovimiento.pagoTarjeta);
      expect(m.tipo.esNeutro, isTrue);
      expect(m.importe, 1465.44);
      expect(m.categoria, 'Movimientos internos');
      expect(m.subcategoria, 'Pago de tarjeta');
    });

    test('un yapeo recibido es un ingreso', () {
      final r = parsearMensaje(correo(
        asunto: 'Recepcion de Yapeo',
        html: tablaBcp({
          'Operacion realizada': 'Yapeo',
          'Monto recibido': 'S/ 30.00',
          'Enviado por': 'MARIA LOPEZ',
        }),
      ));

      final m = r.movimiento!;
      expect(m.tipo, TipoMovimiento.ingreso);
      expect(m.medioPago, MedioPago.yape);
      expect(m.comercio, 'MARIA LOPEZ');
    });

    test('un retiro en cajero es neutro y guarda la comision', () {
      final r = parsearMensaje(correo(
        asunto: 'Retiro en un cajero',
        html: tablaBcp({
          'Operacion realizada': 'Retiro',
          'Total retirado': 'S/ 200.00',
          'Comision por operacion': 'S/ 5.00',
          'Numero de tarjeta de debito': 'Credimas | **** 1476',
        }),
      ));

      final m = r.movimiento!;
      expect(m.tipo, TipoMovimiento.retiroEfectivo);
      expect(m.tipo.esNeutro, isTrue);
      expect(m.comision, 5.0);
    });

    test('una devolucion queda esperando que la vincules', () {
      final r = parsearMensaje(correo(
        asunto: 'Devolucion',
        html: tablaBcp({
          'Operacion realizada': 'Devolucion',
          'Total devuelto': 'S/ 44.90',
          'Empresa': 'NETFLIX.COM',
        }),
      ));

      final m = r.movimiento!;
      expect(m.tipo, TipoMovimiento.devolucion);
      expect(m.estado, EstadoMovimiento.revisar);
      expect(m.motivoRevision, MotivoRevision.vincularDevolucion);
    });
  });

  group('transferencias a terceros', () {
    ContextoCorreo transferencia(ConfigParser config) => correo(
          asunto: 'Transferencia a terceros',
          html: tablaBcp({
            'Operacion realizada': 'Transferencia a Terceros',
            'Monto transferido': 'S/ 300.00',
            'Desde': 'Cuenta Clasica | **** 1099',
            'Enviado a': 'CARLOS RUIZ | **** 7788',
          }),
          config: config,
        );

    test('de fabrica no se registran', () {
      final r = parsearMensaje(transferencia(const ConfigParser()));
      expect(r.accion, AccionParser.ignorar);
    });

    test('las excepciones si se registran', () {
      final r = parsearMensaje(transferencia(const ConfigParser(
        tercerosSiempreRegistrar: ['CARLOS'],
      )));
      expect(r.accion, AccionParser.registrar);
    });

    test('con politica GASTO pasa por revision', () {
      final r = parsearMensaje(transferencia(const ConfigParser(
        politicaTerceros: PoliticaTerceros.gasto,
      )));
      final m = r.movimiento!;
      expect(m.tipo, TipoMovimiento.gasto);
      expect(m.estado, EstadoMovimiento.revisar);
      expect(m.motivoRevision, MotivoRevision.confirmarTransferencia);
    });

    test('con politica NEUTRO no cuenta como gasto', () {
      final r = parsearMensaje(transferencia(const ConfigParser(
        politicaTerceros: PoliticaTerceros.neutro,
      )));
      final m = r.movimiento!;
      expect(m.tipo, TipoMovimiento.transferencia);
      expect(m.tipo.esNeutro, isTrue);
      expect(m.estado, EstadoMovimiento.ok);
    });
  });

  group('avisos que no son movimientos', () {
    for (final asunto in const [
      'Se rechazo tu compra',
      'Token Digital activado',
      'Tu estado de cuenta esta listo',
      'Cambio de clave exitoso',
      'Promocion especial para ti',
    ]) {
      test('se ignora: $asunto', () {
        final r = parsearMensaje(correo(asunto: asunto, html: '<html></html>'));
        expect(r.accion, AccionParser.ignorar);
      });
    }
  });
}
