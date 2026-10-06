import 'package:flutter/material.dart';

import '../core/tema.dart';

/// La rana de Leep.
///
/// Es una rana y tres barras que suben: el salto y el ahorro en la misma
/// figura. El PNG es una silueta con alfa y sin color propio, asi que se
/// pinta con el que le toque en cada tema.
///
/// La regla del pliego: de 76 a 16 px, y por debajo de 40 va en un solo tono,
/// que es lo que hace esto siempre (no hay version a dos tintas todavia).
class MarcaLeep extends StatelessWidget {
  const MarcaLeep({super.key, this.tamanio = 28, this.color});

  final double tamanio;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/marca/leep-mark.png',
      width: tamanio,
      height: tamanio,
      color: color ?? context.tokens.marca,
      filterQuality: FilterQuality.medium,
      // Si el asset falta, la app no se cae por un logo.
      errorBuilder: (_, __, ___) => SizedBox(width: tamanio, height: tamanio),
    );
  }
}

/// La rana saltando: el indicador de carga de Leep.
///
/// En el prototipo es lo que hace un boton mientras trabaja, en vez de una
/// ruedita. La rana se aplasta al caer, se estira en el aire y el charco de
/// abajo se encoge con ella.
///
/// Respeta `prefers-reduced-motion`: si el sistema pide menos movimiento, la
/// rana se queda quieta y solo se atenua. Un indicador de carga no vale una
/// jaqueca.
class RanaCargando extends StatefulWidget {
  const RanaCargando({super.key, this.tamanio = 22, this.color});

  final double tamanio;
  final Color? color;

  @override
  State<RanaCargando> createState() => _EstadoRana();
}

class _EstadoRana extends State<RanaCargando>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void initState() {
    super.initState();
    _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Las posiciones del salto del prototipo, tal cual: aplastarse al 14 %,
  /// estirarse en el aire al 38 %, cumbre al 56 %, y aterrizar al 76 %.
  ({double y, double sx, double sy, double giro}) _paso(double t) {
    if (t < 0.14) {
      final k = t / 0.14;
      return (y: k, sx: 1 + 0.14 * k, sy: 1 - 0.16 * k, giro: 0);
    }
    if (t < 0.38) {
      final k = (t - 0.14) / 0.24;
      return (
        y: 1 - 10 * k,
        sx: 1.14 - 0.24 * k,
        sy: 0.84 + 0.26 * k,
        giro: -0.105 * k,
      );
    }
    if (t < 0.56) {
      final k = (t - 0.38) / 0.18;
      return (
        y: -9 - k,
        sx: 0.9 + 0.1 * k,
        sy: 1.1 - 0.1 * k,
        giro: -0.105 + 0.052 * k,
      );
    }
    if (t < 0.76) {
      final k = (t - 0.56) / 0.2;
      return (
        y: -10 + 10 * k,
        sx: 1 + 0.12 * k,
        sy: 1 - 0.12 * k,
        giro: -0.052 + 0.052 * k,
      );
    }
    final k = (t - 0.76) / 0.24;
    return (y: 0, sx: 1.12 - 0.12 * k, sy: 0.88 + 0.12 * k, giro: 0);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.tokens.marca;
    final quieto = MediaQuery.disableAnimationsOf(context);

    if (quieto) {
      return Opacity(
        opacity: 0.6,
        child: MarcaLeep(tamanio: widget.tamanio, color: color),
      );
    }

    return SizedBox(
      width: widget.tamanio * 1.5,
      height: widget.tamanio * 1.9,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final p = _paso(_c.value);
          // El charco se encoge y se desvanece al mismo compas que el salto.
          final alturaSalto = (-p.y / 10).clamp(0.0, 1.0);
          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                bottom: 0,
                child: Opacity(
                  opacity: 0.28 * (1 - alturaSalto * 0.7),
                  child: Container(
                    width: widget.tamanio * (1 - alturaSalto * 0.45),
                    height: 3,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 6,
                child: Transform.translate(
                  offset: Offset(0, p.y),
                  child: Transform.rotate(
                    angle: p.giro,
                    child: Transform.scale(
                      scaleX: p.sx,
                      scaleY: p.sy,
                      // Se escala desde abajo: una rana que se aplasta lo
                      // hace contra el suelo, no contra su propio centro.
                      alignment: Alignment.bottomCenter,
                      child: MarcaLeep(tamanio: widget.tamanio, color: color),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
