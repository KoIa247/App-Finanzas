import 'package:flutter_test/flutter_test.dart';
import 'package:mateito/data/ingesta/cuentas_ajenas.dart';
import 'package:mateito/data/ingesta/servicio_ingesta.dart';
import 'package:mateito/data/parser/contexto.dart';
import 'package:mateito/domain/catalogo.dart';
import 'package:mateito/domain/enums.dart';

const mias = [
  Cuenta(
    id: 'TC_VISA',
    nombre: 'Visa Oro',
    tipo: 'TARJETA_CREDITO',
    ultimos4: '3496',
  ),
  Cuenta(
    id: 'CTA_SUELDO',
    nombre: 'Sueldo',
    tipo: 'CUENTA_CORRIENTE',
    ultimos4: '1099',
  ),
  Cuenta(
    id: 'CTA_MAMA',
    nombre: 'Negocio de mama',
    tipo: 'CUENTA_CORRIENTE',
    ultimos4: '7047',
    esPropia: false,
  ),
  Cuenta(
    id: 'CTA_VIEJA',
    nombre: 'Cuenta ajena cerrada',
    tipo: 'CUENTA_CORRIENTE',
    ultimos4: '5555',
    activa: false,
    esPropia: false,
  ),
];

void main() {
  group('resolverCuenta', () {
    test('conecta los digitos con la cuenta', () {
      expect(resolverCuenta(mias, '3496'), 'TC_VISA');
      expect(resolverCuenta(mias, '1099'), 'CTA_SUELDO');
    });

    test('devuelve vacio si no conoce esos digitos', () {
      expect(resolverCuenta(mias, '0000'), isEmpty);
      expect(resolverCuenta(mias, ''), isEmpty);
    });

    test('desempata por tipo cuando dos cuentas comparten digitos', () {
      const repetidas = [
        Cuenta(id: 'TARJETA', nombre: 'T', tipo: 'TARJETA_CREDITO', ultimos4: '1111'),
        Cuenta(id: 'CUENTA', nombre: 'C', tipo: 'CUENTA_CORRIENTE', ultimos4: '1111'),
      ];
      expect(
        resolverCuenta(repetidas, '1111', tipoHint: 'CUENTA_CORRIENTE'),
        'CUENTA',
      );
    });

    test('no resuelve contra cuentas desactivadas', () {
      expect(resolverCuenta(mias, '5555'), isEmpty);
    });
  });

  group('cuentas que no son mias', () {
    test('lo que sale de la cuenta ajena se descarta', () {
      final m = MovimientoCrudo(
        tipo: TipoMovimiento.gasto,
        comercio: 'PROVEEDOR SAC',
        cuentaId: 'CTA_MAMA',
        importe: 1500,
      );
      final v = evaluarAjeno(mias, m);
      expect(v.descartar, isTrue);
    });

    test('la marca sobrevive a desactivar la cuenta', () {
      // Si desactivas la cuenta, el banco sigue mandando los correos: sin esto
      // volverian a contarse como tuyos.
      final m = MovimientoCrudo(
        tipo: TipoMovimiento.gasto,
        comercio: 'ALGO',
        cuentaU4: '5555',
        importe: 100,
      );
      expect(evaluarAjeno(mias, m).descartar, isTrue);
    });

    test('lo que llega desde la cuenta ajena a la mia si es mio', () {
      final m = MovimientoCrudo(
        tipo: TipoMovimiento.transferencia,
        comercio: 'YO MISMO',
        cuentaId: 'CTA_MAMA',
        cuentaDestinoId: 'CTA_SUELDO',
        importe: 500,
      );
      final v = evaluarAjeno(mias, m);
      expect(v.descartar, isFalse);
      expect(v.convertirEnIngreso, isTrue);

      aplicarAjusteAjeno(m, v);
      expect(m.tipo, TipoMovimiento.ingreso);
      expect(m.cuentaId, 'CTA_SUELDO');
      expect(m.estado, EstadoMovimiento.revisar);
    });

    test('lo que sale de la mia hacia la ajena es un gasto mio', () {
      final m = MovimientoCrudo(
        tipo: TipoMovimiento.transferencia,
        comercio: 'NEGOCIO',
        cuentaId: 'CTA_SUELDO',
        cuentaDestinoId: 'CTA_MAMA',
        importe: 400,
      );
      final v = evaluarAjeno(mias, m);
      expect(v.convertirEnGasto, isTrue);

      aplicarAjusteAjeno(m, v);
      expect(m.tipo, TipoMovimiento.gasto);
    });

    test('un retiro en cajero no se confunde con un traslado', () {
      // El retiro trae una cuenta destino sintetica (EFECTIVO). Si se tratara
      // como traslado, un retiro de la cuenta ajena se volveria ingreso tuyo.
      final m = MovimientoCrudo(
        tipo: TipoMovimiento.retiroEfectivo,
        comercio: 'Cajero BCP',
        cuentaId: 'CTA_MAMA',
        cuentaDestinoId: 'EFECTIVO',
        importe: 200,
      );
      expect(esTraslado(m), isFalse);
      expect(evaluarAjeno(mias, m).descartar, isTrue);
    });

    test('mis propias cuentas no disparan nada', () {
      final m = MovimientoCrudo(
        tipo: TipoMovimiento.gasto,
        comercio: 'NETFLIX',
        cuentaId: 'TC_VISA',
        importe: 44.90,
      );
      final v = evaluarAjeno(mias, m);
      expect(v.descartar, isFalse);
      expect(v.hayAjuste, isFalse);
    });
  });

  group('huella anti duplicados', () {
    MovimientoCrudo base() => MovimientoCrudo(
          banco: 'BCP',
          fecha: '2026-07-29',
          importe: 44.90,
          moneda: 'PEN',
          comercio: 'NETFLIX.COM',
          cuentaU4: '3496',
          tipo: TipoMovimiento.gasto,
        );

    test('el mismo movimiento da la misma huella', () {
      expect(huellaMovimiento(base()), huellaMovimiento(base()));
    });

    test('un importe distinto da otra huella', () {
      final otro = base()..importe = 44.91;
      expect(huellaMovimiento(base()), isNot(huellaMovimiento(otro)));
    });

    test('un dia distinto da otra huella', () {
      final otro = base()..fecha = '2026-07-30';
      expect(huellaMovimiento(base()), isNot(huellaMovimiento(otro)));
    });
  });
}
