import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/tema.dart';
import '../../domain/catalogo.dart';
import '../../providers.dart';
import '../../widgets/async.dart';
import '../../widgets/comunes.dart';

/// Categorias y subcategorias.
///
/// La parte util no es poder crear una categoria, sino poder arreglar la que
/// el clasificador eligio mal. Por eso renombrar arrastra el cambio a los
/// movimientos, las reglas y el presupuesto que ya la usaban: cambiarle el
/// nombre solo al catalogo dejaria el historial hablando de algo que ya no
/// existe.
class PantallaCategorias extends ConsumerWidget {
  const PantallaCategorias({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final futuro = ref.watch(categoriasProvider);

    return futuro.vista((cats) {
      final grupos = <String, List<Categoria>>{};
      for (final c in cats) {
        grupos.putIfAbsent(c.categoria, () => []).add(c);
      }

      return RefreshIndicator(
        onRefresh: () async => ref.read(revisionProvider.notifier).refrescar(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            Text(
              'Vienen ${grupos.length} grupos con sus subcategorias de '
              'fabrica. Puedes crear las tuyas y decidir a que categoria '
              'pertenece cada parte.',
              style: context.texto.bodyMedium,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => _crear(context, ref, grupos.keys.toList()),
              icon: const Icon(Icons.add, size: 19),
              label: const Text('Crear'),
            ),
            const SizedBox(height: 16),
            for (final g in grupos.entries) ...[
              _Grupo(nombre: g.key, partes: g.value),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 6),
            const Aviso(
              tono: TonoAviso.info,
              texto: 'Cuando corriges la categoria de un movimiento, esa '
                  'correccion se guarda como regla y la proxima vez el '
                  'sistema lo hace solo.',
            ),
          ],
        ),
      );
    });
  }

  Future<void> _crear(
    BuildContext context,
    WidgetRef ref,
    List<String> existentes,
  ) async {
    final nueva = await showModalBottomSheet<Categoria>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _HojaCategoria(existentes: existentes),
    );
    if (nueva == null) return;
    await ref.read(daoProvider).guardarCategoria(nueva);
    ref.read(revisionProvider.notifier).refrescar();
  }
}

/// Una categoria con sus partes dentro.
class _Grupo extends ConsumerWidget {
  const _Grupo({required this.nombre, required this.partes});

  final String nombre;
  final List<Categoria> partes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final cabeza = partes.first;
    final color = Tokens.desdeHex(cabeza.color, respaldo: t.marca);

    return Container(
      decoration: BoxDecoration(
        color: t.superficie,
        borderRadius: BorderRadius.circular(radioTarjeta),
        border: Border.all(color: t.borde),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        // El ExpansionTile trae sus propias lineas y no hacen falta: la
        // tarjeta ya separa un grupo del siguiente.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: InsigniaCategoria(color: color, icono: cabeza.icono),
          title: Text(nombre, style: context.texto.titleSmall),
          subtitle: Text(
            '${partes.length} subcategoria(s)',
            style: context.texto.bodySmall,
          ),
          childrenPadding: const EdgeInsets.only(bottom: 6),
          children: [
            for (final p in partes)
              ListTile(
                dense: true,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(p.icono, style: const TextStyle(fontSize: 16)),
                ),
                title: Text(p.subcategoria, style: context.texto.bodyMedium),
                trailing: Icon(Icons.edit_outlined, size: 17, color: t.apagado),
                onTap: () => _editar(context, ref, p),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editar(
    BuildContext context,
    WidgetRef ref,
    Categoria c,
  ) async {
    final cambiada = await showModalBottomSheet<Categoria>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _HojaCategoria(existentes: const [], original: c),
    );
    if (cambiada == null) return;
    await ref.read(daoProvider).renombrarCategoria(
          antesCategoria: c.categoria,
          antesSubcategoria: c.subcategoria,
          nueva: cambiada,
        );
    ref.read(revisionProvider.notifier).refrescar();
  }
}

/// Crear o editar una parte del catalogo.
class _HojaCategoria extends StatefulWidget {
  const _HojaCategoria({required this.existentes, this.original});

  final List<String> existentes;
  final Categoria? original;

  @override
  State<_HojaCategoria> createState() => _EstadoHojaCategoria();
}

class _EstadoHojaCategoria extends State<_HojaCategoria> {
  late final _categoria =
      TextEditingController(text: widget.original?.categoria ?? '');
  late final _subcategoria =
      TextEditingController(text: widget.original?.subcategoria ?? '');
  late String _icono = widget.original?.icono ?? '🏷';
  late String _color = widget.original?.color ?? '#1E5A37';

  /// Las seis paletas del pliego. No se ofrece un selector libre a proposito:
  /// doce tonos que no se pelean entre si valen mas que cualquier color.
  static const _colores = [
    '#1E5A37',
    '#0A6360',
    '#9E4420',
    '#93122E',
    '#22306B',
    '#33383A',
  ];

  static const _iconos = [
    '🏷', '🍽', '🚗', '🏠', '🩺', '🎬', '👕', '👪',
    '🏦', '🎲', '✈', '💡', '📦', '💵', '📈', '🎁',
  ];

  @override
  void dispose() {
    _categoria.dispose();
    _subcategoria.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final editando = widget.original != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: t.grilla,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                editando ? 'Editar categoria' : 'Nueva categoria',
                style: context.texto.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                editando
                    ? 'Si le cambias el nombre, el cambio se arrastra a los '
                        'movimientos y las reglas que ya la usaban.'
                    : 'Escribe un grupo que ya exista para meterla dentro, o '
                        'uno nuevo para abrir otro.',
                style: context.texto.bodySmall,
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _categoria,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Grupo'),
              ),
              if (widget.existentes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final g in widget.existentes)
                      ActionChip(
                        label: Text(g),
                        onPressed: () => setState(() => _categoria.text = g),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              TextField(
                controller: _subcategoria,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Parte'),
              ),
              const SizedBox(height: 16),
              Text('Icono', style: context.texto.labelSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final i in _iconos)
                    InkWell(
                      borderRadius: BorderRadius.circular(radioPastilla),
                      onTap: () => setState(() => _icono = i),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _icono == i
                              ? t.marca.withValues(alpha: 0.18)
                              : t.superficie2,
                          border: Border.all(
                            color: _icono == i ? t.marca : Colors.transparent,
                          ),
                        ),
                        child: Text(i, style: const TextStyle(fontSize: 17)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Color', style: context.texto.labelSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final c in _colores)
                    InkWell(
                      borderRadius: BorderRadius.circular(radioPastilla),
                      onTap: () => setState(() => _color = c),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Tokens.desdeHex(c),
                          border: Border.all(
                            color: _color == c ? t.tinta : Colors.transparent,
                            width: 2.4,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () {
                  final g = _categoria.text.trim();
                  final p = _subcategoria.text.trim();
                  if (g.isEmpty || p.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ponle grupo y parte a la categoria.'),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(
                    context,
                    Categoria(
                      categoria: g,
                      subcategoria: p,
                      tipoAplicable:
                          widget.original?.tipoAplicable ?? 'GASTO',
                      icono: _icono,
                      color: _color,
                      orden: widget.original?.orden ?? 500,
                    ),
                  );
                },
                child: Text(editando ? 'Guardar' : 'Crear'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
