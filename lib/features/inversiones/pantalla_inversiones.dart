import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formato.dart';
import '../../core/tema.dart';
import '../../domain/finanzas.dart';
import '../../providers.dart';
import '../../widgets/async.dart';
import '../../widgets/comunes.dart';
import '../../widgets/graficos.dart';

class PantallaInversiones extends ConsumerWidget {
  const PantallaInversiones({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posiciones = ref.watch(posicionesProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.read(revisionProvider.notifier).refrescar(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          posiciones.vista(
            (lista) => _Contenido(lista),
            alReintentar: () => ref.invalidate(posicionesProvider),
            altoCarga: 260,
          ),
        ],
      ),
    );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido(this.posiciones);

  final List<PosicionInversion> posiciones;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;

    if (posiciones.isEmpty) {
      return Bloque(
        titulo: 'Portafolio',
        child: Vacio(
          titulo: 'Todavia no registraste inversiones',
          detalle: 'Si ya tienes plata invertida, usa el boton de abajo: te '
              'pide cuanto pusiste y cuanto vale hoy, y listo. No necesitas '
              'reconstruir cada compra.',
          icono: Icons.trending_up,
          accion: FilledButton(
            onPressed: () => _abrirPosicionInicial(context, ref),
            child: const Text('Ya tengo invertido'),
          ),
        ),
      );
    }

    final costo = posiciones.fold(0.0, (a, p) => a + p.costoTotal);
    final valor = posiciones.fold(0.0, (a, p) => a + p.valorActual);
    final ganancia = valor - costo;
    final rendimiento = costo > 0 ? ganancia / costo : 0.0;
    final moneda = posiciones.first.moneda;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RejillaFichas(fichas: [
          Ficha(etiqueta: 'Invertido', valor: plata(costo, moneda: moneda)),
          Ficha(etiqueta: 'Vale hoy', valor: plata(valor, moneda: moneda)),
          Ficha(
            etiqueta: 'Ganancia',
            valor: plata(ganancia, moneda: moneda),
            color: ganancia >= 0 ? t.bueno : t.critico,
          ),
          Ficha(
            etiqueta: 'Rendimiento',
            valor: porcentajeConSigno(rendimiento),
            color: rendimiento >= 0 ? t.bueno : t.critico,
          ),
        ]),
        const SizedBox(height: 14),
        Bloque(
          titulo: 'Posiciones',
          accion: TextButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Agregar'),
            onPressed: () => _abrirPosicionInicial(context, ref),
          ),
          child: Column(
            children: [
              for (final p in posiciones)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.nombre,
                                style: context.texto.bodyMedium
                                    ?.copyWith(color: t.tinta)),
                            Text(
                              'Costo ${plata(p.costoTotal, moneda: p.moneda)}',
                              style: context.texto.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(plata(p.valorActual, moneda: p.moneda),
                              style: context.texto.titleSmall),
                          Text(
                            porcentajeConSigno(p.rendimiento),
                            style: context.texto.bodySmall?.copyWith(
                              color: p.rendimiento >= 0 ? t.bueno : t.critico,
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
        const SizedBox(height: 14),
        Bloque(
          titulo: 'Distribucion',
          child: BarraApilada(
            porciones: [
              for (var i = 0; i < posiciones.length; i++)
                Porcion(
                  etiqueta: posiciones[i].simbolo,
                  valor: posiciones[i].valorActual,
                  color: t.serie[i % t.serie.length],
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _abrirPosicionInicial(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _FormularioPosicionInicial(),
    );
  }
}

class _FormularioPosicionInicial extends ConsumerStatefulWidget {
  const _FormularioPosicionInicial();

  @override
  ConsumerState<_FormularioPosicionInicial> createState() => _Estado();
}

class _Estado extends ConsumerState<_FormularioPosicionInicial> {
  final _simbolo = TextEditingController();
  final _nombre = TextEditingController();
  final _invertido = TextEditingController();
  final _valorHoy = TextEditingController();
  String _moneda = 'USD';

  @override
  void dispose() {
    for (final c in [_simbolo, _nombre, _invertido, _valorHoy]) {
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
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              Text('Ya tengo invertido', style: context.texto.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Sin reconstruir cada compra: solo cuanto pusiste y cuanto '
                'vale hoy.',
                style: context.texto.bodySmall,
              ),
              const SizedBox(height: 18),

              TextField(
                controller: _nombre,
                decoration: const InputDecoration(
                  labelText: 'Que es',
                  hintText: 'Fondo Trii, acciones, depositos a plazo...',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _simbolo,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Codigo corto',
                  hintText: 'TRII, VOO, DPF...',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _invertido,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Cuanto pusiste',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _valorHoy,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Cuanto vale hoy',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _moneda,
                decoration: const InputDecoration(labelText: 'Moneda'),
                items: const [
                  DropdownMenuItem(value: 'USD', child: Text('Dolares')),
                  DropdownMenuItem(value: 'PEN', child: Text('Soles')),
                ],
                onChanged: (v) => setState(() => _moneda = v ?? _moneda),
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: _guardar, child: const Text('Guardar')),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    final simbolo = _simbolo.text.trim().toUpperCase();
    final invertido =
        double.tryParse(_invertido.text.replaceAll(',', '.')) ?? 0;
    final valorHoy = double.tryParse(_valorHoy.text.replaceAll(',', '.')) ?? 0;

    if (simbolo.isEmpty || invertido <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falta el codigo o el monto invertido.')),
      );
      return;
    }

    await ref.read(repositorioProvider).posicionInicial(
          simbolo: simbolo,
          nombre: _nombre.text.trim().isEmpty
              ? simbolo
              : _nombre.text.trim(),
          invertido: invertido,
          valorHoy: valorHoy > 0 ? valorHoy : invertido,
          moneda: _moneda,
        );

    ref.read(revisionProvider.notifier).refrescar();
    if (!mounted) return;
    Navigator.pop(context);
  }
}
