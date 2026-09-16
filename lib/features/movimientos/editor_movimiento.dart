import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/fechas.dart';
import '../../core/formato.dart';
import '../../core/tema.dart';
import '../../domain/catalogo.dart';
import '../../domain/enums.dart';
import '../../domain/movimiento.dart';
import '../../providers.dart';

/// Abre el editor de un movimiento.
Future<void> abrirEditorMovimiento(
  BuildContext context,
  WidgetRef ref,
  Movimiento m,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _Editor(m),
  );
}

class _Editor extends ConsumerStatefulWidget {
  const _Editor(this.m);

  final Movimiento m;

  @override
  ConsumerState<_Editor> createState() => _EstadoEditor();
}

class _EstadoEditor extends ConsumerState<_Editor> {
  late final TextEditingController _comercio =
      TextEditingController(text: widget.m.comercio);
  late final TextEditingController _importe =
      TextEditingController(text: widget.m.importe.toStringAsFixed(2));
  late final TextEditingController _notas =
      TextEditingController(text: widget.m.notas);

  late String _categoria = widget.m.categoria;
  late String _subcategoria = widget.m.subcategoria;
  late TipoMovimiento _tipo = widget.m.tipo;
  late bool _recurrente = widget.m.recurrente;
  bool _aprender = true;
  bool _guardando = false;

  @override
  void dispose() {
    _comercio.dispose();
    _importe.dispose();
    _notas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final categorias = ref.watch(categoriasProvider).valueOrNull ?? const [];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scroll) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: t.grilla,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Editar movimiento',
                            style: context.texto.titleMedium),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Text(
                    '${widget.m.id} · ${fechaCorta(widget.m.fecha)} '
                    '${widget.m.hora} · ${widget.m.banco}',
                    style: context.texto.bodySmall,
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller: _comercio,
                    decoration: const InputDecoration(labelText: 'Comercio'),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _importe,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Importe',
                      prefixText: widget.m.moneda == 'USD' ? r'$ ' : 'S/ ',
                    ),
                  ),
                  if (widget.m.moneda != 'PEN') ...[
                    const SizedBox(height: 6),
                    Text(
                      'Equivale a ${plata(widget.m.importePen)} '
                      '(TC ${widget.m.tipoCambio?.toStringAsFixed(3) ?? '—'})',
                      style: context.texto.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 12),

                  DropdownButtonFormField<TipoMovimiento>(
                    initialValue: _tipo,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: [
                      for (final tipo in TipoMovimiento.values)
                        DropdownMenuItem(
                            value: tipo, child: Text(tipo.etiqueta)),
                    ],
                    onChanged: (v) => setState(() => _tipo = v ?? _tipo),
                  ),
                  const SizedBox(height: 12),

                  _SelectorCategoria(
                    categorias: categorias,
                    categoria: _categoria,
                    subcategoria: _subcategoria,
                    alElegir: (c, s) => setState(() {
                      _categoria = c;
                      _subcategoria = s;
                    }),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _notas,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notas',
                      hintText: 'Opcional',
                    ),
                  ),
                  const SizedBox(height: 8),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _recurrente,
                    onChanged: (v) => setState(() => _recurrente = v),
                    title: const Text('Es una suscripcion'),
                    subtitle: const Text(
                        'Se cobra sola cada mes. Aparecera en el resumen de '
                        'suscripciones.'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _aprender,
                    onChanged: (v) => setState(() => _aprender = v),
                    title: const Text('Recordar esta correccion'),
                    subtitle: Text(
                      'La proxima compra en ${_comercio.text.trim().isEmpty ? 'este comercio' : _comercio.text.trim()} '
                      'se clasificara sola.',
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Descartar'),
                          onPressed: _guardando ? null : _descartar,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: _guardando ? null : _guardar,
                          child: _guardando
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Guardar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (_categoria.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige una categoria.')),
      );
      return;
    }
    setState(() => _guardando = true);

    final importe = double.tryParse(_importe.text.replaceAll(',', '.')) ??
        widget.m.importe;

    await ref.read(repositorioProvider).corregirMovimiento(
          widget.m,
          categoria: _categoria,
          subcategoria: _subcategoria,
          tipo: _tipo,
          recurrente: _recurrente,
          comercio: _comercio.text.trim(),
          importe: importe,
          notas: _notas.text.trim(),
          aprender: _aprender,
        );

    ref.read(revisionProvider.notifier).refrescar();
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _descartar() async {
    await ref
        .read(daoProvider)
        .anularMovimiento(widget.m.id, motivo: 'Descartado por el usuario');
    ref.read(revisionProvider.notifier).refrescar();
    if (!mounted) return;
    Navigator.pop(context);
  }
}

/// Selector de categoria en dos pasos: primero el grupo, despues el detalle.
class _SelectorCategoria extends StatelessWidget {
  const _SelectorCategoria({
    required this.categorias,
    required this.categoria,
    required this.subcategoria,
    required this.alElegir,
  });

  final List<Categoria> categorias;
  final String categoria;
  final String subcategoria;
  final void Function(String categoria, String subcategoria) alElegir;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final grupos = <String>[];
    for (final c in categorias) {
      if (!grupos.contains(c.categoria)) grupos.add(c.categoria);
    }
    final subs = categorias
        .where((c) => c.categoria == categoria)
        .map((c) => c.subcategoria)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: grupos.contains(categoria) ? categoria : null,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Categoria'),
          items: [
            for (final g in grupos)
              DropdownMenuItem(value: g, child: Text(g)),
          ],
          onChanged: (v) {
            if (v == null) return;
            final primera = categorias
                .where((c) => c.categoria == v)
                .map((c) => c.subcategoria)
                .firstOrNull;
            alElegir(v, primera ?? '');
          },
        ),
        if (subs.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in subs)
                ChoiceChip(
                  label: Text(s),
                  selected: s == subcategoria,
                  showCheckmark: false,
                  selectedColor: marca.withValues(alpha: 0.16),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    color: s == subcategoria ? marca : t.tinta2,
                    fontWeight:
                        s == subcategoria ? FontWeight.w600 : FontWeight.w400,
                  ),
                  onSelected: (_) => alElegir(categoria, s),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
