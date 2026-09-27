import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/fechas.dart';
import '../../core/formato.dart';
import '../../core/tema.dart';
import '../../data/repos/vistas.dart';
import '../../domain/finanzas.dart';
import '../../providers.dart';
import '../../widgets/async.dart';
import '../../widgets/comunes.dart';
import '../../widgets/graficos.dart';
import '../movimientos/ficha_movimiento.dart';
import '../shell/caparazon.dart';
import '../shell/registro_manual.dart';

class PantallaDashboard extends ConsumerWidget {
  const PantallaDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final datos = ref.watch(dashboardProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.read(revisionProvider.notifier).refrescar(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          datos.vista(
            (d) => _Contenido(d),
            alReintentar: () => ref.invalidate(dashboardProvider),
            altoCarga: 300,
          ),
        ],
      ),
    );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido(this.d);

  final DatosDashboard d;

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Portada(d),

        const SizedBox(height: 18),
        _EntradasYAhorro(d),

        if (d.pendientes > 0) ...[
          const SizedBox(height: 14),
          Aviso(
            tono: TonoAviso.aviso,
            titulo: '${d.pendientes} movimiento(s) por revisar',
            texto: 'Cuando corriges la categoria, el sistema crea una regla y '
                'la proxima vez lo hace solo.',
            accion: FilledButton.tonal(
              onPressed: () =>
                  ref.read(seccionProvider.notifier).ir(Seccion.revision),
              child: const Text('Revisar ahora'),
            ),
          ),
        ],

        if (d.cobertura.baja) ...[
          const SizedBox(height: 14),
          Aviso(
            tono: TonoAviso.info,
            titulo: 'Este mes casi no tiene correos',
            texto: 'Solo se registraron ${d.cobertura.movimientosPorCorreo} '
                'movimiento(s) por correo en '
                '${d.cobertura.diasConMovimiento} de '
                '${d.cobertura.diasDelPeriodo} dias. Los totales de arriba '
                'estan incompletos: sincroniza o agrega los gastos a mano.',
          ),
        ],

        if (d.ingresos == 0) ...[
          const SizedBox(height: 14),
          Aviso(
            tono: TonoAviso.info,
            titulo: 'Falta registrar tus ingresos',
            texto: 'El banco no notifica el abono del sueldo por correo, asi '
                'que los ingresos los registras tu. Con un toque queda '
                'anotado con el monto de siempre.',
            accion: FilledButton.tonal(
              onPressed: () =>
                  abrirRegistroManual(context, ref, ingreso: true),
              child: const Text('Registrar ingreso'),
            ),
          ),
        ],

        const SizedBox(height: 14),
        _GastosPorCategoria(d),

        const SizedBox(height: 14),
        _ConsumoPorMedio(d),

        const SizedBox(height: 14),
        Bloque(
          titulo: 'Evolucion mensual',
          nota: 'Ultimos 12 meses, en el libro que estas mirando.',
          child: BarrasEvolucion(
            meses: [
              for (final m in d.evolucion)
                BarraMes(
                  etiqueta: mesesCortos[
                      (int.tryParse(m.periodo.substring(5, 7)) ?? 1) - 1],
                  ingresos: m.ingresos,
                  gastos: m.gastos,
                ),
            ],
          ),
        ),

        if (d.suscripciones.isNotEmpty) ...[
          const SizedBox(height: 14),
          _Suscripciones(d),
        ],

        if (d.proximosPagos.isNotEmpty) ...[
          const SizedBox(height: 14),
          _ProximosPagos(d),
        ],

        const SizedBox(height: 14),
        _Ultimos(d),
      ],
    );
  }
}

/// "Entradas y ahorro": lo que entro y lo que se esta quedando.
///
/// Reemplaza a las cuatro fichas sueltas que habia antes. Gastos y
/// presupuesto ya los cuenta la portada, asi que repetirlos aqui solo sumaba
/// ruido: quedan las dos cifras que la portada no dice.
class _EntradasYAhorro extends ConsumerWidget {
  const _EntradasYAhorro(this.d);

  final DatosDashboard d;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final tapado = ref.watch(privacidadProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Entradas y ahorro',
                style: context.texto.titleMedium?.copyWith(fontSize: 18),
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
                  size: 19,
                  color: t.apagado,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: t.superficie,
            borderRadius: BorderRadius.circular(radioTarjeta),
            border: Border.all(color: t.borde),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Cifra(
                    punto: t.bueno,
                    etiqueta: 'ENTRO',
                    valor: plataQuiza(
                      d.ingresos,
                      moneda: d.moneda,
                      tapado: tapado,
                    ),
                    nota: d.ingresos > 0
                        ? 'en el mes'
                        : 'todavia no registras nada',
                    color: d.ingresos > 0 ? t.bueno : null,
                  ),
                ),
                VerticalDivider(width: 1, thickness: 1, color: t.borde),
                Expanded(
                  child: _Cifra(
                    punto: d.ahorro >= 0 ? t.aviso : t.critico,
                    etiqueta: d.ahorro >= 0 ? 'VAS AHORRANDO' : 'VAS EN ROJO',
                    valor: plataQuiza(
                      d.ahorro,
                      moneda: d.moneda,
                      tapado: tapado,
                    ),
                    nota: d.ingresos > 0
                        ? '${porcentaje(d.tasaAhorro)} de lo que entro'
                        : 'registra tus ingresos',
                    color: d.ahorro >= 0 ? null : t.critico,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Una de las dos mitades de "Entradas y ahorro".
class _Cifra extends StatelessWidget {
  const _Cifra({
    required this.punto,
    required this.etiqueta,
    required this.valor,
    required this.nota,
    this.color,
  });

  final Color punto;
  final String etiqueta;
  final String valor;
  final String nota;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: punto, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  etiqueta,
                  style: context.texto.labelSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valor,
              style: context.texto.headlineSmall?.copyWith(color: color),
            ),
          ),
          const SizedBox(height: 4),
          Text(nota, style: context.texto.bodySmall),
        ],
      ),
    );
  }
}

/// La portada del Resumen: lo que te queda por gastar este mes.
///
/// En el repo esta portada mostraba el patrimonio neto. El prototipo lo baja
/// de ahi a proposito: el patrimonio deja de ser portada y manda "te queda
/// este mes". El patrimonio sigue existiendo, pero en Cuentas, que es donde
/// uno lo va a buscar.
class _Portada extends ConsumerWidget {
  const _Portada(this.d);

  final DatosDashboard d;

  /// Cuantos dias quedan del mes, contando hoy.
  ///
  /// Si estas mirando un mes pasado quedan cero, y entonces no tiene sentido
  /// hablar de cuanto puedes gastar al dia.
  int get _diasQueQuedan {
    final hoy = hoyLima();
    if (d.periodo != hoy.substring(0, 7)) return 0;
    final anio = int.tryParse(hoy.substring(0, 4)) ?? 2026;
    final mes = int.tryParse(hoy.substring(5, 7)) ?? 1;
    final dia = int.tryParse(hoy.substring(8, 10)) ?? 1;
    return (diasDelMes(anio, mes) - dia) + 1;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final tapado = ref.watch(privacidadProvider);
    final hayPresupuesto = d.presupuestado > 0;
    final disponible = d.presupuestoDisponible;
    final pasado = hayPresupuesto && disponible < 0;
    final consumo = d.consumoPresupuesto.clamp(0.0, 1.0);

    final planeado = plataQuiza(
      d.presupuestado,
      moneda: d.moneda,
      tapado: tapado,
    );

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
                  hayPresupuesto ? 'DISPONIBLE ESTE MES' : 'GASTADO ESTE MES',
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
              plataQuiza(
                hayPresupuesto ? disponible : d.gastos,
                moneda: d.moneda,
                tapado: tapado,
              ),
              style: context.texto.displaySmall
                  ?.copyWith(color: t.portadaTinta),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hayPresupuesto
                ? (pasado
                    ? 'Te pasaste de los $planeado que planeaste gastar.'
                    : 'de los $planeado que planeaste gastar')
                : 'Ponle un presupuesto al mes y aca te digo cuanto te queda.',
            style: context.texto.bodySmall?.copyWith(
              color: t.portadaTinta.withValues(alpha: 0.86),
              height: 1.45,
            ),
          ),
          if (hayPresupuesto) ...[
            const SizedBox(height: 14),
            _BarraGasto(consumo: consumo, pasado: pasado),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Ya gastaste ${plataQuiza(d.gastos, moneda: d.moneda, tapado: tapado)}',
                    style: context.texto.bodySmall?.copyWith(
                      color: t.portadaTinta.withValues(alpha: 0.72),
                    ),
                  ),
                ),
                Text(
                  porcentaje(d.consumoPresupuesto),
                  style: context.texto.bodySmall?.copyWith(
                    color: t.portadaTinta.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
            if (!pasado && _diasQueQuedan > 0) ...[
              const SizedBox(height: 14),
              _RitmoDiario(
                porDia: disponible / _diasQueQuedan,
                moneda: d.moneda,
                tapado: tapado,
              ),
            ],
          ] else ...[
            const SizedBox(height: 14),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: t.portadaTinta.withValues(alpha: 0.18),
                foregroundColor: t.portadaTinta,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              ),
              onPressed: () =>
                  ref.read(seccionProvider.notifier).ir(Seccion.presupuesto),
              child: const Text('Poner presupuesto'),
            ),
          ],
        ],
      ),
    );
  }
}

/// La barra de consumo del presupuesto, dentro de la portada.
class _BarraGasto extends StatelessWidget {
  const _BarraGasto({required this.consumo, required this.pasado});

  final double consumo;
  final bool pasado;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radioPastilla),
      child: LinearProgressIndicator(
        value: consumo,
        minHeight: 8,
        backgroundColor: t.portadaTinta.withValues(alpha: 0.18),
        valueColor: AlwaysStoppedAnimation(
          pasado ? t.critico : t.portadaTinta.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}

/// "Para no pasarte, puedes gastar al dia X".
///
/// Es la cuenta que uno hace de cabeza a mitad de mes, hecha por la app.
class _RitmoDiario extends StatelessWidget {
  const _RitmoDiario({
    required this.porDia,
    required this.moneda,
    required this.tapado,
  });

  final double porDia;
  final String moneda;
  final bool tapado;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: t.portadaTinta.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radioCampo),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.portadaTinta.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(radioPastilla),
            ),
            child: Icon(
              Icons.event_outlined,
              size: 17,
              color: t.portadaTinta.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Para no pasarte, puedes gastar al dia',
              style: context.texto.bodySmall?.copyWith(
                color: t.portadaTinta.withValues(alpha: 0.86),
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            plataQuiza(porDia, moneda: moneda, tapado: tapado),
            style: context.texto.titleMedium?.copyWith(color: t.portadaTinta),
          ),
        ],
      ),
    );
  }
}

class _GastosPorCategoria extends ConsumerWidget {
  const _GastosPorCategoria(this.d);

  final DatosDashboard d;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (d.porCategoria.isEmpty) {
      return const Bloque(
        titulo: 'Gastos por categoria',
        child: Vacio(
          titulo: 'Todavia no hay gastos este mes',
          detalle: 'Sincroniza tus correos o registra un gasto en efectivo.',
          icono: Icons.pie_chart_outline,
        ),
      );
    }

    final porciones = [
      for (final c in d.porCategoria)
        Porcion(
          etiqueta: c.categoria,
          valor: c.monto,
          color: Tokens.desdeHex(c.color),
        ),
    ];

    return Bloque(
      titulo: 'Gastos por categoria',
      accion: TextButton(
        onPressed: () =>
            ref.read(seccionProvider.notifier).ir(Seccion.movimientos),
        child: const Text('Ver todos'),
      ),
      child: LayoutBuilder(
        builder: (context, cons) {
          final dona = Dona(porciones: porciones, etiquetaCentro: 'Gastos');
          final leyenda = LeyendaDona(porciones: porciones);
          // En pantalla ancha la dona y su leyenda van lado a lado; en telefono
          // una encima de la otra, porque la leyenda necesita el ancho completo
          // para que los montos no se corten.
          if (cons.maxWidth >= 560) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                dona,
                const SizedBox(width: 24),
                Expanded(child: leyenda),
              ],
            );
          }
          return Column(
            children: [
              Center(child: dona),
              const SizedBox(height: 18),
              leyenda,
            ],
          );
        },
      ),
    );
  }
}

class _ConsumoPorMedio extends ConsumerWidget {
  const _ConsumoPorMedio(this.d);

  final DatosDashboard d;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    if (d.porMedio.isEmpty) return const SizedBox.shrink();

    return Bloque(
      titulo: 'Consumo por tarjeta y cuenta',
      nota: 'Cuanto gastaste con cada medio este mes. Los pagos de tarjeta y '
          'las transferencias entre tus cuentas no cuentan aca porque no son '
          'consumo.',
      child: Column(
        children: [
          for (final m in d.porMedio)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        m.esTarjetaCredito
                            ? Icons.credit_card
                            : Icons.account_balance_wallet_outlined,
                        size: 18,
                        color: t.apagado,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          m.ultimos4.isEmpty
                              ? m.nombre
                              : '${m.nombre} ····${m.ultimos4}',
                          style: context.texto.bodyMedium
                              ?.copyWith(color: t.tinta),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(plata(m.monto, moneda: d.moneda), style: context.texto.titleSmall),
                    ],
                  ),
                  if (m.lineaCredito > 0) ...[
                    const SizedBox(height: 8),
                    BarraAvance(
                      valor: m.usoLinea,
                      color: m.usoLinea > 0.8 ? t.serio : t.serie[0],
                      alto: 6,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${porcentaje(m.usoLinea)} de tu linea de '
                      '${plataCorta(m.lineaCredito, moneda: d.moneda)}',
                      style: context.texto.bodySmall,
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    Text('${m.movimientos} movimiento(s)',
                        style: context.texto.bodySmall),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Suscripciones extends StatelessWidget {
  const _Suscripciones(this.d);

  final DatosDashboard d;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final activas = d.suscripciones.where((s) => s.activa).toList();
    final bajas = d.suscripciones.where((s) => !s.activa).toList();

    return Bloque(
      titulo: 'Suscripciones detectadas',
      nota: 'Cargos que se repiten cada mes con el mismo monto y cerca del '
          'mismo dia.',
      pie: Row(
        children: [
          Expanded(
            child: Text(
              'Te cuestan al anio',
              style: context.texto.bodySmall,
            ),
          ),
          Text(
            plata(d.costoAnualSuscripciones, moneda: d.moneda),
            style: context.texto.titleMedium,
          ),
        ],
      ),
      child: Column(
        children: [
          for (final s in activas.take(8)) _FilaSuscripcion(s, moneda: d.moneda),
          if (bajas.isNotEmpty) ...[
            Divider(height: 24, color: t.borde),
            Text(
              'Sin cobrar hace mas de 45 dias',
              style: context.texto.labelSmall,
            ),
            const SizedBox(height: 8),
            for (final s in bajas.take(4)) _FilaSuscripcion(s, moneda: d.moneda, apagada: true),
          ],
        ],
      ),
    );
  }
}

class _FilaSuscripcion extends StatelessWidget {
  const _FilaSuscripcion(this.s, {required this.moneda, this.apagada = false});

  final Suscripcion s;
  final String moneda;
  final bool apagada;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.comercio,
                  style: context.texto.bodyMedium?.copyWith(
                    color: apagada ? t.apagado : t.tinta,
                    decoration: apagada ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  apagada
                      ? 'Ultimo cargo hace ${s.diasSinCobrar} dias'
                      : 'Cada mes cerca del ${s.diaAproximado} · '
                          '${s.cargos} cargo(s)',
                  style: context.texto.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(plata(s.importePromedio, moneda: moneda),
                  style: context.texto.titleSmall),
              if (s.monedaOriginal != 'PEN')
                Text(
                  plata(s.importeOriginal, moneda: s.monedaOriginal),
                  style: context.texto.bodySmall,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProximosPagos extends StatelessWidget {
  const _ProximosPagos(this.d);

  final DatosDashboard d;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Bloque(
      titulo: 'Proximos pagos',
      child: Column(
        children: [
          for (final p in d.proximosPagos)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Icon(Icons.event_outlined,
                      size: 18,
                      color: p.urgente ? t.serio : t.apagado),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.nombre, style: context.texto.bodyMedium),
                        Text(
                          p.diasRestantes == 0
                              ? 'Se paga hoy'
                              : 'En ${p.diasRestantes} dia(s) · '
                                  'dia ${p.diaPago} de cada mes',
                          style: context.texto.bodySmall?.copyWith(
                            color: p.urgente ? t.serio : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(plata(p.consumoDelMes, moneda: d.moneda),
                      style: context.texto.titleSmall),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Ultimos extends ConsumerWidget {
  const _Ultimos(this.d);

  final DatosDashboard d;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Bloque(
      titulo: 'Ultimos movimientos',
      accion: TextButton(
        onPressed: () =>
            ref.read(seccionProvider.notifier).ir(Seccion.movimientos),
        child: const Text('Ver todos'),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: d.ultimos.isEmpty
          ? const Vacio(
              titulo: 'Nada por aqui todavia',
              detalle: 'Sincroniza tus correos para que aparezcan solos.',
              icono: Icons.receipt_long_outlined,
            )
          : Column(
              children: [
                for (final m in d.ultimos) FichaMovimiento(m),
              ],
            ),
    );
  }
}
