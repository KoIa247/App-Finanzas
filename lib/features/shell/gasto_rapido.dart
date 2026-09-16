import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formato.dart';
import '../../core/tema.dart';
import '../../domain/enums.dart';
import '../../providers.dart';

/// El gasto en efectivo, en dos toques.
///
/// Existe porque es el unico agujero estructural del sistema: el banco notifica
/// todo lo que pasa por tarjeta, pero lo que pagas en efectivo no deja rastro.
/// Si registrarlo cuesta trabajo, no se registra y el mes queda mal.
Future<void> abrirGastoRapido(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _GastoRapido(),
  );
}

class _GastoRapido extends ConsumerStatefulWidget {
  const _GastoRapido();

  @override
  ConsumerState<_GastoRapido> createState() => _Estado();
}

class _Estado extends ConsumerState<_GastoRapido> {
  final _importe = TextEditingController();
  final _comercio = TextEditingController();
  String _categoria = '';
  String _subcategoria = '';
  bool _guardando = false;

  /// Los atajos que cubren casi todo el gasto en efectivo del dia a dia.
  static const _atajos = [
    ('Almuerzo', 'Alimentacion', 'Restaurantes', '🍽'),
    ('Taxi', 'Transporte', 'Taxi / Apps', '🚗'),
    ('Mercado', 'Alimentacion', 'Supermercado', '🛒'),
    ('Cafe', 'Alimentacion', 'Cafeteria', '☕'),
    ('Farmacia', 'Salud', 'Farmacia', '💊'),
    ('Otro', 'Sin clasificar', 'Sin clasificar', '📦'),
  ];

  @override
  void dispose() {
    _importe.dispose();
    _comercio.dispose();
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
              Text('Gasto en efectivo', style: context.texto.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Lo unico que el banco no te avisa por correo.',
                style: context.texto.bodySmall,
              ),
              const SizedBox(height: 18),

              TextField(
                controller: _importe,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
                style: context.texto.displaySmall,
                decoration: const InputDecoration(
                  prefixText: 'S/ ',
                  hintText: '0.00',
                ),
              ),
              const SizedBox(height: 16),

              Text('En que', style: context.texto.labelSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in _atajos)
                    ChoiceChip(
                      avatar: Text(a.$4),
                      label: Text(a.$1),
                      selected: _categoria == a.$2 && _subcategoria == a.$3,
                      showCheckmark: false,
                      selectedColor: marca.withValues(alpha: 0.16),
                      onSelected: (_) => setState(() {
                        _categoria = a.$2;
                        _subcategoria = a.$3;
                        if (_comercio.text.trim().isEmpty) {
                          _comercio.text = a.$1;
                        }
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _comercio,
                decoration: const InputDecoration(
                  labelText: 'Donde',
                  hintText: 'Opcional',
                ),
              ),
              const SizedBox(height: 20),

              FilledButton(
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
                    : const Text('Registrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    final importe = double.tryParse(_importe.text.replaceAll(',', '.')) ?? 0;
    if (importe <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe cuanto gastaste.')),
      );
      return;
    }
    setState(() => _guardando = true);

    final config = ref.read(configProvider).valueOrNull ?? const {};

    await ref.read(repositorioProvider).crearMovimiento(
          tipo: TipoMovimiento.gasto,
          importe: importe,
          comercio: _comercio.text.trim().isEmpty
              ? 'Gasto en efectivo'
              : _comercio.text.trim(),
          categoria: _categoria,
          subcategoria: _subcategoria,
          cuentaId: config['cuenta_efectivo'] ?? 'EFECTIVO',
          medioPago: MedioPago.efectivo,
          descripcion: 'Registrado a mano desde la app',
        );

    ref.read(revisionProvider.notifier).refrescar();
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Anotado: ${plata(importe)}')),
    );
  }
}
