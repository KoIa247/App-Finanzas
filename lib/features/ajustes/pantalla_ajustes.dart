import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/tema.dart';
import '../../domain/catalogo.dart';
import '../../domain/enums.dart';
import '../../providers.dart';
import '../../widgets/async.dart';
import '../../widgets/comunes.dart';

class PantallaAjustes extends ConsumerWidget {
  const PantallaAjustes({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: const [
        _Cuenta(),
        SizedBox(height: 14),
        _Sincronizacion(),
        SizedBox(height: 14),
        _PoliticaDebito(),
        SizedBox(height: 14),
        _PoliticaTerceros(),
        SizedBox(height: 14),
        _Reglas(),
        SizedBox(height: 14),
        _Remitentes(),
        SizedBox(height: 14),
        _Privacidad(),
      ],
    );
  }
}

/// Conexion con Gmail.
class _Cuenta extends ConsumerWidget {
  const _Cuenta();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionProvider);
    final auth = ref.watch(autenticacionProvider);
    final t = context.tokens;

    return Bloque(
      titulo: 'Tu correo',
      nota: 'La app solo lee los correos de los bancos que autorices. Nada mas '
          'de tu bandeja se toca, y no puede escribir, enviar ni borrar nada.',
      child: sesion.vista(
        (conectado) {
          if (!conectado) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Aviso(
                  tono: TonoAviso.info,
                  texto: 'Conecta tu Gmail para que tus gastos se registren '
                      'solos. Hasta entonces puedes usar la app registrando '
                      'todo a mano.',
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  icon: const Icon(Icons.mail_outline),
                  label: const Text('Conectar con Google'),
                  onPressed: () => ref.read(sesionProvider.notifier).entrar(),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: t.superficie2,
                  backgroundImage: auth.fotoUrl == null
                      ? null
                      : NetworkImage(auth.fotoUrl!),
                  child: auth.fotoUrl == null
                      ? Icon(Icons.person, color: t.apagado)
                      : null,
                ),
                title: Text(auth.nombre.isEmpty ? 'Conectado' : auth.nombre),
                subtitle: Text(auth.correo),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Desconectar tu correo?'),
                      content: const Text(
                        'Se quita el permiso de lectura. Tus movimientos ya '
                        'registrados se quedan en el telefono: no se borra '
                        'nada.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Desconectar'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await ref.read(sesionProvider.notifier).desconectar();
                  }
                },
                child: const Text('Desconectar'),
              ),
            ],
          );
        },
        altoCarga: 120,
      ),
    );
  }
}

class _Sincronizacion extends ConsumerStatefulWidget {
  const _Sincronizacion();

  @override
  ConsumerState<_Sincronizacion> createState() => _EstadoSincronizacion();
}

class _EstadoSincronizacion extends ConsumerState<_Sincronizacion> {
  DateTime _desde = DateTime.now().subtract(const Duration(days: 90));
  DateTime _hasta = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(syncProvider);
    final corriendo = estado is SyncCorriendo;

    return Bloque(
      titulo: 'Sincronizacion',
      nota: 'La sincronizacion normal revisa los ultimos dias. Si acabas de '
          'instalar la app, procesa un rango historico para traer tus meses '
          'anteriores de una vez.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: corriendo ? null : () => _elegir(esDesde: true),
                  child: Text('Desde ${_fmt(_desde)}'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: corriendo ? null : () => _elegir(esDesde: false),
                  child: Text('Hasta ${_fmt(_hasta)}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: corriendo
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.history),
            label: Text(corriendo ? 'Procesando...' : 'Procesar historico'),
            onPressed: corriendo
                ? null
                : () => ref
                    .read(syncProvider.notifier)
                    .historico(_desde, _hasta),
          ),
          if (estado is SyncListo) ...[
            const SizedBox(height: 14),
            Aviso(
              tono: TonoAviso.bueno,
              titulo: 'Ultima corrida',
              texto: estado.resultado.resumen,
            ),
          ],
          if (estado is SyncFallo) ...[
            const SizedBox(height: 14),
            Aviso(
              tono: TonoAviso.critico,
              titulo: 'No se pudo sincronizar',
              texto: estado.mensaje,
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  Future<void> _elegir({required bool esDesde}) async {
    final d = await showDatePicker(
      context: context,
      initialDate: esDesde ? _desde : _hasta,
      firstDate: DateTime(2018),
      lastDate: DateTime.now(),
    );
    if (d == null) return;
    setState(() => esDesde ? _desde = d : _hasta = d);
  }
}

/// De fabrica solo se registran los consumos con tarjeta de credito.
class _PoliticaDebito extends ConsumerWidget {
  const _PoliticaDebito();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configProvider);

    return Bloque(
      titulo: 'Que tarjetas se registran',
      nota: 'De fabrica solo se registran los consumos con tarjeta de credito. '
          'Los correos de la tarjeta de debito se ignoran. Los Plin son la '
          'excepcion que viene puesta: no son una compra con la tarjeta, es '
          'plata que le mandas a una persona.',
      child: config.vista(
        (c) => SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: (c['registrar_debito'] ?? 'NO') == 'SI',
          title: const Text('Registrar tambien la tarjeta de debito'),
          onChanged: (v) async {
            await ref
                .read(daoProvider)
                .guardarConfig('registrar_debito', v ? 'SI' : 'NO');
            ref.read(revisionProvider.notifier).refrescar();
          },
        ),
        altoCarga: 70,
      ),
    );
  }
}

/// Que hacer cuando envias dinero a otra persona.
class _PoliticaTerceros extends ConsumerWidget {
  const _PoliticaTerceros();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configProvider);

    return Bloque(
      titulo: 'Transferencias a otra persona',
      nota: 'Que hacer cuando envias dinero a alguien: tu mama, un amigo, un '
          'proveedor. No aplica a las transferencias entre tus propias '
          'cuentas, que siempre son neutras.',
      child: config.vista(
        (c) {
          final actual =
              PoliticaTerceros.desde(c['transferencias_terceros']);
          return RadioGroup<PoliticaTerceros>(
            groupValue: actual,
            onChanged: (v) async {
              if (v == null) return;
              await ref
                  .read(daoProvider)
                  .guardarConfig('transferencias_terceros', v.valor);
              ref.read(revisionProvider.notifier).refrescar();
            },
            child: Column(
              children: [
                for (final p in PoliticaTerceros.values)
                  RadioListTile<PoliticaTerceros>(
                    contentPadding: EdgeInsets.zero,
                    value: p,
                    title: Text(switch (p) {
                      PoliticaTerceros.ignorar => 'No registrarlas',
                      PoliticaTerceros.neutro =>
                        'Registrar como movimiento interno',
                      PoliticaTerceros.gasto => 'Registrar como gasto',
                    }),
                    subtitle: Text(switch (p) {
                      PoliticaTerceros.ignorar =>
                        'El correo se ignora. Es lo que viene de fabrica.',
                      PoliticaTerceros.neutro =>
                        'Queda anotado pero no cuenta como gasto del mes.',
                      PoliticaTerceros.gasto =>
                        'Cuenta como gasto y pasa por la bandeja de revision.',
                    }),
                  ),
              ],
            ),
          );
        },
        altoCarga: 180,
      ),
    );
  }
}

class _Reglas extends ConsumerWidget {
  const _Reglas();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reglas = ref.watch(reglasProvider);

    return Bloque(
      titulo: 'Reglas de clasificacion',
      nota: 'Se evaluan en orden de prioridad y gana la primera que calza. Las '
          'que dicen "aprendida" salieron de correcciones tuyas.',
      child: reglas.vista(
        (lista) {
          final aprendidas =
              lista.where((r) => r.origen == 'APRENDIDA').toList();
          final usadas = lista.where((r) => r.aciertos > 0).toList()
            ..sort((a, b) => b.aciertos.compareTo(a.aciertos));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${lista.length} reglas · ${aprendidas.length} aprendidas de '
                'tus correcciones',
                style: context.texto.bodyMedium,
              ),
              if (usadas.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text('Las que mas trabajan', style: context.texto.labelSmall),
                const SizedBox(height: 8),
                for (final r in usadas.take(6)) _FilaRegla(r),
              ],
            ],
          );
        },
        altoCarga: 120,
      ),
    );
  }
}

class _FilaRegla extends StatelessWidget {
  const _FilaRegla(this.r);

  final Regla r;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.valor,
                    style: context.texto.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('${r.categoria} / ${r.subcategoria}',
                    style: context.texto.bodySmall),
              ],
            ),
          ),
          Text('${r.aciertos}x', style: context.texto.bodySmall),
        ],
      ),
    );
  }
}

class _Remitentes extends ConsumerWidget {
  const _Remitentes();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remitentes = ref.watch(remitentesProvider);

    return Bloque(
      titulo: 'Remitentes autorizados',
      nota: 'Solo se leen correos de estas direcciones. SOLO BANCOS: no '
          'agregues comercios como Rappi o tiendas. El gasto real es el que '
          'cobra el banco; si entrara tambien la boleta del comercio, la misma '
          'compra se contaria dos veces y tus totales saldrian inflados sin '
          'que nada avise.',
      child: remitentes.vista(
        (lista) => Column(
          children: [
            for (final r in lista)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: r.activo,
                title: Text(r.banco),
                subtitle: Text(r.remitente,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                onChanged: (v) async {
                  await ref
                      .read(daoProvider)
                      .guardarRemitente(r.copyWith(activo: v));
                  ref.read(revisionProvider.notifier).refrescar();
                },
              ),
          ],
        ),
        altoCarga: 200,
      ),
    );
  }
}

class _Privacidad extends ConsumerWidget {
  const _Privacidad();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Bloque(
      titulo: 'Tus datos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Todo lo que ves en esta app vive solo en este telefono, en una '
            'base de datos local. No hay servidor, no hay cuenta que crear y '
            'nada se sube a ningun lado. Los correos se leen directamente '
            'desde Gmail con el permiso que le diste, se procesan aqui mismo '
            'y no se guardan: de cada uno solo queda el movimiento que genero.',
            style: context.texto.bodySmall?.copyWith(height: 1.55),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            icon: const Icon(Icons.delete_forever_outlined, size: 18),
            label: const Text('Borrar todo y empezar de cero'),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Borrar todo?'),
                  content: const Text(
                    'Se borran tus movimientos, presupuestos, cuentas y '
                    'reglas aprendidas. Vuelve todo al estado de fabrica. '
                    'Esto no se puede deshacer.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: context.tokens.critico,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Borrar todo'),
                    ),
                  ],
                ),
              );
              if (ok != true) return;
              await ref.read(baseDatosProvider).reiniciar();
              ref.read(revisionProvider.notifier).refrescar();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Listo, todo de cero.')),
              );
            },
          ),
        ],
      ),
    );
  }
}
