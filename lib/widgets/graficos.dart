import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/formato.dart';
import '../core/tema.dart';

/// Un trozo de un grafico.
class Porcion {
  const Porcion({
    required this.etiqueta,
    required this.valor,
    required this.color,
  });

  final String etiqueta;
  final double valor;
  final Color color;
}

/// Dona de gastos por categoria, con el total en el centro.
///
/// Dibujada a mano en vez de traer una libreria de graficos: es un arco y un
/// texto, y asi el estilo calza exacto con el resto sin pelear con la API de
/// nadie.
class Dona extends StatelessWidget {
  const Dona({
    super.key,
    required this.porciones,
    this.total,
    this.etiquetaCentro = 'Total',
    this.tamano = 190,
    this.grosor = 26,
  });

  final List<Porcion> porciones;
  final double? total;
  final String etiquetaCentro;
  final double tamano;
  final double grosor;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final suma = total ?? porciones.fold<double>(0.0, (a, p) => a + p.valor);

    return SizedBox(
      height: tamano,
      width: tamano,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(tamano),
            painter: _PintorDona(
              porciones: porciones,
              grosor: grosor,
              fondo: t.superficie2,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(etiquetaCentro.toUpperCase(),
                  style: context.texto.labelSmall),
              const SizedBox(height: 2),
              Text(plataCorta(suma), style: context.texto.headlineSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _PintorDona extends CustomPainter {
  _PintorDona({
    required this.porciones,
    required this.grosor,
    required this.fondo,
  });

  final List<Porcion> porciones;
  final double grosor;
  final Color fondo;

  @override
  void paint(Canvas lienzo, Size size) {
    final centro = size.center(Offset.zero);
    final radio = (math.min(size.width, size.height) - grosor) / 2;
    final rect = Rect.fromCircle(center: centro, radius: radio);

    final pincel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor
      ..strokeCap = StrokeCap.butt;

    lienzo.drawCircle(centro, radio, pincel..color = fondo);

    final total = porciones.fold<double>(0.0, (a, p) => a + p.valor);
    if (total <= 0) return;

    // Se arranca arriba, no a las 3 en punto: es como la gente espera leer un
    // grafico de torta.
    var inicio = -math.pi / 2;
    for (final p in porciones) {
      if (p.valor <= 0) continue;
      final barrido = (p.valor / total) * math.pi * 2;
      lienzo.drawArc(
        rect,
        inicio,
        // Un pelo menos para que quede una hendidura entre porciones.
        barrido - 0.012,
        false,
        pincel..color = p.color,
      );
      inicio += barrido;
    }
  }

  @override
  bool shouldRepaint(_PintorDona viejo) =>
      viejo.porciones != porciones || viejo.grosor != grosor;
}

/// Leyenda de la dona: categoria, monto y porcentaje.
class LeyendaDona extends StatelessWidget {
  const LeyendaDona({super.key, required this.porciones, this.maximo = 6});

  final List<Porcion> porciones;
  final int maximo;

  @override
  Widget build(BuildContext context) {
    final total = porciones.fold<double>(0.0, (a, p) => a + p.valor);
    final visibles = porciones.take(maximo).toList();
    final resto = porciones.skip(maximo).fold<double>(0.0, (a, p) => a + p.valor);

    return Column(
      children: [
        for (final p in visibles)
          _Fila(
            color: p.color,
            etiqueta: p.etiqueta,
            monto: p.valor,
            pct: total > 0 ? p.valor / total : 0,
          ),
        if (resto > 0)
          _Fila(
            color: context.tokens.apagado,
            etiqueta: 'Otras ${porciones.length - maximo}',
            monto: resto,
            pct: total > 0 ? resto / total : 0,
          ),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.color,
    required this.etiqueta,
    required this.monto,
    required this.pct,
  });

  final Color color;
  final String etiqueta;
  final double monto;
  final double pct;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(etiqueta,
                style: context.texto.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          Text(porcentaje(pct),
              style: context.texto.bodySmall),
          const SizedBox(width: 12),
          SizedBox(
            width: 88,
            child: Text(
              plata(monto),
              textAlign: TextAlign.right,
              style: context.texto.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Un punto de la serie mensual.
class BarraMes {
  const BarraMes({
    required this.etiqueta,
    required this.ingresos,
    required this.gastos,
  });

  final String etiqueta;
  final double ingresos;
  final double gastos;
}

/// Barras de ingresos contra gastos, mes a mes.
class BarrasEvolucion extends StatelessWidget {
  const BarrasEvolucion({
    super.key,
    required this.meses,
    this.alto = 170,
  });

  final List<BarraMes> meses;
  final double alto;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (meses.isEmpty) return const SizedBox.shrink();

    final tope = meses
        .map((m) => math.max(m.ingresos, m.gastos))
        .fold<double>(0.0, math.max);

    return Column(
      children: [
        SizedBox(
          height: alto,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final m in meses)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _Barra(
                                  fraccion:
                                      tope > 0 ? m.ingresos / tope : 0,
                                  color: t.bueno),
                              const SizedBox(width: 2),
                              _Barra(
                                  fraccion: tope > 0 ? m.gastos / tope : 0,
                                  color: t.serie[1]),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          m.etiqueta,
                          style: context.texto.labelSmall?.copyWith(
                            fontSize: 9,
                            letterSpacing: 0,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Clave(color: t.bueno, texto: 'Ingresos'),
            const SizedBox(width: 18),
            _Clave(color: t.serie[1], texto: 'Gastos'),
          ],
        ),
      ],
    );
  }
}

class _Barra extends StatelessWidget {
  const _Barra({required this.fraccion, required this.color});

  final double fraccion;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FractionallySizedBox(
        // Un minimo visible: una barra de altura cero parece un dato faltante,
        // no un mes en el que de verdad no hubo movimiento.
        heightFactor: fraccion <= 0 ? 0.012 : fraccion.clamp(0.012, 1.0),
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: BoxDecoration(
            color: fraccion <= 0 ? context.tokens.grilla : color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          ),
        ),
      ),
    );
  }
}

class _Clave extends StatelessWidget {
  const _Clave({required this.color, required this.texto});

  final Color color;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(texto, style: context.texto.bodySmall),
      ],
    );
  }
}

/// Barra apilada horizontal: en que se convirtio cada sol que entro.
class BarraApilada extends StatelessWidget {
  const BarraApilada({super.key, required this.porciones, this.alto = 30});

  final List<Porcion> porciones;
  final double alto;

  @override
  Widget build(BuildContext context) {
    final total = porciones.fold<double>(0.0, (a, p) => a + math.max(p.valor, 0));
    if (total <= 0) {
      return Container(
        height: alto,
        decoration: BoxDecoration(
          color: context.tokens.superficie2,
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: alto,
            child: Row(
              children: [
                for (final p in porciones)
                  if (p.valor > 0)
                    Expanded(
                      flex: (p.valor / total * 1000).round().clamp(1, 1000),
                      child: Container(color: p.color),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            for (final p in porciones)
              if (p.valor > 0)
                _Clave(
                  color: p.color,
                  texto: '${p.etiqueta} · ${porcentaje(p.valor / total)}',
                ),
          ],
        ),
      ],
    );
  }
}
