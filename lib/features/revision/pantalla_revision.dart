import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formato.dart';
import '../../core/tema.dart';
import '../../domain/movimiento.dart';
import '../../providers.dart';
import '../../widgets/async.dart';
import '../../widgets/comunes.dart';
import '../movimientos/editor_movimiento.dart';
import '../movimientos/ficha_movimiento.dart';

/// La bandeja de revision.
///
/// Aqui llega lo que el sistema no supo clasificar con confianza. Cada
/// correccion que haces aqui se convierte en una regla, asi que la bandeja se
/// vacia sola con el tiempo.
class PantallaRevision extends ConsumerWidget {
  const PantallaRevision({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendientes = ref.watch(pendientesProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.read(revisionProvider.notifier).refrescar(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          Bloque(
            titulo: 'Bandeja de revision',
            nota: 'Aqui llegan los movimientos con informacion incompleta o '
                'clasificacion dudosa. Cuando corriges la categoria, el '
                'sistema crea una regla y la proxima vez lo hace solo.',
            accion: TextButton.icon(
              icon: const Icon(Icons.auto_fix_high, size: 18),
              label: const Text('Reaplicar'),
              onPressed: () async {
                final n = await ref.read(repositorioProvider).reclasificar();
                ref.read(revisionProvider.notifier).refrescar();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(n == 0
                        ? 'No hubo nada que reclasificar.'
                        : '$n movimiento(s) se resolvieron solos.'),
                  ),
                );
              },
            ),
            child: pendientes.vista(
              (lista) => lista.isEmpty
                  ? const Vacio(
                      titulo: 'Todo en orden',
                      detalle: 'No hay nada esperando tu decision.',
                      icono: Icons.check_circle_outline,
                    )
                  : Text(
                      '${lista.length} movimiento(s) esperan tu decision.',
                      style: context.texto.bodyMedium,
                    ),
              altoCarga: 80,
            ),
          ),
          const SizedBox(height: 14),
          pendientes.vista(
            (lista) => Column(
              children: [
                for (final m in lista) _Pendiente(m),
              ],
            ),
            alReintentar: () => ref.invalidate(pendientesProvider),
          ),
        ],
      ),
    );
  }
}

class _Pendiente extends ConsumerWidget {
  const _Pendiente(this.m);

  final Movimiento m;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FichaMovimiento(m),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: t.aviso.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.help_outline, size: 16, color: t.aviso),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        m.motivoRevision.isEmpty
                            ? 'Revisa que los datos esten bien.'
                            : m.motivoRevision,
                        style: context.texto.bodySmall
                            ?.copyWith(color: t.tinta2, height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _descartar(context, ref),
                      child: const Text('No es mio'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => abrirEditorMovimiento(context, ref, m),
                      child: const Text('Clasificar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _descartar(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Descartar este movimiento?'),
        content: Text(
          'Se quitara de tus totales. No se borra del todo: sigue guardado '
          'para que el mismo correo no se vuelva a registrar en la proxima '
          'sincronizacion.\n\n${m.comercio} · ${plata(m.importe, moneda: m.moneda)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await ref
        .read(daoProvider)
        .anularMovimiento(m.id, motivo: 'Descartado desde revision');
    ref.read(revisionProvider.notifier).refrescar();
  }
}
