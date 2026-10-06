import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/tema.dart';
import '../../providers.dart';
import '../../widgets/comunes.dart';

/// Accesibilidad.
///
/// Es corta a proposito: casi todo lo que hace falta ya esta puesto y no
/// deberia ser una opcion. Lo unico que se elige aqui es el tamanio, porque
/// eso si cambia de persona a persona.
class PantallaAccesibilidad extends ConsumerWidget {
  const PantallaAccesibilidad({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final escala = ref.watch(escalaProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Text('Tamanio de texto', style: context.texto.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Se multiplica con lo que ya pida tu telefono, no lo reemplaza: si '
          'ya lo tienes en letra grande, no hace falta configurarlo dos veces.',
          style: context.texto.bodySmall,
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
          decoration: BoxDecoration(
            color: t.superficie,
            borderRadius: BorderRadius.circular(radioTarjeta),
            border: Border.all(color: t.borde),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // La muestra usa las mismas cifras tabulares del resto: asi se
              // ve de verdad como va a quedar un monto, no una frase suelta.
              Text('S/ 4,182.50', style: context.texto.headlineSmall),
              const SizedBox(height: 4),
              Text(
                'Cuando corriges la categoria, el sistema crea una regla.',
                style: context.texto.bodyMedium,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('A', style: context.texto.bodySmall),
                  Expanded(
                    child: Slider(
                      value: escala,
                      min: EscalaNotifier.minimo,
                      max: EscalaNotifier.maximo,
                      divisions: 7,
                      label: '${(escala * 100).round()}%',
                      onChanged: (v) =>
                          ref.read(escalaProvider.notifier).cambiar(v),
                    ),
                  ),
                  Text(
                    'A',
                    style: context.texto.titleMedium?.copyWith(fontSize: 22),
                  ),
                ],
              ),
              Center(
                child: TextButton(
                  onPressed: escala == 1
                      ? null
                      : () => ref.read(escalaProvider.notifier).cambiar(1),
                  child: const Text('Volver al tamanio normal'),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),
        Text('Lo que ya viene puesto', style: context.texto.titleMedium),
        const SizedBox(height: 10),

        const _Puesto(
          icono: Icons.motion_photos_off_outlined,
          texto: 'Si tu telefono pide "reducir movimiento", la app le hace '
              'caso sin que toques nada.',
        ),
        const _Puesto(
          icono: Icons.pin_outlined,
          texto: 'Cifras tabulares: una columna de montos nunca queda '
              'torcida, por mucho que cambien los numeros.',
        ),
        const _Puesto(
          icono: Icons.visibility_off_outlined,
          texto: 'El ojo de cada seccion tapa los montos sin cambiar la forma '
              'de la pantalla, para mirarla con gente al lado.',
        ),
        const _Puesto(
          icono: Icons.contrast_outlined,
          texto: 'Los dos temas estan hechos aparte, no invertidos: el '
              'contraste se cuida en cada uno.',
        ),

        const SizedBox(height: 16),
        const Aviso(
          tono: TonoAviso.info,
          texto: 'Si algo se corta o no se lee a un tamanio grande, es un '
              'error de la app y no tuyo.',
        ),
      ],
    );
  }
}

/// Una linea de "esto ya esta hecho".
class _Puesto extends StatelessWidget {
  const _Puesto({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.marca.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icono, size: 17, color: t.marca),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(texto, style: context.texto.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}
