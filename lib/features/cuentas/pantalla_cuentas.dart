import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/fechas.dart';
import '../../core/formato.dart';
import '../../core/tema.dart';
import '../../domain/catalogo.dart';
import '../../domain/enums.dart';
import '../../domain/finanzas.dart';
import '../../providers.dart';
import '../../widgets/async.dart';
import '../../widgets/comunes.dart';

class PantallaCuentas extends ConsumerWidget {
  const PantallaCuentas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuentas = ref.watch(cuentasProvider);
    final historial = ref.watch(patrimonioProvider);
    final dash = ref.watch(dashboardProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.read(revisionProvider.notifier).refrescar(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          Bloque(
            titulo: 'Mi posicion',
            nota: 'Estos numeros los registras tu copiandolos de la app de tu '
                'banco. No se calculan sumando correos: el banco no notifica '
                'el abono del sueldo ni los gastos en efectivo, asi que un '
                'saldo derivado solo de correos siempre estaria mal. Lo que si '
                'es exacto y automatico son tus gastos y categorias.',
            accion: TextButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Actualizar'),
              onPressed: () => _actualizarPosicion(context, ref),
            ),
            child: dash.vista(
              (d) {
                final p = d.posicion;
                if (!p.hayFoto) {
                  return Vacio(
                    titulo: 'Todavia no registraste tu posicion',
                    detalle: 'Abre la app de tu banco, copia tus saldos y '
                        'anotalos aca. Toma un minuto y es lo que hace que el '
                        'patrimonio neto sea real.',
                    icono: Icons.account_balance_outlined,
                    accion: FilledButton(
                      onPressed: () => _actualizarPosicion(context, ref),
                      child: const Text('Registrar'),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RejillaFichas(fichas: [
                      Ficha(etiqueta: 'Liquidez', valor: plata(p.liquidezPen)),
                      Ficha(etiqueta: 'Deuda', valor: plata(p.deudaPen)),
                      Ficha(
                          etiqueta: 'Inversiones',
                          valor: plata(p.inversionesPen)),
                      Ficha(
                        etiqueta: 'Neto',
                        valor: plata(p.neto),
                        color: p.neto >= 0
                            ? context.tokens.bueno
                            : context.tokens.critico,
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Text(
                      'Ultima actualizacion: ${fechaCorta(p.fecha)}'
                      '${p.notas.isEmpty ? '' : ' · ${p.notas}'}',
                      style: context.texto.bodySmall,
                    ),
                  ],
                );
              },
              altoCarga: 180,
            ),
          ),
          const SizedBox(height: 14),
          Bloque(
            titulo: 'Cuentas y tarjetas',
            nota: 'Esta lista existe para una sola cosa: conectar los ultimos '
                '4 digitos que vienen en cada correo con la cuenta correcta. '
                'No guarda saldos.',
            accion: TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nueva'),
              onPressed: () => _editarCuenta(context, ref, null),
            ),
            child: cuentas.vista(
              (lista) => Column(
                children: [
                  for (final c in lista) _FilaCuenta(c),
                ],
              ),
              altoCarga: 120,
            ),
          ),
          const SizedBox(height: 14),
          Bloque(
            titulo: 'Historial de la posicion',
            child: historial.vista(
              (lista) => lista.isEmpty
                  ? const Vacio(
                      titulo: 'Sin historial todavia',
                      detalle: 'Cada vez que actualices tu posicion queda una '
                          'foto aca.',
                      icono: Icons.timeline_outlined,
                    )
                  : Column(
                      children: [
                        for (final f in lista.take(12))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(fechaCorta(f.fecha),
                                      style: context.texto.bodyMedium),
                                ),
                                Text(
                                  plata(f.liquidezPen +
                                      f.liquidezUsd * 3.75 -
                                      f.deudaTarjetaPen),
                                  style: context.texto.titleSmall,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
              altoCarga: 100,
            ),
          ),
        ],
      ),
    );
  }

  void _actualizarPosicion(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _FormularioPosicion(),
    );
  }
}

void _editarCuenta(BuildContext context, WidgetRef ref, Cuenta? c) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _FormularioCuenta(c),
  );
}

class _FilaCuenta extends ConsumerWidget {
  const _FilaCuenta(this.c);

  final Cuenta c;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        c.esTarjetaCredito
            ? Icons.credit_card
            : (c.tipo == 'EFECTIVO'
                ? Icons.payments_outlined
                : Icons.account_balance_outlined),
        color: c.esPropia ? t.apagado : t.serio,
      ),
      title: Text(c.nombre),
      subtitle: Text([
        TipoCuenta.etiqueta(c.tipo),
        if (c.ultimos4.isNotEmpty) '····${c.ultimos4}',
        c.moneda,
        if (!c.esPropia) 'no es mi dinero',
        if (!c.activa) 'inactiva',
      ].join(' · ')),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () => _editarCuenta(context, ref, c),
    );
  }
}

class _FormularioCuenta extends ConsumerStatefulWidget {
  const _FormularioCuenta(this.cuenta);

  final Cuenta? cuenta;

  @override
  ConsumerState<_FormularioCuenta> createState() => _EstadoCuenta();
}

class _EstadoCuenta extends ConsumerState<_FormularioCuenta> {
  late final _id = TextEditingController(text: widget.cuenta?.id ?? '');
  late final _nombre = TextEditingController(text: widget.cuenta?.nombre ?? '');
  late final _banco =
      TextEditingController(text: widget.cuenta?.banco ?? 'BCP');
  late final _u4 = TextEditingController(text: widget.cuenta?.ultimos4 ?? '');
  late final _linea = TextEditingController(
      text: (widget.cuenta?.lineaCredito ?? 0) > 0
          ? widget.cuenta!.lineaCredito.toStringAsFixed(0)
          : '');
  late final _diaPago = TextEditingController(
      text: widget.cuenta?.diaPago?.toString() ?? '');

  late String _tipo = widget.cuenta?.tipo ?? TipoCuenta.tarjetaCredito;
  late String _moneda = widget.cuenta?.moneda ?? 'PEN';
  late bool _activa = widget.cuenta?.activa ?? true;
  late bool _esPropia = widget.cuenta?.esPropia ?? true;

  bool get _esNueva => widget.cuenta == null;

  @override
  void dispose() {
    for (final c in [_id, _nombre, _banco, _u4, _linea, _diaPago]) {
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
                  Text(_esNueva ? 'Nueva cuenta' : 'Editar cuenta',
                      style: context.texto.titleMedium),
                  const SizedBox(height: 18),

                  TextField(
                    controller: _nombre,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      hintText: 'Visa Oro, Cuenta sueldo...',
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_esNueva) ...[
                    TextField(
                      controller: _id,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Identificador',
                        hintText: 'TC_VISA, CTA_SUELDO...',
                        helperText: 'Corto y sin espacios. No se puede cambiar '
                            'despues.',
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  TextField(
                    controller: _u4,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Ultimos 4 digitos',
                      helperText: 'Es lo que conecta cada correo del banco con '
                          'esta cuenta. Copialos tal cual aparecen.',
                    ),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: _tipo,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: [
                      for (final tipo in TipoCuenta.todos)
                        DropdownMenuItem(
                            value: tipo, child: Text(TipoCuenta.etiqueta(tipo))),
                    ],
                    onChanged: (v) => setState(() => _tipo = v ?? _tipo),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _banco,
                          decoration:
                              const InputDecoration(labelText: 'Banco'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _moneda,
                          decoration:
                              const InputDecoration(labelText: 'Moneda'),
                          items: const [
                            DropdownMenuItem(value: 'PEN', child: Text('Soles')),
                            DropdownMenuItem(
                                value: 'USD', child: Text('Dolares')),
                          ],
                          onChanged: (v) =>
                              setState(() => _moneda = v ?? _moneda),
                        ),
                      ),
                    ],
                  ),

                  if (_tipo == TipoCuenta.tarjetaCredito) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _linea,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Linea de credito',
                              prefixText: 'S/ ',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _diaPago,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Dia de pago',
                              hintText: '5',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _activa,
                    onChanged: (v) => setState(() => _activa = v),
                    title: const Text('Activa'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: !_esPropia,
                    onChanged: (v) => setState(() => _esPropia = !v),
                    title: const Text('Este dinero no es mio'),
                    subtitle: const Text(
                      'Para cuentas que operas pero cuyo dinero es de otra '
                      'persona. Sus operaciones no se registran nunca.',
                    ),
                  ),
                  const SizedBox(height: 16),

                  FilledButton(
                    onPressed: _guardar,
                    child: const Text('Guardar'),
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
    final id = _esNueva
        ? _id.text.trim().toUpperCase().replaceAll(' ', '_')
        : widget.cuenta!.id;
    if (id.isEmpty || _nombre.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falta el nombre o el identificador.')),
      );
      return;
    }

    final antesEraPropia = widget.cuenta?.esPropia ?? true;

    await ref.read(daoProvider).guardarCuenta(Cuenta(
          id: id,
          nombre: _nombre.text.trim(),
          banco: _banco.text.trim(),
          tipo: _tipo,
          moneda: _moneda,
          ultimos4: _u4.text.trim(),
          lineaCredito: double.tryParse(_linea.text.replaceAll(',', '.')) ?? 0,
          diaPago: int.tryParse(_diaPago.text.trim()),
          activa: _activa,
          esPropia: _esPropia,
          notas: widget.cuenta?.notas ?? '',
        ));

    // Marcar una cuenta como ajena tambien tiene que sacar de tus totales lo
    // que ya se habia registrado de ella. Si no, el cambio solo valdria para el
    // futuro y el historial seguiria inflado.
    var anulados = 0;
    if (antesEraPropia && !_esPropia) {
      anulados = await ref.read(daoProvider).anularMovimientosDeCuenta(id);
    }

    ref.read(revisionProvider.notifier).refrescar();
    if (!mounted) return;
    Navigator.pop(context);
    if (anulados > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Se quitaron $anulados movimiento(s) de tus totales.'),
        ),
      );
    }
  }
}

class _FormularioPosicion extends ConsumerStatefulWidget {
  const _FormularioPosicion();

  @override
  ConsumerState<_FormularioPosicion> createState() => _EstadoPosicion();
}

class _EstadoPosicion extends ConsumerState<_FormularioPosicion> {
  final _liquidezPen = TextEditingController();
  final _liquidezUsd = TextEditingController();
  final _deudaPen = TextEditingController();
  final _notas = TextEditingController();

  @override
  void dispose() {
    for (final c in [_liquidezPen, _liquidezUsd, _deudaPen, _notas]) {
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
              Text('Actualizar mi posicion',
                  style: context.texto.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Abre la app de tu banco y copia los saldos de hoy.',
                style: context.texto.bodySmall,
              ),
              const SizedBox(height: 18),

              TextField(
                controller: _liquidezPen,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Lo que tengo en soles',
                  prefixText: 'S/ ',
                  helperText: 'Suma de tus cuentas de ahorro y corrientes.',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _liquidezUsd,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Lo que tengo en dolares',
                  prefixText: r'$ ',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _deudaPen,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Lo que debo de tarjetas',
                  prefixText: 'S/ ',
                  helperText: 'Deja en 0 si pagas el total cada mes.',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notas,
                decoration: const InputDecoration(
                  labelText: 'Nota',
                  hintText: 'Opcional',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _guardar,
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _leer(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  Future<void> _guardar() async {
    await ref.read(daoProvider).guardarPatrimonio(FotoPatrimonio(
          fecha: hoyLima(),
          liquidezPen: _leer(_liquidezPen),
          liquidezUsd: _leer(_liquidezUsd),
          deudaTarjetaPen: _leer(_deudaPen),
          notas: _notas.text.trim(),
        ));
    ref.read(revisionProvider.notifier).refrescar();
    if (!mounted) return;
    Navigator.pop(context);
  }
}
