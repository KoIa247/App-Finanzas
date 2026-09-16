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
    final t = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Portada(d),
        const SizedBox(height: 14),

        RejillaFichas(fichas: [
          Ficha(
            etiqueta: 'Ingresos',
            valor: plata(d.ingresos),
            sub: 'del mes',
            color: d.ingresos > 0 ? t.bueno : null,
          ),
          Ficha(
            etiqueta: 'Gastos',
            valor: plata(d.gastos),
            sub: '${d.porCategoria.length} categoria(s)',
          ),
          Ficha(
            etiqueta: 'Ahorro',
            valor: plata(d.ahorro),
            sub: d.ingresos > 0
                ? '${porcentaje(d.tasaAhorro)} de lo que entro'
                : 'registra tus ingresos',
            color: d.ahorro >= 0 ? t.bueno : t.critico,
          ),
          Ficha(
            etiqueta: 'Presupuesto',
            valor: d.presupuestado > 0
                ? plata(d.presupuestoDisponible)
                : '—',
            sub: d.presupuestado > 0
                ? '${porcentaje(d.consumoPresupuesto)} consumido'
                : 'sin definir',
            color: d.presupuestado > 0 && d.presupuestoDisponible < 0
                ? t.critico
                : null,
            alPresionar: () =>
                ref.read(seccionProvider.notifier).ir(Seccion.presupuesto),
          ),
        ]),

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
                  ref.read(seccionProvider.notifier).ir(Seccion.ingresos),
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
          nota: 'Ultimos 12 meses, en soles.',
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

/// El patrimonio neto, arriba de todo.
class _Portada extends ConsumerWidget {
  const _Portada(this.d);

  final DatosDashboard d;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // El fondo de la portada es un degradado fijo, asi que los textos van en
    // blanco directo y no en tokens de tema.
    final p = d.posicion;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [marca, marca.withValues(alpha: 0.78)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PATRIMONIO NETO',
            style: context.texto.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              p.hayFoto ? plata(p.neto) : 'Sin registrar',
              style: context.texto.displaySmall?.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            p.hayFoto
                ? 'Al ${fechaCorta(p.fecha)} · '
                    'liquidez ${plataCorta(p.liquidezPen)}'
                    '${p.deudaPen > 0 ? ' · deuda ${plataCorta(p.deudaPen)}' : ''}'
                    '${p.inversionesPen > 0 ? ' · inversiones ${plataCorta(p.inversionesPen)}' : ''}'
                : 'Copia tus saldos de la app del banco para verlo aqui.',
            style: context.texto.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () =>
                    ref.read(seccionProvider.notifier).ir(Seccion.cuentas),
                child: Text(p.hayFoto ? 'Actualizar' : 'Registrar posicion'),
              ),
              const Spacer(),
              if (p.tipoCambio > 0)
                Text(
                  'USD ${p.tipoCambio.toStringAsFixed(3)}',
                  style: context.texto.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
            ],
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
                      Text(plata(m.monto), style: context.texto.titleSmall),
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
                      '${plataCorta(m.lineaCredito)}',
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
            plata(d.costoAnualSuscripciones),
            style: context.texto.titleMedium,
          ),
        ],
      ),
      child: Column(
        children: [
          for (final s in activas.take(8)) _FilaSuscripcion(s),
          if (bajas.isNotEmpty) ...[
            Divider(height: 24, color: t.borde),
            Text(
              'Sin cobrar hace mas de 45 dias',
              style: context.texto.labelSmall,
            ),
            const SizedBox(height: 8),
            for (final s in bajas.take(4)) _FilaSuscripcion(s, apagada: true),
          ],
        ],
      ),
    );
  }
}

class _FilaSuscripcion extends StatelessWidget {
  const _FilaSuscripcion(this.s, {this.apagada = false});

  final Suscripcion s;
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
              Text(plata(s.importePromedio),
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
                  Text(plata(p.consumoDelMes),
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
