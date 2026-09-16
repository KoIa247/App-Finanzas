import 'package:flutter_test/flutter_test.dart';
import 'package:mateito/data/clasificador/motor_reglas.dart';
import 'package:mateito/data/clasificador/suscripciones.dart';
import 'package:mateito/data/db/semilla.dart';
import 'package:mateito/data/parser/contexto.dart';
import 'package:mateito/domain/enums.dart';
import 'package:mateito/domain/movimiento.dart';

MovimientoCrudo gasto(String comercio) =>
    MovimientoCrudo(comercio: comercio, tipo: TipoMovimiento.gasto);

Movimiento mov({
  required String comercio,
  required String fecha,
  required double importe,
  bool recurrente = false,
}) =>
    Movimiento(
      id: 'MOV-$fecha-$comercio',
      fecha: fecha,
      tipo: TipoMovimiento.gasto,
      comercio: comercio,
      importe: importe,
      importePen: importe,
      recurrente: recurrente,
    );

void main() {
  final motor = MotorReglas(reglasSemilla);

  group('motor de reglas', () {
    test('clasifica los comercios de la semilla', () {
      expect(motor.clasificar(gasto('NETFLIX.COM'))?.categoria, 'Suscripciones');
      expect(motor.clasificar(gasto('RAPPI*PEDIDO 123'))?.subcategoria,
          'Delivery');
      expect(motor.clasificar(gasto('UBER TRIP'))?.subcategoria, 'Taxi / Apps');
    });

    test('la prioridad decide entre reglas que se pisan', () {
      // "Google Workspace" (54) tiene que ganarle al comodin "GOOGLE" (60).
      expect(motor.clasificar(gasto('GOOGLE WORKSPACE'))?.subcategoria,
          'Profesional');
      expect(motor.clasificar(gasto('GOOGLE *GOOGLE ONE'))?.subcategoria,
          'Nube / Storage');
      expect(motor.clasificar(gasto('GOOGLE SERVICIOS'))?.subcategoria,
          'Software / IA');
    });

    test('YouTube Premium no cae en el comodin de Google', () {
      // Llega como "Google YouTubePremium": sin su regla propia terminaba en
      // Software / IA en vez de Streaming.
      expect(motor.clasificar(gasto('GOOGLE YOUTUBEPREMIUM'))?.subcategoria,
          'Streaming');
    });

    test('Rappi Pro es suscripcion pero un pedido de Rappi no', () {
      expect(motor.clasificar(gasto('RAPPI PRO'))?.recurrente, isTrue);
      expect(motor.clasificar(gasto('RAPPI*PEDIDO'))?.recurrente, isFalse);
    });

    test('no inventa categoria cuando nada calza', () {
      expect(motor.clasificar(gasto('BODEGA DONA ROSA')), isNull);
    });

    test('lo no clasificado va a revision', () {
      final m = gasto('BODEGA DONA ROSA');
      motor.aplicar(m);
      expect(m.categoria, 'Sin clasificar');
      expect(m.estado, EstadoMovimiento.revisar);
      expect(m.motivoRevision, MotivoRevision.sinCategoria);
    });

    test('el aporte al broker cambia el tipo del movimiento', () {
      final c = motor.clasificar(gasto('TRII SAB'));
      expect(c?.tipo, 'APORTE_INVERSION');
      expect(c?.cuentaDestino, 'INV_TRII');
    });
  });

  group('patron aprendido', () {
    test('usa las tres primeras palabras', () {
      expect(patronAprendido('EDO SUSHI BAR MIRAFLORES 8891'), 'EDO SUSHI BAR');
    });

    test('ignora los comercios sin nombre', () {
      expect(patronAprendido('Sin identificar'), isEmpty);
      expect(patronAprendido(''), isEmpty);
    });
  });

  group('deteccion de suscripciones', () {
    test('reconoce un cargo mensual estable', () {
      final s = detectarSuscripciones([
        mov(comercio: 'NETFLIX.COM', fecha: '2026-05-15', importe: 44.90),
        mov(comercio: 'NETFLIX.COM', fecha: '2026-06-15', importe: 44.90),
        mov(comercio: 'NETFLIX.COM', fecha: '2026-07-16', importe: 44.90),
      ], hoy: '2026-07-29');

      expect(s, hasLength(1));
      expect(s.first.comercio, 'NETFLIX.COM');
      expect(s.first.origen, 'PATRON');
      expect(s.first.diaAproximado, anyOf(15, 16));
    });

    test('el supermercado no es una suscripcion', () {
      // Cuatro visitas al mes con montos dispares: es justo lo que los cuatro
      // filtros juntos tienen que descartar.
      final s = detectarSuscripciones([
        mov(comercio: 'WONG SAN ISIDRO', fecha: '2026-05-03', importe: 120),
        mov(comercio: 'WONG SAN ISIDRO', fecha: '2026-05-14', importe: 310),
        mov(comercio: 'WONG SAN ISIDRO', fecha: '2026-05-27', importe: 85),
        mov(comercio: 'WONG SAN ISIDRO', fecha: '2026-06-08', importe: 240),
        mov(comercio: 'WONG SAN ISIDRO', fecha: '2026-06-22', importe: 155),
        mov(comercio: 'WONG SAN ISIDRO', fecha: '2026-07-05', importe: 400),
      ], hoy: '2026-07-29');

      expect(s, isEmpty);
    });

    test('una regla basta: un solo cargo ya cuenta', () {
      final s = detectarSuscripciones([
        mov(
          comercio: 'SPOTIFY',
          fecha: '2026-07-10',
          importe: 26.90,
          recurrente: true,
        ),
      ], hoy: '2026-07-29');

      expect(s, hasLength(1));
      expect(s.first.origen, 'REGLA');
    });

    test('sin cobrar hace mucho se marca como posible baja', () {
      final s = detectarSuscripciones([
        mov(comercio: 'DISNEY PLUS', fecha: '2026-01-10', importe: 30,
            recurrente: true),
      ], hoy: '2026-07-29');

      expect(s.first.estado, 'POSIBLE_BAJA');
    });

    test('el dia del mes se trata como circular', () {
      // El 30, el 31 y el 1 estan a un dia entre si, no a 29: con un promedio
      // aritmetico darian 20 y la suscripcion quedaria descartada.
      // Los tres cargos caen en meses distintos a proposito: el detector exige
      // tres meses, que es lo que separa una suscripcion de dos compras.
      final s = detectarSuscripciones([
        mov(comercio: 'ICLOUD', fecha: '2026-04-30', importe: 12.90),
        mov(comercio: 'ICLOUD', fecha: '2026-05-31', importe: 12.90),
        mov(comercio: 'ICLOUD', fecha: '2026-07-01', importe: 12.90),
      ], hoy: '2026-07-05');

      expect(s, hasLength(1));
      expect(s.first.diaAproximado, anyOf(30, 31, 1));
    });

    test('exige tres meses distintos', () {
      // Dos cargos en el mismo mes no son una suscripcion, por identicos que
      // sean: podrian ser dos compras iguales.
      final s = detectarSuscripciones([
        mov(comercio: 'ICLOUD', fecha: '2026-04-30', importe: 12.90),
        mov(comercio: 'ICLOUD', fecha: '2026-06-01', importe: 12.90),
        mov(comercio: 'ICLOUD', fecha: '2026-06-30', importe: 12.90),
      ], hoy: '2026-07-05');

      expect(s, isEmpty);
    });

    test('lo vetado a mano no aparece aunque calce', () {
      final s = detectarSuscripciones([
        mov(comercio: 'NETFLIX.COM', fecha: '2026-05-15', importe: 44.90),
        mov(comercio: 'NETFLIX.COM', fecha: '2026-06-15', importe: 44.90),
        mov(comercio: 'NETFLIX.COM', fecha: '2026-07-15', importe: 44.90),
      ], hoy: '2026-07-29', excluidas: ['NETFLIX']);

      expect(s, isEmpty);
    });
  });
}
