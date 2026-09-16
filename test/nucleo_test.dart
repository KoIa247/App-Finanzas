import 'package:flutter_test/flutter_test.dart';
import 'package:mateito/core/fechas.dart';
import 'package:mateito/core/numeros.dart';
import 'package:mateito/core/texto.dart';

void main() {
  group('parsearImporte', () {
    test('lee el formato peruano con coma de miles', () {
      expect(parsearImporte('S/ 1,465.44'), 1465.44);
      expect(parsearImporte(r'$ 77.71'), 77.71);
      expect(parsearImporte('S/ 12.50'), 12.50);
    });

    test('lee el formato europeo con punto de miles', () {
      expect(parsearImporte('1.465,44'), 1465.44);
      expect(parsearImporte('12,50'), 12.50);
    });

    test('distingue miles de decimales cuando solo hay un separador', () {
      // "1,465" son mil cuatrocientos sesenta y cinco, no uno coma cuatro.
      expect(parsearImporte('1,465'), 1465);
      expect(parsearImporte('1.465'), 1465);
      expect(parsearImporte('12.50'), 12.50);
    });

    test('sobrevive a los caracteres invisibles del BCP', () {
      expect(parsearImporte('S/​ 61.52'), 61.52);
    });

    test('devuelve null cuando no hay numero', () {
      expect(parsearImporte('sin monto'), isNull);
      expect(parsearImporte(''), isNull);
      expect(parsearImporte(null), isNull);
    });
  });

  group('detectarMoneda', () {
    test('reconoce soles y dolares', () {
      expect(detectarMoneda('S/ 61.52'), 'PEN');
      expect(detectarMoneda(r'US$ 4.84'), 'USD');
      expect(detectarMoneda(r'$ 4.84'), 'USD');
      expect(detectarMoneda('123.45'), 'PEN');
    });
  });

  group('parsearFechaHora', () {
    test('lee el formato largo en castellano', () {
      final r = parsearFechaHora('29 de julio de 2026 - 09:32 PM');
      expect(r!.fecha, '2026-07-29');
      expect(r.hora, '21:32');
    });

    test('lee el formato con dia de la semana', () {
      final r = parsearFechaHora('Lunes, 26 Enero 2026 - 08:36 AM');
      expect(r!.fecha, '2026-01-26');
      expect(r.hora, '08:36');
    });

    test('lee el formato con barras', () {
      final r = parsearFechaHora('03/12/2025 - 01:52 PM');
      expect(r!.fecha, '2025-12-03');
      expect(r.hora, '13:52');
    });

    test('las 12 AM son medianoche y las 12 PM mediodia', () {
      expect(parsearFechaHora('01/01/2026 - 12:00 AM')!.hora, '00:00');
      expect(parsearFechaHora('01/01/2026 - 12:00 PM')!.hora, '12:00');
    });

    test('acepta setiembre, que es como se escribe en Peru', () {
      expect(parsearFechaHora('5 de setiembre de 2026')!.fecha, '2026-09-05');
      expect(parsearFechaHora('5 de septiembre de 2026')!.fecha, '2026-09-05');
    });
  });

  group('norm', () {
    test('quita acentos y pasa a mayusculas', () {
      expect(norm('Alimentación'), 'ALIMENTACION');
      expect(norm('  Peña   Blanca '), 'PENA BLANCA');
    });

    test('quita los caracteres de ancho cero', () {
      expect(norm('GOO​GLE'), 'GOOGLE');
    });
  });

  group('periodos', () {
    test('el mes anterior cruza bien el cambio de anio', () {
      expect(periodoAnterior('2026-01'), '2025-12');
      expect(periodoAnterior('2026-07'), '2026-06');
    });

    test('periodoSumar retrocede varios meses', () {
      expect(periodoSumar('2026-03', -5), '2025-10');
    });

    test('febrero bisiesto', () {
      expect(diasDelMes(2024, 2), 29);
      expect(diasDelMes(2026, 2), 28);
      expect(diasDelMes(2000, 2), 29);
      expect(diasDelMes(1900, 2), 28);
    });
  });
}
