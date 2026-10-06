import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/fechas.dart';
import '../../core/formato.dart';
import '../../core/tema.dart';
import '../../domain/meta.dart';
import '../../providers.dart';
import '../../widgets/async.dart';
import '../../widgets/animaciones.dart';
import '../../widgets/comunes.dart';

/// Metas de ahorro.
///
/// El ahorro ya se calculaba en el Resumen; lo que le faltaba era destino. La
/// regla que las ordena, y que esta escrita al pie de la pantalla: lo que
/// aportas sale de tu ahorro del mes, no de un presupuesto. Si un mes no
/// alcanza, la meta se queda quieta.
class PantallaMetas extends ConsumerWidget {
  const PantallaMetas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final futuro = ref.watch(metasProvider);

    return futuro.vista(
      (metas) => RefreshIndicator(
        onRefresh: () async => ref.read(revisionProvider.notifier).refrescar(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            EntradaPop(child: _Portada(metas)),
            const SizedBox(height: 14),
            for (final a in metas) ...[
              _FichaMeta(a),
              const SizedBox(height: 12),
            ],
            _BotonNueva(hayMetas: metas.isNotEmpty),
            const SizedBox(height: 14),
            const _Nota(),
          ],
        ),
      ),
    );
  }
}

/// Lo guardado en total, arriba de todo.
class _Portada extends ConsumerWidget {
  const _Portada(this.metas);

  final List<AvanceMeta> metas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final tapado = ref.watch(privacidadProvider);
    final moneda = ref.watch(monedaProvider);

    final total = metas.fold(0.0, (a, m) => a + m.ahorrado);
    final delMes = metas.fold(0.0, (a, m) => a + m.aportadoEnPeriodo);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radioTarjeta),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.portada, t.portada.withValues(alpha: 0.86)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'GUARDADO EN TOTAL',
                  style: context.texto.labelSmall
                      ?.copyWith(color: t.portadaTinta.withValues(alpha: 0.75)),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(radioPastilla),
                onTap: () => ref.read(privacidadProvider.notifier).alternar(),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    tapado
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: t.portadaTinta.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              plataQuiza(total, moneda: moneda, tapado: tapado),
              style:
                  context.texto.displaySmall?.copyWith(color: t.portadaTinta),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            metas.isEmpty
                ? 'Todavia no tienes metas. Una meta es ahorro con nombre.'
                : 'En ${metas.length} meta(s) · '
                    '${plataQuiza(delMes, moneda: moneda, tapado: tapado)} '
                    'aportado este mes',
            style: context.texto.bodySmall?.copyWith(
              color: t.portadaTinta.withValues(alpha: 0.86),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

/// Una meta: el anillo, el avance y el boton de aportar.
class _FichaMeta extends ConsumerWidget {
  const _FichaMeta(this.a);

  final AvanceMeta a;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final tapado = ref.watch(privacidadProvider);
    final moneda = ref.watch(monedaProvider);
    final color = Tokens.desdeHex(a.meta.color, respaldo: t.marca);

    String monto(num v) => plataQuiza(v, moneda: moneda, tapado: tapado);

    final plazo = a.cumplida
        ? 'Meta cumplida'
        : [
            a.meta.tieneFecha
                ? 'Para ${periodoCorto(a.meta.fechaLimite.substring(0, 7))}'
                : 'Sin fecha',
            'faltan ${monto(a.falta)}',
          ].join(' · ');

    final sugerido = a.meta.aporteSugerido > 0
        ? a.meta.aporteSugerido
        : (a.porMes ?? 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.superficie,
        borderRadius: BorderRadius.circular(radioTarjeta),
        border: Border.all(color: t.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Anillo(valor: a.porcentaje, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.meta.icono.isEmpty
                          ? a.meta.nombre
                          : '${a.meta.icono}  ${a.meta.nombre}',
                      style: context.texto.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${monto(a.ahorrado)} de ${monto(a.meta.objetivo)}',
                      style: context.texto.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plazo,
                      style: context.texto.bodySmall?.copyWith(
                        color: a.cumplida ? t.bueno : t.apagado,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!a.cumplida && sugerido > 0) ...[
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => _aportar(context, ref, sugerido, moneda),
              child: Text('Aportar ${plata(sugerido, moneda: moneda)}'),
            ),
          ],
          if (!a.cumplida && sugerido <= 0) ...[
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () => _aportarOtro(context, ref, moneda),
              child: const Text('Aportar'),
            ),
          ],
          if (a.aportadoEnPeriodo > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Este mes pusiste ${monto(a.aportadoEnPeriodo)}',
              style: context.texto.bodySmall?.copyWith(color: t.bueno),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _aportar(
    BuildContext context,
    WidgetRef ref,
    double importe,
    String moneda,
  ) async {
    await ref.read(repositorioProvider).aportarAMeta(
          metaId: a.meta.id,
          importe: importe,
          moneda: moneda,
        );
    ref.read(revisionProvider.notifier).refrescar();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Aportaste ${plata(importe, moneda: moneda)} a ${a.meta.nombre}',
        ),
      ),
    );
  }

  Future<void> _aportarOtro(
    BuildContext context,
    WidgetRef ref,
    String moneda,
  ) async {
    final v = await _pedirMonto(context, moneda, 'Aportar a ${a.meta.nombre}');
    if (v == null || v <= 0) return;
    if (!context.mounted) return;
    await _aportar(context, ref, v, moneda);
  }
}

/// El anillo de avance con su porcentaje al centro.
class _Anillo extends StatelessWidget {
  const _Anillo({required this.valor, required this.color});

  final double valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      width: 54,
      height: 54,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (MediaQuery.disableAnimationsOf(context))
            CustomPaint(
              size: const Size(54, 54),
              painter: _PintorAnillo(
                valor: valor,
                color: color,
                fondo: t.superficie2,
              ),
            )
          else
            // El anillo tambien se llena desde cero, como las barras.
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: valor),
              duration: const Duration(milliseconds: 700),
              curve: curvaLeep,
              builder: (context, v, _) => CustomPaint(
                size: const Size(54, 54),
                painter: _PintorAnillo(
                  valor: v,
                  color: color,
                  fondo: t.superficie2,
                ),
              ),
            ),
          Text(
            '${(valor * 100).round()}%',
            style: context.texto.labelSmall?.copyWith(
              color: t.tinta,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PintorAnillo extends CustomPainter {
  _PintorAnillo({
    required this.valor,
    required this.color,
    required this.fondo,
  });

  final double valor;
  final Color color;
  final Color fondo;

  @override
  void paint(Canvas canvas, Size size) {
    const grosor = 5.0;
    final centro = Offset(size.width / 2, size.height / 2);
    final radio = (math.min(size.width, size.height) - grosor) / 2;

    final base = Paint()
      ..color = fondo
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor;
    canvas.drawCircle(centro, radio, base);

    if (valor <= 0) return;
    final arco = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: centro, radius: radio),
      -math.pi / 2,
      2 * math.pi * valor.clamp(0.0, 1.0),
      false,
      arco,
    );
  }

  @override
  bool shouldRepaint(_PintorAnillo v) =>
      v.valor != valor || v.color != color || v.fondo != fondo;
}

/// "+ Nueva meta", con el borde punteado del prototipo.
class _BotonNueva extends ConsumerWidget {
  const _BotonNueva({required this.hayMetas});

  final bool hayMetas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    return OutlinedButton.icon(
      onPressed: () => _crear(context, ref),
      icon: const Icon(Icons.add, size: 19),
      label: Text(hayMetas ? 'Nueva meta' : 'Crear tu primera meta'),
      style: OutlinedButton.styleFrom(
        foregroundColor: t.tinta,
        side: BorderSide(color: t.grilla),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Future<void> _crear(BuildContext context, WidgetRef ref) async {
    final moneda = ref.read(monedaProvider);
    final datos = await showModalBottomSheet<({String nombre, double objetivo})>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _HojaNuevaMeta(moneda: moneda),
    );
    if (datos == null) return;
    await ref.read(repositorioProvider).crearMeta(
          nombre: datos.nombre,
          objetivo: datos.objetivo,
          moneda: moneda,
        );
    ref.read(revisionProvider.notifier).refrescar();
  }
}

/// La hoja de crear meta: nombre y cuanto.
class _HojaNuevaMeta extends StatefulWidget {
  const _HojaNuevaMeta({required this.moneda});

  final String moneda;

  @override
  State<_HojaNuevaMeta> createState() => _EstadoHoja();
}

class _EstadoHoja extends State<_HojaNuevaMeta> {
  final _nombre = TextEditingController();
  final _objetivo = TextEditingController();

  @override
  void dispose() {
    _nombre.dispose();
    _objetivo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final simbolo = widget.moneda == 'USD' ? r'$ ' : 'S/ ';

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
              Text('Nueva meta', style: context.texto.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Ahorro con nombre. Lo que le pongas sale de tu ahorro del '
                'mes, no de un presupuesto.',
                style: context.texto.bodySmall,
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _nombre,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Para que',
                  hintText: 'Viaje, laptop, emergencias...',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _objetivo,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Cuanto quieres juntar',
                  prefixText: simbolo,
                  hintText: '0.00',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  final nombre = _nombre.text.trim();
                  final objetivo =
                      double.tryParse(_objetivo.text.replaceAll(',', '.')) ?? 0;
                  if (nombre.isEmpty || objetivo <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ponle nombre y cuanto quieres juntar.'),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context, (nombre: nombre, objetivo: objetivo));
                },
                child: const Text('Crear meta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// La regla, escrita donde se ve.
class _Nota extends StatelessWidget {
  const _Nota();

  @override
  Widget build(BuildContext context) {
    return const Aviso(
      tono: TonoAviso.info,
      texto: 'Lo que aportas sale de tu ahorro del mes, no de un presupuesto. '
          'Si un mes no alcanza, la meta se queda quieta y no te pintamos un '
          'numero falso.',
    );
  }
}

/// Pide un monto suelto. Devuelve null si el usuario se arrepiente.
Future<double?> _pedirMonto(
  BuildContext context,
  String moneda,
  String titulo,
) =>
    showDialog<double>(
      context: context,
      builder: (_) => _DialogoMonto(moneda: moneda, titulo: titulo),
    );

/// El dialogo es su propio widget para que el controlador viva y muera con el.
///
/// Soltarlo apenas `showDialog` devuelve no sirve: la ruta todavia se esta
/// yendo y el campo sigue escuchando, asi que Flutter revienta con
/// `_dependents.isEmpty is not true`.
class _DialogoMonto extends StatefulWidget {
  const _DialogoMonto({required this.moneda, required this.titulo});

  final String moneda;
  final String titulo;

  @override
  State<_DialogoMonto> createState() => _EstadoDialogoMonto();
}

class _EstadoDialogoMonto extends State<_DialogoMonto> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final simbolo = widget.moneda == 'USD' ? r'$ ' : 'S/ ';
    return AlertDialog(
      title: Text(widget.titulo),
      content: TextField(
        controller: _c,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
        ],
        decoration: InputDecoration(prefixText: simbolo, hintText: '0.00'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            double.tryParse(_c.text.replaceAll(',', '.')) ?? 0,
          ),
          child: const Text('Aportar'),
        ),
      ],
    );
  }
}
