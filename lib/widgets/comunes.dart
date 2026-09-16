import 'package:flutter/material.dart';

import '../core/formato.dart';
import '../core/tema.dart';

/// Tarjeta con titulo y accion opcional. Es el contenedor base de todo.
class Bloque extends StatelessWidget {
  const Bloque({
    super.key,
    required this.titulo,
    required this.child,
    this.pie,
    this.accion,
    this.nota,
    this.padding = const EdgeInsets.all(16),
  });

  final String titulo;
  final Widget child;
  final Widget? pie;
  final Widget? accion;

  /// Texto explicativo bajo el titulo. El prototipo lo usa mucho y vale la
  /// pena: buena parte del valor de esta app es explicar por que un numero es
  /// lo que es.
  final String? nota;

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(titulo, style: context.texto.titleMedium),
                ),
                if (accion != null) accion!,
              ],
            ),
            if (nota != null) ...[
              const SizedBox(height: 6),
              Text(nota!,
                  style: context.texto.bodySmall?.copyWith(height: 1.5)),
            ],
            const SizedBox(height: 14),
            child,
            if (pie != null) ...[
              Divider(height: 26, color: t.borde),
              pie!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Un numero grande con su etiqueta. La unidad de los tableros.
class Ficha extends StatelessWidget {
  const Ficha({
    super.key,
    required this.etiqueta,
    required this.valor,
    this.sub,
    this.color,
    this.alPresionar,
  });

  final String etiqueta;
  final String valor;
  final String? sub;
  final Color? color;
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: alPresionar,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: t.superficie,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.borde),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(etiqueta.toUpperCase(),
                style: context.texto.labelSmall, maxLines: 1),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                valor,
                style: context.texto.headlineSmall?.copyWith(color: color),
              ),
            ),
            if (sub != null) ...[
              const SizedBox(height: 4),
              Text(sub!,
                  style: context.texto.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
      ),
    );
  }
}

/// Una rejilla de fichas que se adapta al ancho.
class RejillaFichas extends StatelessWidget {
  const RejillaFichas({super.key, required this.fichas});

  final List<Widget> fichas;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, cons) {
        // Dos columnas en telefono, cuatro cuando hay sitio. Por debajo de
        // ~170px por ficha el monto deja de leerse.
        final columnas = cons.maxWidth >= 720 ? 4 : 2;
        const espacio = 10.0;
        final ancho =
            (cons.maxWidth - espacio * (columnas - 1)) / columnas;
        return Wrap(
          spacing: espacio,
          runSpacing: espacio,
          children: [
            for (final f in fichas) SizedBox(width: ancho, child: f),
          ],
        );
      },
    );
  }
}

/// Aviso con tono. Se usa para la bandeja de revision, la cobertura baja y los
/// mensajes de "todavia no configuraste esto".
class Aviso extends StatelessWidget {
  const Aviso({
    super.key,
    required this.texto,
    this.titulo,
    this.tono = TonoAviso.info,
    this.accion,
    this.icono,
  });

  final String texto;
  final String? titulo;
  final TonoAviso tono;
  final Widget? accion;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = switch (tono) {
      TonoAviso.info => marca,
      TonoAviso.bueno => t.bueno,
      TonoAviso.aviso => t.aviso,
      TonoAviso.serio => t.serio,
      TonoAviso.critico => t.critico,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono ?? _iconoPorTono(tono), size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (titulo != null) ...[
                  Text(titulo!,
                      style: context.texto.titleSmall?.copyWith(color: color)),
                  const SizedBox(height: 3),
                ],
                Text(texto,
                    style: context.texto.bodySmall
                        ?.copyWith(color: t.tinta2, height: 1.5)),
                if (accion != null) ...[
                  const SizedBox(height: 10),
                  accion!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconoPorTono(TonoAviso tono) => switch (tono) {
        TonoAviso.info => Icons.info_outline,
        TonoAviso.bueno => Icons.check_circle_outline,
        TonoAviso.aviso => Icons.warning_amber_rounded,
        TonoAviso.serio => Icons.error_outline,
        TonoAviso.critico => Icons.dangerous_outlined,
      };
}

enum TonoAviso { info, bueno, aviso, serio, critico }

/// Estado vacio con una explicacion util, no un "no hay datos" pelado.
class Vacio extends StatelessWidget {
  const Vacio({
    super.key,
    required this.titulo,
    this.detalle,
    this.icono = Icons.inbox_outlined,
    this.accion,
  });

  final String titulo;
  final String? detalle;
  final IconData icono;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
        children: [
          Icon(icono, size: 34, color: t.apagado),
          const SizedBox(height: 12),
          Text(titulo,
              textAlign: TextAlign.center, style: context.texto.titleSmall),
          if (detalle != null) ...[
            const SizedBox(height: 6),
            Text(detalle!,
                textAlign: TextAlign.center,
                style: context.texto.bodySmall?.copyWith(height: 1.5)),
          ],
          if (accion != null) ...[
            const SizedBox(height: 16),
            accion!,
          ],
        ],
      ),
    );
  }
}

/// Barra de progreso de una categoria contra su presupuesto.
class BarraAvance extends StatelessWidget {
  const BarraAvance({
    super.key,
    required this.valor,
    required this.color,
    this.alto = 8,
  });

  /// 0 a 1. Por encima de 1 la barra se pinta en rojo y se recorta.
  final double valor;
  final Color color;
  final double alto;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final excedido = valor > 1;
    return ClipRRect(
      borderRadius: BorderRadius.circular(alto),
      child: LinearProgressIndicator(
        value: valor.clamp(0.0, 1.0),
        minHeight: alto,
        backgroundColor: t.superficie2,
        valueColor:
            AlwaysStoppedAnimation(excedido ? t.critico : color),
      ),
    );
  }
}

/// Monto con color segun si suma o resta.
class Monto extends StatelessWidget {
  const Monto(
    this.valor, {
    super.key,
    this.moneda = 'PEN',
    this.estilo,
    this.conSigno = false,
    this.colorear = true,
  });

  final double valor;
  final String moneda;
  final TextStyle? estilo;
  final bool conSigno;
  final bool colorear;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = !colorear
        ? null
        : valor > 0
            ? t.bueno
            : (valor < 0 ? t.critico : t.tinta2);
    final signo = conSigno && valor > 0 ? '+' : '';
    return Text(
      '$signo${plata(valor, moneda: moneda)}',
      style: (estilo ?? context.texto.titleSmall)?.copyWith(color: color),
    );
  }
}

/// Circulito de color con el emoji de la categoria.
class InsigniaCategoria extends StatelessWidget {
  const InsigniaCategoria({
    super.key,
    required this.color,
    this.icono = '',
    this.tamano = 38,
  });

  final Color color;
  final String icono;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: icono.isEmpty
          ? Icon(Icons.receipt_long_outlined,
              size: tamano * 0.5, color: color)
          : Text(icono, style: TextStyle(fontSize: tamano * 0.45)),
    );
  }
}
