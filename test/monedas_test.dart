import 'package:flutter_test/flutter_test.dart';
import 'package:leep/domain/enums.dart';
import 'package:leep/domain/movimiento.dart';

/// Cada moneda lleva su propio libro y nada se convierte para sumarse.
///
/// Estas pruebas cuidan la regla en el punto donde es facil romperla sin
/// darse cuenta: los montos que la app suma. Antes todo pasaba por soles, asi
/// que confundir `gasto` con `gastoPen` no rompia nada visible; ahora si.
void main() {
  Movimiento mov({
    required String moneda,
    required double importe,
    required double importePen,
    TipoMovimiento tipo = TipoMovimiento.gasto,
    EstadoMovimiento estado = EstadoMovimiento.ok,
  }) =>
      Movimiento(
        id: 'x',
        fecha: '2026-09-16',
        tipo: tipo,
        estado: estado,
        moneda: moneda,
        importe: importe,
        importePen: importePen,
      );

  group('los montos que se suman van en la moneda del movimiento', () {
    test('un gasto en dolares suma dolares, no su equivalente en soles', () {
      final m = mov(moneda: 'USD', importe: 20, importePen: 75.04);
      expect(m.gasto, 20);
      expect(m.gastoPen, 75.04);
    });

    test('un gasto en soles tiene el mismo monto en los dos', () {
      final m = mov(moneda: 'PEN', importe: 148.7, importePen: 148.7);
      expect(m.gasto, 148.7);
      expect(m.gastoPen, 148.7);
    });

    test('un ingreso en dolares suma dolares', () {
      final m = mov(
        moneda: 'USD',
        importe: 500,
        importePen: 1876,
        tipo: TipoMovimiento.ingreso,
      );
      expect(m.ingreso, 500);
      expect(m.ingresoPen, 1876);
      expect(m.gasto, 0);
    });
  });

  group('el signo y los neutros se comportan igual en las dos monedas', () {
    test('una devolucion es gasto negativo', () {
      final m = mov(
        moneda: 'USD',
        importe: 20,
        importePen: 75.04,
        tipo: TipoMovimiento.devolucion,
      );
      expect(m.gasto, -20);
      expect(m.gastoPen, -75.04);
    });

    test('un pago de tarjeta no es gasto', () {
      final m = mov(
        moneda: 'PEN',
        importe: 800,
        importePen: 800,
        tipo: TipoMovimiento.pagoTarjeta,
      );
      expect(m.gasto, 0);
      expect(m.gastoPen, 0);
    });

    test('un movimiento anulado no suma en ninguna moneda', () {
      final m = mov(
        moneda: 'USD',
        importe: 20,
        importePen: 75.04,
        estado: EstadoMovimiento.anulado,
      );
      expect(m.gasto, 0);
      expect(m.gastoPen, 0);
    });

    test('una comision si es gasto', () {
      final m = mov(
        moneda: 'USD',
        importe: 3,
        importePen: 11.26,
        tipo: TipoMovimiento.comision,
      );
      expect(m.gasto, 3);
    });
  });

  test('sumar un libro completo no arrastra la otra moneda', () {
    final libro = [
      mov(moneda: 'PEN', importe: 148.7, importePen: 148.7),
      mov(moneda: 'PEN', importe: 96, importePen: 96),
      mov(moneda: 'USD', importe: 20, importePen: 75.04),
    ];

    final soles = libro
        .where((m) => m.moneda == 'PEN')
        .fold(0.0, (a, m) => a + m.gasto);
    final dolares = libro
        .where((m) => m.moneda == 'USD')
        .fold(0.0, (a, m) => a + m.gasto);

    expect(soles, 244.7);
    expect(dolares, 20);

    // El total viejo, el que juntaba todo en soles, era otro numero. Se deja
    // escrito para que quede claro que no es el que la app muestra ahora.
    final consolidadoViejo = libro.fold(0.0, (a, m) => a + m.gastoPen);
    expect(consolidadoViejo, closeTo(319.74, 0.001));
    expect(soles + dolares, isNot(closeTo(consolidadoViejo, 0.001)));
  });
}
