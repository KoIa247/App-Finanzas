import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formato.dart';
import '../../core/tema.dart';
import '../../domain/finanzas.dart';
import '../../providers.dart';
import '../../widgets/async.dart';
import '../../widgets/comunes.dart';

/// Suscripciones detectadas.
///
/// El motor que las encuentra ya existia y lo usaba el Resumen para una lista
/// corta. Lo que faltaba era la pantalla: ver el ano completo de golpe es lo
/// que hace que uno de baja a algo, no ver S/ 38.90 al mes.
///
/// Nada de esto se guarda en una tabla. Sale de mirar el historial cada vez,
/// asi que una suscripcion que deja de cobrarse deja de aparecer sola.
class PantallaSuscripciones extends ConsumerWidget {
  const PantallaSuscripciones({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final futuro = ref.watch(suscripcionesProvider);

    return futuro.vista((todas) {
      final activas = todas.where((s) => s.activa).toList();
      final bajas = todas.where((s) => !s.activa).toList();

      if (todas.isEmpty) {
        return const Vacio(
          titulo: 'Todavia no detectamos suscripciones',
          detalle: 'Hace falta que un mismo cargo se repita unos meses con el '
              'mismo monto y cerca del mismo dia. Sincroniza el correo y '
              'vuelve en un par de meses.',
          icono: Icons.autorenew,
        );
      }

      return RefreshIndicator(
        onRefresh: () async => ref.read(revisionProvider.notifier).refrescar(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            _Portada(activas),
            const SizedBox(height: 16),
            if (activas.isNotEmpty) ...[
              Text('Activas', style: context.texto.titleMedium),
              const SizedBox(height: 10),
              for (final s in activas) _Ficha(s),
            ],
            if (bajas.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Puede que ya no las tengas',
                  style: context.texto.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Llevan tiempo sin cobrarte. Si ya las diste de baja, marcalas '
                'para que dejen de contar.',
                style: context.texto.bodySmall,
              ),
              const SizedBox(height: 10),
              for (final s in bajas) _Ficha(s, apagada: true),
            ],
          ],
        ),
      );
    });
  }
}

/// Lo que cuestan al ano, que es el numero que mueve a cancelar algo.
class _Portada extends ConsumerWidget {
  const _Portada(this.activas);

  final List<Suscripcion> activas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final tapado = ref.watch(privacidadProvider);
    final moneda = ref.watch(monedaProvider);

    final alAnio = activas.fold(0.0, (a, s) => a + s.costoAnual);
    final alMes = activas.fold(0.0, (a, s) => a + s.importePromedio);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radioTarjeta),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.portada, t.portada.withValues(alpha: 0.86)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TE CUESTAN AL ANIO',
            style: context.texto.labelSmall
                ?.copyWith(color: t.portadaTinta.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              plataQuiza(alAnio, moneda: moneda, tapado: tapado),
              style:
                  context.texto.displaySmall?.copyWith(color: t.portadaTinta),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${activas.length} activa(s) · '
            '${plataQuiza(alMes, moneda: moneda, tapado: tapado)} al mes',
            style: context.texto.bodySmall?.copyWith(
              color: t.portadaTinta.withValues(alpha: 0.86),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

/// Una suscripcion.
class _Ficha extends ConsumerWidget {
  const _Ficha(this.s, {this.apagada = false});

  final Suscripcion s;
  final bool apagada;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final tapado = ref.watch(privacidadProvider);
    final moneda = ref.watch(monedaProvider);

    // El importe se muestra en la moneda en que de verdad se cobra: una
    // suscripcion en dolares que se vea en soles invita a buscarla en el
    // estado de cuenta equivocado.
    final enSuMoneda = s.monedaOriginal != 'PEN' && s.importeOriginal > 0;
    final importe = enSuMoneda ? s.importeOriginal : s.importePromedio;
    final monedaMostrada = enSuMoneda ? s.monedaOriginal : moneda;

    final detalle = [
      if (s.subcategoria.isNotEmpty) s.subcategoria,
      'dia ~${s.diaAproximado}',
      if (apagada) '${s.diasSinCobrar} dias sin cobrar',
    ].join(' · ');

    return Opacity(
      opacity: apagada ? 0.72 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.superficie,
          borderRadius: BorderRadius.circular(radioTarjeta),
          border: Border.all(color: t.borde),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.comercio,
                        style: context.texto.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(detalle, style: context.texto.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      plataQuiza(
                        importe,
                        moneda: monedaMostrada,
                        tapado: tapado,
                      ),
                      style: context.texto.titleSmall,
                    ),
                    Text('al mes', style: context.texto.bodySmall),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Al anio: ${plataQuiza(
                      enSuMoneda ? s.importeOriginal * 12 : s.costoAnual,
                      moneda: monedaMostrada,
                      tapado: tapado,
                    )}',
                    style: context.texto.bodySmall?.copyWith(color: t.aviso),
                  ),
                ),
                TextButton(
                  onPressed: () => _noEs(context, ref),
                  child: Text(apagada ? 'Ya no la tengo' : 'No es suscripcion'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _noEs(BuildContext context, WidgetRef ref) async {
    await ref
        .read(repositorioProvider)
        .marcarSuscripcion(s.comercio, esta: false);
    ref.read(revisionProvider.notifier).refrescar();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${s.comercio} ya no cuenta como suscripcion')),
    );
  }
}
