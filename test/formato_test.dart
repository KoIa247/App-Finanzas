import 'package:flutter_test/flutter_test.dart';
import 'package:mateito/core/formato.dart';

void main() {
  group('formato de plata', () {
    test('el sol va con el simbolo delante y punto decimal', () {
      // Asi se escribe en Peru. El locale 'es_PE' de intl devuelve
      // "1.234,56 S/", que es la convencion espanola: por eso el formateador
      // usa la maquinaria de 'en_US' con el simbolo puesto a mano.
      expect(plata(0), 'S/ 0.00');
      expect(plata(1234.56), 'S/ 1,234.56');
      expect(plata(44.9), 'S/ 44.90');
    });

    test('los miles llevan coma y los decimales punto', () {
      expect(plata(1000000), 'S/ 1,000,000.00');
      expect(plata(1465.44), 'S/ 1,465.44');
    });

    test('los negativos se leen sin ambiguedad', () {
      expect(plata(-250.5), contains('250.50'));
    });

    test('los dolares usan su propio simbolo', () {
      expect(plata(20, moneda: 'USD'), r'$ 20.00');
      expect(plata(1234.5, moneda: 'USD'), r'$ 1,234.50');
    });

    test('la version corta abrevia los montos grandes', () {
      expect(plataCorta(12400), 'S/ 12.4k');
      expect(plataCorta(2500000), 'S/ 2.5M');
      // Por debajo de 10 mil se muestra completo: abreviar "S/ 1.2k" cuando
      // puedes escribir "S/ 1,234.00" solo esconde informacion.
      expect(plataCorta(1234.56), 'S/ 1,234.56');
    });

    test('porcentajes', () {
      expect(porcentaje(0.847), '85%');
      expect(porcentaje(0.5, decimales: 1), '50.0%');
      expect(porcentajeConSigno(0.1234), '+12.3%');
      expect(porcentajeConSigno(-0.05), '-5.0%');
    });
  });
}
