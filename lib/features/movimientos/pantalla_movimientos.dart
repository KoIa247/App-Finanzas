import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/fechas.dart';
import '../../core/formato.dart';
import '../../core/tema.dart';
import '../../data/repos/dao.dart';
import '../../domain/enums.dart';
import '../../domain/movimiento.dart';
import '../../providers.dart';
import '../../widgets/async.dart';
import '../../widgets/comunes.dart';
import 'ficha_movimiento.dart';

class PantallaMovimientos extends ConsumerStatefulWidget {
  const PantallaMovimientos({super.key});

  @override
  ConsumerState<PantallaMovimientos> createState() => _Estado();
}

class _Estado extends ConsumerState<PantallaMovimientos> {
  final _busqueda = TextEditingController();
  Timer? _rebote;

  @override
  void dispose() {
    _rebote?.cancel();
    _busqueda.dispose();
    super.dispose();
  }

  /// Se espera a que el usuario deje de escribir antes de consultar: una
  /// consulta por tecla hace parpadear la lista sin necesidad.
  void _buscar(String v) {
    _rebote?.cancel();
    _rebote = Timer(const Duration(milliseconds: 280), () {
      final f = ref.read(filtroProvider);
      ref.read(filtroProvider.notifier).actualizar(f.copyWith(texto: v));
    });
  }

  @override
  Widget build(BuildContext context) {
    final movs = ref.watch(movimientosProvider);
    final filtro = ref.watch(filtroProvider);

    return Column(
      children: [
        _Filtros(
          controlador: _busqueda,
          alBuscar: _buscar,
          filtro: filtro,
        ),
        Expanded(
          child: movs.vista(
            (lista) => _Lista(lista),
            alReintentar: () => ref.invalidate(movimientosProvider),
            altoCarga: 300,
          ),
        ),
      ],
    );
  }
}

class _Filtros extends ConsumerWidget {
  const _Filtros({
    required this.controlador,
    required this.alBuscar,
    required this.filtro,
  });

  final TextEditingController controlador;
  final ValueChanged<String> alBuscar;
  final FiltroMovimientos filtro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final categorias = ref.watch(categoriasProvider).valueOrNull ?? const [];
    final cuentas = ref.watch(cuentasProvider).valueOrNull ?? const [];
    final nombres = {
      for (final c in categorias) c.categoria: c.categoria,
    }.keys.toList();

    final hayFiltros = filtro.categoria.isNotEmpty ||
        filtro.cuentaId.isNotEmpty ||
        filtro.tipo != null ||
        filtro.estado != null;

    return Container(
      color: t.plano,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Column(
        children: [
          TextField(
            controller: controlador,
            onChanged: alBuscar,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar comercio, nota, operacion...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: controlador.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        controlador.clear();
                        alBuscar('');
                      },
                    ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _Filtro(
                  etiqueta: filtro.categoria.isEmpty
                      ? 'Categoria'
                      : filtro.categoria,
                  activo: filtro.categoria.isNotEmpty,
                  opciones: nombres,
                  alElegir: (v) => ref
                      .read(filtroProvider.notifier)
                      .actualizar(filtro.copyWith(categoria: v ?? '')),
                ),
                const SizedBox(width: 8),
                _Filtro(
                  etiqueta: filtro.cuentaId.isEmpty
                      ? 'Cuenta'
                      : (cuentas
                              .where((c) => c.id == filtro.cuentaId)
                              .firstOrNull
                              ?.nombre ??
                          'Cuenta'),
                  activo: filtro.cuentaId.isNotEmpty,
                  opciones: [for (final c in cuentas) c.id],
                  etiquetaDe: (id) =>
                      cuentas.where((c) => c.id == id).firstOrNull?.nombre ?? id,
                  alElegir: (v) => ref
                      .read(filtroProvider.notifier)
                      .actualizar(filtro.copyWith(cuentaId: v ?? '')),
                ),
                const SizedBox(width: 8),
                _Filtro(
                  etiqueta: filtro.tipo?.etiqueta ?? 'Tipo',
                  activo: filtro.tipo != null,
                  opciones: [for (final t in TipoMovimiento.values) t.valor],
                  etiquetaDe: (v) => TipoMovimiento.desde(v).etiqueta,
                  alElegir: (v) => ref.read(filtroProvider.notifier).actualizar(
                        v == null
                            ? filtro.copyWith(limpiarTipo: true)
                            : filtro.copyWith(tipo: TipoMovimiento.desde(v)),
                      ),
                ),
                const SizedBox(width: 8),
                _Filtro(
                  etiqueta: filtro.estado == EstadoMovimiento.revisar
                      ? 'Por revisar'
                      : 'Estado',
                  activo: filtro.estado != null,
                  opciones: const ['OK', 'REVISAR'],
                  etiquetaDe: (v) => v == 'OK' ? 'Sin pendientes' : 'Por revisar',
                  alElegir: (v) => ref.read(filtroProvider.notifier).actualizar(
                        v == null
                            ? filtro.copyWith(limpiarEstado: true)
                            : filtro.copyWith(
                                estado: EstadoMovimiento.desde(v)),
                      ),
                ),
                if (hayFiltros) ...[
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.close, size: 16),
                    label: const Text('Limpiar'),
                    onPressed: () {
                      controlador.clear();
                      ref.read(filtroProvider.notifier).limpiar();
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Filtro extends StatelessWidget {
  const _Filtro({
    required this.etiqueta,
    required this.activo,
    required this.opciones,
    required this.alElegir,
    this.etiquetaDe,
  });

  final String etiqueta;
  final bool activo;
  final List<String> opciones;
  final ValueChanged<String?> alElegir;
  final String Function(String)? etiquetaDe;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return PopupMenuButton<String?>(
      onSelected: alElegir,
      itemBuilder: (_) => [
        const PopupMenuItem<String?>(value: null, child: Text('Todos')),
        for (final o in opciones)
          PopupMenuItem<String?>(
            value: o,
            child: Text(etiquetaDe?.call(o) ?? o),
          ),
      ],
      child: Chip(
        label: Text(
          etiqueta,
          style: TextStyle(color: activo ? Colors.white : t.tinta2),
        ),
        backgroundColor: activo ? marca : t.superficie2,
        side: BorderSide(color: activo ? marca : t.borde),
        deleteIcon: Icon(
          Icons.arrow_drop_down,
          size: 18,
          color: activo ? Colors.white : t.apagado,
        ),
        onDeleted: null,
      ),
    );
  }
}

class _Lista extends ConsumerWidget {
  const _Lista(this.movs);

  final List<Movimiento> movs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;

    if (movs.isEmpty) {
      return const Vacio(
        titulo: 'No hay movimientos con esos filtros',
        detalle: 'Prueba con otro mes o limpia los filtros.',
        icono: Icons.search_off,
      );
    }

    // Se agrupa por dia: una lista plana de 200 filas de montos es ilegible.
    final porDia = <String, List<Movimiento>>{};
    for (final m in movs) {
      porDia.putIfAbsent(m.fecha, () => []).add(m);
    }
    final dias = porDia.keys.toList();

    final total = movs.fold(0.0, (a, m) => a + m.gastoPen);

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: t.superficie2,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Text(
            '${movs.length} movimiento(s) · ${plata(total)} en gastos',
            style: context.texto.bodySmall,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: dias.length,
            itemBuilder: (context, i) {
              final dia = dias[i];
              final delDia = porDia[dia]!;
              final gastoDia = delDia.fold(0.0, (a, m) => a + m.gastoPen);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : 18, bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            fechaCorta(dia),
                            style: context.texto.labelSmall,
                          ),
                        ),
                        if (gastoDia > 0)
                          Text(plata(gastoDia),
                              style: context.texto.labelSmall),
                      ],
                    ),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: Column(
                        children: [
                          for (final m in delDia)
                            FichaMovimiento(m, mostrarFecha: false),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
