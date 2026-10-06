import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/fechas.dart';
import '../../core/tema.dart';
import '../../providers.dart';
import '../../widgets/async.dart';
import '../../widgets/comunes.dart';

/// De donde salen los datos que la app no inventa.
///
/// La lista es corta y dice la verdad: solo estan las fuentes que la app
/// consulta de verdad hoy. El prototipo dibuja ademas la SBS, el BCRP, la SMV
/// y la BVL, pero nada de eso esta conectado todavia, y una pantalla que
/// promete datos que no llegan es peor que no tenerla.
class PantallaFuentes extends ConsumerWidget {
  const PantallaFuentes({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final futuro = ref.watch(configProvider);

    return futuro.vista((config) {
      final remitentes = ref.watch(remitentesProvider).valueOrNull ?? const [];
      final activos = remitentes.where((r) => r.activo).length;
      final sesion = ref.watch(sesionProvider).valueOrNull ?? false;
      final correo = ref.watch(autenticacionProvider).correo;
      final conectado = sesion && correo.isNotEmpty;

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Text(
            'Lo que la app no calcula sola lo pide afuera. Esto es todo lo '
            'que consulta y para que.',
            style: context.texto.bodyMedium,
          ),
          const SizedBox(height: 18),

          _Fuente(
            sello: 'GOOGLE',
            titulo: 'Correo de tus bancos',
            detalle: 'Permiso de lectura y nada mas: no puede escribir, '
                'enviar ni borrar. Solo mira los remitentes que tengas '
                'activos.',
            alimenta: 'Los movimientos',
            frecuencia: 'Cuando tocas sincronizar',
            origen: 'gmail.googleapis.com',
            estado: conectado ? 'Conectado como $correo' : 'Sin conectar',
            conectada: conectado,
          ),

          _Fuente(
            sello: 'TIPO DE CAMBIO',
            titulo: 'open.er-api.com',
            detalle: 'La primera que se prueba. Gratuita y sin llave.',
            alimenta: 'El equivalente en soles de lo que gastas en dolares',
            frecuencia: 'Una vez al dia, al abrir la app',
            origen: 'open.er-api.com',
            estado: _ultimoTc(config),
            conectada: true,
          ),

          const _Fuente(
            sello: 'RESPALDO',
            titulo: 'frankfurter.app',
            detalle: 'Solo se consulta si la primera no respondio.',
            alimenta: 'Lo mismo, cuando la de arriba falla',
            frecuencia: 'Solo si hace falta',
            origen: 'api.frankfurter.app',
            estado: 'En reserva',
            conectada: true,
          ),

          const SizedBox(height: 6),
          Aviso(
            tono: TonoAviso.info,
            titulo: 'Los remitentes los eliges tu',
            texto: activos == 0
                ? 'Todavia no tienes remitentes activos: sin eso la lectura '
                    'del correo no trae nada.'
                : 'Hay $activos remitente(s) activo(s). Solo se leen correos '
                    'de esos; el resto de tu bandeja no se toca.',
          ),
          const SizedBox(height: 12),
          const Aviso(
            tono: TonoAviso.bueno,
            titulo: 'Nada sale del telefono',
            texto: 'Estas fuentes son de entrada. La app no manda tus '
                'movimientos a ningun lado: no hay servidor al que mandarlos.',
          ),
        ],
      );
    });
  }

  String _ultimoTc(Map<String, String> config) {
    final f = config['tc_ultima_fecha'] ?? '';
    final v = config['tc_ultimo_valor'] ?? '';
    if (f.isEmpty) return 'Sin consultar todavia';
    return v.isEmpty ? 'Ultima: ${fechaCorta(f)}' : 'S/ $v · ${fechaCorta(f)}';
  }
}

/// Una fuente, con lo que alimenta y cada cuanto.
class _Fuente extends StatelessWidget {
  const _Fuente({
    required this.sello,
    required this.titulo,
    required this.detalle,
    required this.alimenta,
    required this.frecuencia,
    required this.origen,
    required this.estado,
    required this.conectada,
  });

  final String sello;
  final String titulo;
  final String detalle;
  final String alimenta;
  final String frecuencia;
  final String origen;
  final String estado;
  final bool conectada;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.superficie,
        borderRadius: BorderRadius.circular(radioTarjeta),
        border: Border.all(color: t.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: conectada ? t.bueno : t.apagado,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(sello, style: context.texto.labelSmall),
            ],
          ),
          const SizedBox(height: 8),
          Text(titulo, style: context.texto.titleMedium),
          const SizedBox(height: 4),
          Text(detalle, style: context.texto.bodySmall),
          const SizedBox(height: 14),
          _Par(etiqueta: 'ALIMENTA', valor: alimenta),
          _Par(etiqueta: 'FRECUENCIA', valor: frecuencia),
          _Par(etiqueta: 'ORIGEN', valor: origen),
          _Par(etiqueta: 'ESTADO', valor: estado),
        ],
      ),
    );
  }
}

class _Par extends StatelessWidget {
  const _Par({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: context.texto.labelSmall),
          const SizedBox(height: 2),
          Text(valor, style: context.texto.bodyMedium),
        ],
      ),
    );
  }
}
