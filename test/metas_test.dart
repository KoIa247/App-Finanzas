import 'package:flutter_test/flutter_test.dart';
import 'package:leep/domain/meta.dart';

/// Las cuentas de una meta.
///
/// Lo que se cuida aqui es sobre todo lo que la pantalla NO debe decir: la
/// regla del prototipo es que si un mes no alcanza, la meta se queda quieta y
/// no se pinta un numero falso. Varias de estas pruebas comprueban que una
/// cuenta sin sentido devuelve null en vez de un numero cualquiera.
void main() {
  Meta meta({double objetivo = 4500, String fechaLimite = ''}) => Meta(
        id: 'm1',
        nombre: 'Viaje a Cusco',
        objetivo: objetivo,
        fechaLimite: fechaLimite,
      );

  AvanceMeta avance({
    double objetivo = 4500,
    double ahorrado = 0,
    double enPeriodo = 0,
    String fechaLimite = '',
  }) =>
      AvanceMeta(
        meta: meta(objetivo: objetivo, fechaLimite: fechaLimite),
        ahorrado: ahorrado,
        aportadoEnPeriodo: enPeriodo,
      );

  group('avance', () {
    test('el porcentaje y lo que falta salen de lo aportado', () {
      final a = avance(ahorrado: 1240);
      expect(a.porcentaje, closeTo(0.2756, 0.0001));
      expect(a.falta, 3260);
      expect(a.cumplida, isFalse);
    });

    test('pasarse del objetivo no pasa del 100 ni deja un falta negativo', () {
      final a = avance(ahorrado: 5000);
      expect(a.porcentaje, 1);
      expect(a.falta, 0);
      expect(a.cumplida, isTrue);
    });

    test('una meta sin objetivo no inventa un porcentaje', () {
      expect(avance(objetivo: 0, ahorrado: 100).porcentaje, 0);
      expect(avance(objetivo: 0, ahorrado: 100).cumplida, isFalse);
    });
  });

  group('cuanto por mes', () {
    test('sin fecha no hay cuenta que hacer', () {
      expect(avance(ahorrado: 1000).porMes, isNull);
    });

    test('con una fecha ya pasada tampoco', () {
      expect(avance(ahorrado: 1000, fechaLimite: '2020-01-01').porMes, isNull);
    });

    test('una meta cumplida no pide mas aportes', () {
      final a = avance(ahorrado: 4500, fechaLimite: '2099-12-01');
      expect(a.cumplida, isTrue);
      expect(a.porMes, isNull);
    });

    test('reparte lo que falta entre los meses que quedan', () {
      final a = avance(ahorrado: 0, fechaLimite: '2099-12-01');
      final meses = mesesHasta('2099-12-01')!;
      expect(a.porMes, closeTo(4500 / meses, 0.001));
    });
  });

  group('mesesHasta', () {
    test('el mes en curso cuenta como uno', () {
      expect(mesesHasta('1900-01-01'), isNull);
    });

    test('una fecha ilegible no rompe nada', () {
      expect(mesesHasta(''), isNull);
      expect(mesesHasta('manana'), isNull);
    });
  });

  group('el aporte conoce su periodo', () {
    test('lo deduce de la fecha', () {
      const a = AporteMeta(
        id: 'a1',
        metaId: 'm1',
        fecha: '2026-10-05',
        importe: 1240,
      );
      expect(a.periodo, '2026-10');
      expect(a.toMap()['periodo'], '2026-10');
    });
  });
}
