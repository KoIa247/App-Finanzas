import 'package:flutter/material.dart';

/// La curva de Leep. Es la del prototipo, `cubic-bezier(.2,.8,.2,1)`: sale
/// rapido y frena largo, que es lo que hace que algo parezca que llega a su
/// sitio en vez de que lo empujen.
const Curve curvaLeep = Cubic(0.2, 0.8, 0.2, 1);

/// Las barras crecen desde cero: el `@keyframes grow` del prototipo.
///
/// No es adorno. Una barra que crece se lee como una cantidad que se llena, y
/// de paso obliga al ojo a mirar donde termina, que es el dato.
class CrecerX extends StatelessWidget {
  const CrecerX({
    super.key,
    required this.child,
    this.duracion = const Duration(milliseconds: 600),
  });

  final Widget child;
  final Duration duracion;

  @override
  Widget build(BuildContext context) {
    // Si el sistema pide menos movimiento, la barra aparece ya llena.
    if (MediaQuery.disableAnimationsOf(context)) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duracion,
      curve: curvaLeep,
      builder: (context, v, hijo) => Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: v.clamp(0.0, 1.0),
          child: hijo,
        ),
      ),
      child: child,
    );
  }
}

/// El `@keyframes popIn`: aparece subiendo diez pixeles.
///
/// Se usa en lo que entra despues de que la pantalla ya esta, no en todo lo
/// que se dibuja: una lista entera animandose fila por fila marea.
class EntradaPop extends StatelessWidget {
  const EntradaPop({
    super.key,
    required this.child,
    this.duracion = const Duration(milliseconds: 300),
    this.retraso = Duration.zero,
  });

  final Widget child;
  final Duration duracion;

  /// Para escalonar dos o tres cosas. Mas de eso se nota como lentitud.
  final Duration retraso;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duracion + retraso,
      curve: retraso == Duration.zero
          ? curvaLeep
          : Interval(
              retraso.inMilliseconds / (duracion + retraso).inMilliseconds,
              1,
              curve: curvaLeep,
            ),
      builder: (context, v, hijo) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - v)),
          child: hijo,
        ),
      ),
      child: child,
    );
  }
}
