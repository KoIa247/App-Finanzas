import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/fechas.dart';
import '../../core/tema.dart';
import '../../providers.dart';
import '../ajustes/pantalla_ajustes.dart';
import '../cuentas/pantalla_cuentas.dart';
import '../dashboard/pantalla_dashboard.dart';
import '../ingresos/pantalla_ingresos.dart';
import '../inversiones/pantalla_inversiones.dart';
import '../movimientos/pantalla_movimientos.dart';
import '../presupuesto/pantalla_presupuesto.dart';
import '../revision/pantalla_revision.dart';
import 'gasto_rapido.dart';

/// Las secciones de la app. El prototipo tiene ocho; en un telefono solo caben
/// cinco en la barra inferior, asi que las tres restantes viven en "Mas".
enum Seccion {
  dashboard('Resumen', Icons.dashboard_outlined, Icons.dashboard),
  movimientos('Movimientos', Icons.receipt_long_outlined, Icons.receipt_long),
  presupuesto('Presupuesto', Icons.pie_chart_outline, Icons.pie_chart),
  ingresos('Ingresos', Icons.savings_outlined, Icons.savings),
  revision('Revisar', Icons.rule_outlined, Icons.rule),
  cuentas('Cuentas', Icons.account_balance_outlined, Icons.account_balance),
  inversiones('Inversiones', Icons.trending_up_outlined, Icons.trending_up),
  ajustes('Ajustes', Icons.settings_outlined, Icons.settings);

  const Seccion(this.titulo, this.icono, this.iconoActivo);

  final String titulo;
  final IconData icono;
  final IconData iconoActivo;

  Widget get pantalla => switch (this) {
        Seccion.dashboard => const PantallaDashboard(),
        Seccion.movimientos => const PantallaMovimientos(),
        Seccion.presupuesto => const PantallaPresupuesto(),
        Seccion.ingresos => const PantallaIngresos(),
        Seccion.revision => const PantallaRevision(),
        Seccion.cuentas => const PantallaCuentas(),
        Seccion.inversiones => const PantallaInversiones(),
        Seccion.ajustes => const PantallaAjustes(),
      };
}

/// Las que van en la barra inferior del telefono.
const List<Seccion> _barra = [
  Seccion.dashboard,
  Seccion.movimientos,
  Seccion.presupuesto,
  Seccion.revision,
];

final seccionProvider =
    NotifierProvider<SeccionNotifier, Seccion>(SeccionNotifier.new);

class SeccionNotifier extends Notifier<Seccion> {
  @override
  Seccion build() => Seccion.dashboard;

  void ir(Seccion s) => state = s;
}

class Caparazon extends ConsumerWidget {
  const Caparazon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seccion = ref.watch(seccionProvider);
    final ancho = MediaQuery.sizeOf(context).width;
    final esAncho = ancho >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(seccion.titulo),
        actions: const [_SelectorPeriodo(), _BotonSync(), SizedBox(width: 8)],
      ),
      drawer: esAncho ? null : const _Menu(),
      body: Row(
        children: [
          if (esAncho) const _Rail(),
          Expanded(
            child: SafeArea(
              top: false,
              child: seccion.pantalla,
            ),
          ),
        ],
      ),
      floatingActionButton: seccion == Seccion.dashboard ||
              seccion == Seccion.movimientos
          ? FloatingActionButton.extended(
              onPressed: () => abrirGastoRapido(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Gasto'),
              backgroundColor: marca,
              foregroundColor: Colors.white,
            )
          : null,
      bottomNavigationBar: esAncho
          ? null
          : NavigationBar(
              selectedIndex:
                  _barra.contains(seccion) ? _barra.indexOf(seccion) : 0,
              onDestinationSelected: (i) =>
                  ref.read(seccionProvider.notifier).ir(_barra[i]),
              destinations: [
                for (final s in _barra)
                  NavigationDestination(
                    icon: Icon(s.icono),
                    selectedIcon: Icon(s.iconoActivo),
                    label: s.titulo,
                  ),
              ],
            ),
    );
  }
}

class _Rail extends ConsumerWidget {
  const _Rail();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seccion = ref.watch(seccionProvider);
    final t = context.tokens;
    return NavigationRail(
      backgroundColor: t.superficie,
      selectedIndex: Seccion.values.indexOf(seccion),
      onDestinationSelected: (i) =>
          ref.read(seccionProvider.notifier).ir(Seccion.values[i]),
      labelType: NavigationRailLabelType.all,
      destinations: [
        for (final s in Seccion.values)
          NavigationRailDestination(
            icon: Icon(s.icono),
            selectedIcon: Icon(s.iconoActivo),
            label: Text(s.titulo),
          ),
      ],
    );
  }
}

class _Menu extends ConsumerWidget {
  const _Menu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seccion = ref.watch(seccionProvider);
    final auth = ref.watch(autenticacionProvider);
    final t = context.tokens;

    return Drawer(
      backgroundColor: t.superficie,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: marca,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Text(
                      'S/',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Finanzas', style: context.texto.titleMedium),
                        Text(
                          auth.conectado ? auth.correo : 'Sin conectar',
                          style: context.texto.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: t.borde),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final s in Seccion.values)
                    ListTile(
                      leading:
                          Icon(s == seccion ? s.iconoActivo : s.icono),
                      title: Text(s.titulo),
                      selected: s == seccion,
                      selectedColor: marca,
                      onTap: () {
                        ref.read(seccionProvider.notifier).ir(s);
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            ),
            Divider(color: t.borde),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                      value: ThemeMode.light, icon: Icon(Icons.light_mode)),
                  ButtonSegment(
                      value: ThemeMode.system, icon: Icon(Icons.brightness_auto)),
                  ButtonSegment(
                      value: ThemeMode.dark, icon: Icon(Icons.dark_mode)),
                ],
                selected: {ref.watch(temaProvider)},
                showSelectedIcon: false,
                onSelectionChanged: (v) =>
                    ref.read(temaProvider.notifier).cambiar(v.first),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Selector de mes. Vive en la barra superior porque casi todas las pantallas
/// dependen de el.
class _SelectorPeriodo extends ConsumerWidget {
  const _SelectorPeriodo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodo = ref.watch(periodoProvider);
    final periodos = ref.watch(periodosProvider).valueOrNull ?? [periodo];

    return PopupMenuButton<String>(
      tooltip: 'Cambiar mes',
      onSelected: (p) => ref.read(periodoProvider.notifier).cambiar(p),
      itemBuilder: (_) => [
        for (final p in periodos)
          PopupMenuItem(value: p, child: Text(periodoLegible(p))),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(periodoCorto(periodo), style: context.texto.titleSmall),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Boton de sincronizar, con su estado.
class _BotonSync extends ConsumerWidget {
  const _BotonSync();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(syncProvider);
    final conectado = ref.watch(sesionProvider).valueOrNull ?? false;

    if (estado is SyncCorriendo) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      );
    }

    return IconButton(
      tooltip: conectado ? 'Sincronizar correos' : 'Conecta tu Gmail',
      icon: Icon(conectado ? Icons.sync : Icons.link_off),
      onPressed: () async {
        if (!conectado) {
          ref.read(seccionProvider.notifier).ir(Seccion.ajustes);
          return;
        }
        await ref.read(syncProvider.notifier).sincronizar();
        if (!context.mounted) return;
        final r = ref.read(syncProvider);
        final mensaje = switch (r) {
          SyncListo(:final resultado) => resultado.registrados > 0
              ? '${resultado.registrados} movimiento(s) nuevos'
              : 'Todo al dia. Nada nuevo que registrar.',
          SyncFallo(:final mensaje) => mensaje,
          _ => '',
        };
        if (mensaje.isEmpty) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            action: r is SyncListo
                ? SnackBarAction(
                    label: 'Detalle',
                    onPressed: () => _verDetalle(context, r.resultado.resumen),
                  )
                : null,
          ),
        );
      },
    );
  }

  void _verDetalle(BuildContext context, String texto) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ultima sincronizacion'),
        content: Text(texto),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
