import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formato.dart';
import '../../core/tema.dart';
import '../../domain/enums.dart';
import '../../providers.dart';

/// El registro manual: lo que el correo del banco no trae.
///
/// Son dos agujeros, no uno. El gasto en efectivo no deja rastro en ningun
/// correo, y el abono del sueldo tampoco se notifica. Por eso la hoja tiene
/// las dos caras y no solo la del gasto: el prototipo la llama "Registro
/// manual" justamente porque cubre las dos.
Future<void> abrirRegistroManual(
  BuildContext context,
  WidgetRef ref, {
  bool ingreso = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _RegistroManual(ingreso: ingreso),
  );
}

class _RegistroManual extends ConsumerStatefulWidget {
  const _RegistroManual({required this.ingreso});

  final bool ingreso;

  @override
  ConsumerState<_RegistroManual> createState() => _Estado();
}

/// Un atajo de la hoja: etiqueta, categoria, subcategoria e icono.
typedef _Atajo = ({String label, String cat, String sub, String icono});

class _Estado extends ConsumerState<_RegistroManual> {
  final _importe = TextEditingController();
  final _comercio = TextEditingController();
  String _categoria = '';
  String _subcategoria = '';
  bool _guardando = false;
  late bool _esIngreso = widget.ingreso;

  /// Los atajos que cubren casi todo el gasto en efectivo del dia a dia.
  static const List<_Atajo> _gastos = [
    (label: 'Almuerzo', cat: 'Alimentacion', sub: 'Restaurantes', icono: '🍽'),
    (label: 'Taxi', cat: 'Transporte', sub: 'Taxi / Apps', icono: '🚗'),
    (label: 'Mercado', cat: 'Alimentacion', sub: 'Supermercado', icono: '🛒'),
    (label: 'Cafe', cat: 'Alimentacion', sub: 'Cafeteria', icono: '☕'),
    (label: 'Farmacia', cat: 'Salud', sub: 'Farmacia', icono: '💊'),
    (label: 'Otro', cat: 'Sin clasificar', sub: 'Sin clasificar', icono: '📦'),
  ];

  /// Los del regimen peruano, que son los que de verdad se repiten.
  static const List<_Atajo> _ingresos = [
    (label: 'Sueldo', cat: 'Ingresos', sub: 'Sueldo', icono: '💵'),
    (label: 'Quincena', cat: 'Ingresos', sub: 'Quincena', icono: '💵'),
    (label: 'Gratificacion', cat: 'Ingresos', sub: 'Gratificacion', icono: '🎁'),
    (label: 'CTS', cat: 'Ingresos', sub: 'CTS', icono: '🏦'),
    (label: 'Dividendos', cat: 'Ingresos', sub: 'Dividendos', icono: '📈'),
    (label: 'Intereses', cat: 'Ingresos', sub: 'Intereses', icono: '🏦'),
    (label: 'Alquiler', cat: 'Ingresos', sub: 'Alquiler cobrado', icono: '🏠'),
    (
      label: 'Freelance',
      cat: 'Ingresos',
      sub: 'Trabajo independiente',
      icono: '💼'
    ),
    (label: 'Reembolso', cat: 'Ingresos', sub: 'Reembolsos', icono: '↩'),
    (label: 'Otro', cat: 'Ingresos', sub: 'Otros', icono: '➕'),
  ];

  List<_Atajo> get _atajos => _esIngreso ? _ingresos : _gastos;

  @override
  void dispose() {
    _importe.dispose();
    _comercio.dispose();
    super.dispose();
  }

  void _cambiarCara(bool ingreso) {
    if (_esIngreso == ingreso) return;
    setState(() {
      _esIngreso = ingreso;
      // Los atajos de una cara no valen en la otra.
      _categoria = '';
      _subcategoria = '';
      _comercio.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final moneda = ref.watch(monedaProvider);
    final simbolo = moneda == 'USD' ? r'$ ' : 'S/ ';

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
              Text('Registro manual', style: context.texto.titleMedium),
              const SizedBox(height: 4),
              Text(
                _esIngreso
                    ? 'El banco no avisa cuando te cae el sueldo.'
                    : 'Lo unico que el banco no te avisa por correo.',
                style: context.texto.bodySmall,
              ),
              const SizedBox(height: 16),

              _CaraSelector(
                esIngreso: _esIngreso,
                alCambiar: _cambiarCara,
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _importe,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
                style: context.texto.displaySmall,
                decoration: InputDecoration(
                  prefixText: simbolo,
                  hintText: '0.00',
                ),
              ),
              const SizedBox(height: 16),

              Text(_esIngreso ? 'De donde' : 'En que',
                  style: context.texto.labelSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in _atajos)
                    ChoiceChip(
                      avatar: Text(a.icono),
                      label: Text(a.label),
                      selected: _categoria == a.cat && _subcategoria == a.sub,
                      showCheckmark: false,
                      selectedColor: t.marca.withValues(alpha: 0.16),
                      onSelected: (_) => setState(() {
                        _categoria = a.cat;
                        _subcategoria = a.sub;
                        if (_comercio.text.trim().isEmpty) {
                          _comercio.text = a.label;
                        }
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _comercio,
                decoration: InputDecoration(
                  labelText: _esIngreso ? 'Concepto' : 'Donde',
                  hintText: 'Opcional',
                ),
              ),
              const SizedBox(height: 20),

              FilledButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: t.marcaTinta,
                        ),
                      )
                    : Text(_esIngreso ? 'Anotar ingreso' : 'Registrar'),
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
        SnackBar(
          content: Text(
            _esIngreso ? 'Escribe cuanto entro.' : 'Escribe cuanto gastaste.',
          ),
        ),
      );
      return;
    }
    setState(() => _guardando = true);

    final config = ref.read(configProvider).valueOrNull ?? const {};
    final moneda = ref.read(monedaProvider);

    await ref.read(repositorioProvider).crearMovimiento(
          tipo: _esIngreso ? TipoMovimiento.ingreso : TipoMovimiento.gasto,
          importe: importe,
          moneda: moneda,
          comercio: _comercio.text.trim().isEmpty
              ? (_esIngreso ? 'Ingreso' : 'Gasto en efectivo')
              : _comercio.text.trim(),
          categoria: _categoria,
          subcategoria: _subcategoria,
          cuentaId: _esIngreso ? '' : (config['cuenta_efectivo'] ?? 'EFECTIVO'),
          medioPago: _esIngreso ? '' : MedioPago.efectivo,
          descripcion: 'Registrado a mano desde la app',
        );

    ref.read(revisionProvider.notifier).refrescar();
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_esIngreso ? 'Anotado' : 'Anotado'}: '
          '${plata(importe, moneda: moneda)}',
        ),
      ),
    );
  }
}

/// Gasto o ingreso. Segmentado, como el de la moneda.
class _CaraSelector extends StatelessWidget {
  const _CaraSelector({required this.esIngreso, required this.alCambiar});

  final bool esIngreso;
  final ValueChanged<bool> alCambiar;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    Widget gajo(String etiqueta, bool ingreso) {
      final activo = esIngreso == ingreso;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(radioPastilla),
          onTap: () => alCambiar(ingreso),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: activo ? t.marca : Colors.transparent,
              borderRadius: BorderRadius.circular(radioPastilla),
            ),
            child: Text(
              etiqueta,
              style: context.texto.titleSmall?.copyWith(
                color: activo ? t.marcaTinta : t.apagado,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.superficie2,
        borderRadius: BorderRadius.circular(radioPastilla),
      ),
      child: Row(children: [gajo('Gasto', false), gajo('Ingreso', true)]),
    );
  }
}
