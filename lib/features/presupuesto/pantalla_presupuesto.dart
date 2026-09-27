import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/fechas.dart';
import '../../core/formato.dart';
import '../../core/tema.dart';
import '../../domain/finanzas.dart';
import '../../providers.dart';
import '../../widgets/async.dart';
import '../../widgets/comunes.dart';

class PantallaPresupuesto extends ConsumerWidget {
  const PantallaPresupuesto({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avances = ref.watch(presupuestoProvider);
    final periodo = ref.watch(periodoProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.read(revisionProvider.notifier).refrescar(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          avances.vista(
            (lista) => _Contenido(lista: lista, periodo: periodo),
            alReintentar: () => ref.invalidate(presupuestoProvider),
            altoCarga: 260,
          ),
        ],
      ),
    );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido({required this.lista, required this.periodo});

  final List<AvancePresupuesto> lista;
  final String periodo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final presupuestado = lista.fold(0.0, (a, l) => a + l.presupuestado);
    final gastado = lista.fold(0.0, (a, l) => a + l.gastado);
    final disponible = presupuestado - gastado;
    final consumo = presupuestado > 0 ? gastado / presupuestado : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (lista.isEmpty)
          Bloque(
            titulo: 'Presupuesto de ${periodoLegible(periodo)}',
            child: Vacio(
              titulo: 'Todavia no pusiste limites',
              detalle: 'Define cuanto quieres gastar en cada categoria y la '
                  'app te avisa cuando te acercas.',
              icono: Icons.pie_chart_outline,
              accion: FilledButton(
                onPressed: () => _editar(context, ref, periodo),
                child: const Text('Crear presupuesto'),
              ),
            ),
          )
        else ...[
          RejillaFichas(fichas: [
            Ficha(
              etiqueta: 'Presupuestado',
              valor: plata(presupuestado, moneda: ref.watch(monedaProvider)),
            ),
            Ficha(
              etiqueta: 'Gastado',
              valor: plata(gastado, moneda: ref.watch(monedaProvider)),
            ),
            Ficha(
              etiqueta: 'Disponible',
              valor: plata(disponible, moneda: ref.watch(monedaProvider)),
              color: disponible < 0 ? t.critico : t.bueno,
            ),
            Ficha(
              etiqueta: 'Consumido',
              valor: porcentaje(consumo),
              color: consumo > 1 ? t.critico : (consumo > 0.85 ? t.aviso : null),
            ),
          ]),
          const SizedBox(height: 14),
          Bloque(
            titulo: 'Por categoria',
            accion: TextButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Editar'),
              onPressed: () => _editar(context, ref, periodo),
            ),
            child: Column(
              children: [
                for (final a in lista)
                  _FilaAvance(
                    a,
                    moneda: ref.watch(monedaProvider),
                    tapado: ref.watch(privacidadProvider),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        _SinPresupuesto(periodo: periodo),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          icon: const Icon(Icons.copy_all_outlined, size: 18),
          label: Text('Copiar de ${periodoCorto(periodoAnterior(periodo))}'),
          onPressed: () async {
            final n = await ref
                .read(daoProvider)
                .copiarPresupuesto(
                  periodoAnterior(periodo),
                  periodo,
                  ref.read(monedaProvider),
                );
            ref.read(revisionProvider.notifier).refrescar();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(n == 0
                    ? 'No habia nada que copiar del mes anterior.'
                    : 'Se copiaron $n categoria(s).'),
              ),
            );
          },
        ),
      ],
    );
  }

  void _editar(BuildContext context, WidgetRef ref, String periodo) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EditorPresupuesto(periodo),
    );
  }
}

class _FilaAvance extends StatelessWidget {
  const _FilaAvance(this.a, {required this.moneda, this.tapado = false});

  final AvancePresupuesto a;
  final String moneda;
  final bool tapado;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = Tokens.desdeHex(a.color);

    String monto(num v) => plataQuiza(v, moneda: moneda, tapado: tapado);

    // El estado va debajo del nombre y no debajo de la barra: es lo que se
    // viene a leer, y en el prototipo manda sobre la cifra exacta.
    final estado = a.excedido
        ? 'Te pasaste por ${monto(-a.disponible)}'
        : 'Te quedan ${monto(a.disponible)}';
    final colorEstado = a.excedido
        ? t.critico
        : (a.porcentaje > 0.85 ? t.aviso : t.apagado);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (a.icono.isNotEmpty) ...[
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    // Insignias circulares al 18 % de su color, como el pliego.
                    color: color.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Text(a.icono, style: const TextStyle(fontSize: 15)),
                ),
                const SizedBox(width: 11),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.etiqueta,
                      style: context.texto.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      estado,
                      style: context.texto.bodySmall
                          ?.copyWith(color: colorEstado),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Solo el limite. El prototipo no pone el par
              // gastado/presupuestado en la fila: lo gastado ya lo dice la
              // barra, y meterlo aqui dejaba el estado cortado a la mitad de
              // un monto.
              Text(
                monto(a.presupuestado),
                style: context.texto.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 9),
          BarraAvance(valor: a.porcentaje, color: color),
        ],
      ),
    );
  }
}

class _SinPresupuesto extends ConsumerWidget {
  const _SinPresupuesto({required this.periodo});

  final String periodo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final futuro = ref.watch(gastoSinPresupuestoProvider);

    return futuro.vista(
      (lista) {
        if (lista.isEmpty) return const SizedBox.shrink();
        return Bloque(
          titulo: 'Gasto sin presupuesto asignado',
          nota: 'Categorias en las que gastaste este mes pero a las que no les '
              'pusiste un limite.',
          child: Column(
            children: [
              for (final c in lista)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      InsigniaCategoria(
                        color: Tokens.desdeHex(c.color),
                        icono: c.icono,
                        tamano: 30,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(c.categoria,
                          style: context.texto.bodyMedium)),
                      Text(plata(c.monto), style: context.texto.titleSmall),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
      altoCarga: 90,
    );
  }
}

/// Editor de montos por categoria.
class _EditorPresupuesto extends ConsumerStatefulWidget {
  const _EditorPresupuesto(this.periodo);

  final String periodo;

  @override
  ConsumerState<_EditorPresupuesto> createState() => _EstadoEditor();
}

class _EstadoEditor extends ConsumerState<_EditorPresupuesto> {
  final Map<String, TextEditingController> _campos = {};
  bool _listo = false;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final lineas = await ref
        .read(daoProvider)
        .presupuesto(widget.periodo, ref.read(monedaProvider));
    final actuales = {for (final l in lineas) l.categoria: l.monto};
    final categorias = await ref.read(daoProvider).categorias();

    final grupos = <String>[];
    for (final c in categorias) {
      // Solo los grupos de gasto: no tiene sentido presupuestar tus ingresos ni
      // los movimientos internos.
      if (c.tipoAplicable != 'GASTO') continue;
      if (c.categoria == 'Sin clasificar') continue;
      if (!grupos.contains(c.categoria)) grupos.add(c.categoria);
    }

    for (final g in grupos) {
      final v = actuales[g] ?? 0;
      _campos[g] =
          TextEditingController(text: v > 0 ? v.toStringAsFixed(0) : '');
    }
    if (mounted) setState(() => _listo = true);
  }

  @override
  void dispose() {
    for (final c in _campos.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scroll) {
          if (!_listo) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
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
                    Text('Presupuesto de ${periodoLegible(widget.periodo)}',
                        style: context.texto.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Deja en blanco lo que no quieras limitar.',
                      style: context.texto.bodySmall,
                    ),
                    const SizedBox(height: 18),
                    for (final e in _campos.entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextField(
                          controller: e.value,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[\d.,]')),
                          ],
                          decoration: InputDecoration(
                            labelText: e.key,
                            prefixText: 'S/ ',
                            hintText: '0',
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _guardando ? null : _guardar,
                      child: const Text('Guardar presupuesto'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);

    // La moneda va en cada linea, no solo en el borrado: si se quedara con el
    // 'PEN' por defecto, guardar el presupuesto en dolares borraria el de
    // dolares y escribiria las lineas en el libro de soles.
    final moneda = ref.read(monedaProvider);

    final lineas = <LineaPresupuesto>[];
    _campos.forEach((categoria, c) {
      final v = double.tryParse(c.text.replaceAll(',', '.')) ?? 0;
      if (v <= 0) return;
      lineas.add(LineaPresupuesto(
        periodo: widget.periodo,
        categoria: categoria,
        moneda: moneda,
        monto: v,
      ));
    });

    await ref
        .read(daoProvider)
        .guardarPresupuesto(widget.periodo, moneda, lineas);
    ref.read(revisionProvider.notifier).refrescar();
    if (!mounted) return;
    Navigator.pop(context);
  }
}
