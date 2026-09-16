import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/fechas.dart';
import '../../core/formato.dart';
import '../../core/texto.dart';
import '../../core/tema.dart';
import '../../data/repos/dao.dart';
import '../../domain/enums.dart';
import '../../domain/finanzas.dart';
import '../../providers.dart';
import '../../widgets/async.dart';
import '../../widgets/comunes.dart';
import '../../widgets/graficos.dart';
import '../movimientos/ficha_movimiento.dart';

class PantallaIngresos extends ConsumerWidget {
  const PantallaIngresos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodo = ref.watch(periodoProvider);
    final plantillas = ref.watch(plantillasProvider);

    final distribucion = ref.watch(FutureProvider((ref) {
      ref.watch(revisionProvider);
      return ref.watch(repositorioProvider).distribucionIngresos(periodo);
    }));

    final registrados = ref.watch(FutureProvider((ref) {
      ref.watch(revisionProvider);
      return ref.watch(daoProvider).movimientos(
            FiltroMovimientos(periodo: periodo, tipo: TipoMovimiento.ingreso),
          );
    }));

    return RefreshIndicator(
      onRefresh: () async => ref.read(revisionProvider.notifier).refrescar(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          Bloque(
            titulo: 'Registrar un ingreso',
            nota: 'El banco no notifica el abono del sueldo por correo, asi que '
                'los ingresos los registras tu. Con un toque queda anotado con '
                'la fecha de hoy y el monto de siempre; puedes cambiarlo antes '
                'de guardar.',
            child: plantillas.vista(
              (lista) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in lista)
                    ActionChip(
                      label: Text(p.nombre),
                      onPressed: () => _registrar(context, ref, p),
                    ),
                ],
              ),
              altoCarga: 80,
            ),
          ),
          const SizedBox(height: 14),
          distribucion.vista(
            (d) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RejillaFichas(fichas: [
                  Ficha(
                    etiqueta: 'Ingresos del mes',
                    valor: plata(d.ingresos),
                    color: context.tokens.bueno,
                  ),
                  Ficha(
                    etiqueta: 'Se fue en gastos',
                    valor: plata(d.gastos),
                    sub: porcentaje(d.pctGasto),
                  ),
                  Ficha(
                    etiqueta: 'A inversion',
                    valor: plata(d.inversion),
                    sub: porcentaje(d.pctInversion),
                  ),
                  Ficha(
                    etiqueta: 'Quedo como ahorro',
                    valor: plata(d.ahorro),
                    sub: porcentaje(d.pctAhorro),
                    color: d.ahorro >= 0
                        ? context.tokens.bueno
                        : context.tokens.critico,
                  ),
                ]),
                const SizedBox(height: 14),
                Bloque(
                  titulo: 'En que se convirtio cada sol',
                  child: d.ingresos <= 0
                      ? const Vacio(
                          titulo: 'Sin ingresos este mes',
                          detalle: 'Registra tu sueldo con los botones de '
                              'arriba para ver el reparto.',
                          icono: Icons.savings_outlined,
                        )
                      : BarraApilada(porciones: [
                          Porcion(
                            etiqueta: 'Gastos',
                            valor: d.gastos,
                            color: context.tokens.serie[1],
                          ),
                          Porcion(
                            etiqueta: 'Inversion',
                            valor: d.inversion,
                            color: context.tokens.serie[0],
                          ),
                          Porcion(
                            etiqueta: 'Ahorro',
                            valor: d.ahorro > 0 ? d.ahorro : 0,
                            color: context.tokens.bueno,
                          ),
                        ]),
                ),
              ],
            ),
            altoCarga: 220,
          ),
          const SizedBox(height: 14),
          Bloque(
            titulo: 'Ingresos registrados',
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: registrados.vista(
              (lista) => lista.isEmpty
                  ? const Vacio(
                      titulo: 'Nada registrado este mes',
                      icono: Icons.inbox_outlined,
                    )
                  : Column(
                      children: [
                        for (final m in lista) FichaMovimiento(m),
                      ],
                    ),
              altoCarga: 90,
            ),
          ),
        ],
      ),
    );
  }

  void _registrar(
    BuildContext context,
    WidgetRef ref,
    PlantillaIngreso p,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _FormularioIngreso(p),
    );
  }
}

class _FormularioIngreso extends ConsumerStatefulWidget {
  const _FormularioIngreso(this.plantilla);

  final PlantillaIngreso plantilla;

  @override
  ConsumerState<_FormularioIngreso> createState() => _Estado();
}

class _Estado extends ConsumerState<_FormularioIngreso> {
  late final TextEditingController _monto = TextEditingController(
    text: widget.plantilla.montoSugerido > 0
        ? widget.plantilla.montoSugerido.toStringAsFixed(2)
        : '',
  );
  late String _fecha = hoyLima();
  bool _guardando = false;

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
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
            Text(widget.plantilla.nombre, style: context.texto.titleMedium),
            Text(
              '${widget.plantilla.categoria} / '
              '${widget.plantilla.subcategoria}',
              style: context.texto.bodySmall,
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _monto,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
              ],
              style: context.texto.headlineSmall,
              decoration: InputDecoration(
                prefixText:
                    widget.plantilla.moneda == 'USD' ? r'$ ' : 'S/ ',
                hintText: '0.00',
                labelText: 'Cuanto entro',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today_outlined, size: 17),
              label: Text('Fecha: ${fechaCorta(_fecha)}'),
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.parse(_fecha),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (d == null) return;
                setState(() => _fecha =
                    '${pad(d.year, 4)}-${pad(d.month, 2)}-${pad(d.day, 2)}');
              },
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: const Text('Registrar ingreso'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    final monto = double.tryParse(_monto.text.replaceAll(',', '.')) ?? 0;
    if (monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe cuanto entro.')),
      );
      return;
    }
    setState(() => _guardando = true);

    await ref.read(repositorioProvider).registrarIngreso(
          plantilla: widget.plantilla,
          monto: monto,
          fecha: _fecha,
        );

    ref.read(revisionProvider.notifier).refrescar();
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Registrado: ${plata(monto)}')),
    );
  }
}
