import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/fechas.dart';
import '../../core/formato.dart';
import '../../core/tema.dart';
import '../../domain/catalogo.dart';
import '../../domain/enums.dart';
import '../../domain/movimiento.dart';
import '../../providers.dart';
import '../../widgets/comunes.dart';
import 'editor_movimiento.dart';

/// Una fila de movimiento. Se reutiliza en Dashboard, Movimientos y Revision.
class FichaMovimiento extends ConsumerWidget {
  const FichaMovimiento(
    this.m, {
    super.key,
    this.mostrarFecha = true,
    this.alTocar,
  });

  final Movimiento m;
  final bool mostrarFecha;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final categorias = ref.watch(categoriasProvider).valueOrNull ?? const [];
    final cat = _buscar(categorias, m);
    final tapado = ref.watch(privacidadProvider);

    // El prototipo firma cada fila con el banco y los ultimos cuatro: con dos
    // tarjetas del mismo banco, el nombre del comercio solo no alcanza para
    // saber con cual pagaste.
    final cuentas = ref.watch(cuentasProvider).valueOrNull ?? const [];
    final cuenta = m.cuentaId.isEmpty
        ? null
        : cuentas.where((c) => c.id == m.cuentaId).firstOrNull;
    final banco = m.banco.isNotEmpty ? m.banco : (cuenta?.banco ?? '');
    final ultimos4 = cuenta?.ultimos4 ?? '';
    final firma = [
      if (banco.isNotEmpty) banco,
      if (ultimos4.isNotEmpty) '····$ultimos4',
    ].join(' ');

    final color = Tokens.desdeHex(cat?.color ?? '#94A3B8');
    final esIngreso = m.tipo == TipoMovimiento.ingreso ||
        m.tipo == TipoMovimiento.devolucion;
    final esNeutro = m.tipo.esNeutro;

    return InkWell(
      onTap: alTocar ?? () => abrirEditorMovimiento(context, ref, m),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
        child: Row(
          children: [
            InsigniaCategoria(color: color, icono: cat?.icono ?? ''),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          m.comercio.isEmpty ? 'Sin identificar' : m.comercio,
                          style: context.texto.bodyMedium
                              ?.copyWith(color: t.tinta, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (m.necesitaRevision) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.error_outline, size: 15, color: t.aviso),
                      ],
                      if (m.recurrente) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.autorenew, size: 14, color: t.apagado),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (mostrarFecha) fechaCorta(m.fecha),
                      if (m.subcategoria.isNotEmpty)
                        m.subcategoria
                      else if (m.categoria.isNotEmpty)
                        m.categoria,
                      if (firma.isNotEmpty)
                        firma
                      else if (m.medioPago.isNotEmpty)
                        MedioPago.etiqueta(m.medioPago),
                    ].join(' · '),
                    style: context.texto.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${tapado || esNeutro ? '' : (esIngreso ? '+' : '-')}'
                  '${plataQuiza(m.importe, moneda: m.moneda, tapado: tapado)}',
                  style: context.texto.titleSmall?.copyWith(
                    color: esIngreso
                        ? t.bueno
                        : (esNeutro ? t.apagado : t.tinta),
                  ),
                ),
                // El equivalente en soles es referencia, no total: solo se
                // muestra en la moneda que no es la del libro.
                if (m.moneda != 'PEN')
                  Text(
                    plataQuiza(m.importePen, tapado: tapado),
                    style: context.texto.bodySmall,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Categoria? _buscar(List<Categoria> cats, Movimiento m) {
    for (final c in cats) {
      if (c.categoria == m.categoria && c.subcategoria == m.subcategoria) {
        return c;
      }
    }
    for (final c in cats) {
      if (c.categoria == m.categoria) return c;
    }
    return null;
  }
}
