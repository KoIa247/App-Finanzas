import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/fechas.dart';
import '../../core/tema.dart';
import '../../providers.dart';
import '../../widgets/marca.dart';

/// La clave de `config` que recuerda que ya pasaste por aqui.
const String claveOnboarding = 'onboarding_hecho';

/// La primera vez que se abre la app.
///
/// Tres pasos y ninguno obligatorio: se puede salir por abajo y registrar
/// todo a mano. Es a proposito, porque conectar el correo es la parte que mas
/// desconfianza da y obligar a hacerlo de entrada es la mejor forma de que
/// alguien desinstale la app antes de verla.
class PantallaOnboarding extends ConsumerStatefulWidget {
  const PantallaOnboarding({super.key, required this.alTerminar});

  final VoidCallback alTerminar;

  @override
  ConsumerState<PantallaOnboarding> createState() => _Estado();
}

class _Estado extends ConsumerState<PantallaOnboarding> {
  bool _armando = false;
  int? _lineasArmadas;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final moneda = ref.watch(monedaProvider);
    final sesion = ref.watch(sesionProvider).valueOrNull ?? false;
    final correo = ref.watch(autenticacionProvider).correo;
    final conectado = sesion && correo.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 32),
          children: [
            const MarcaLeep(tamanio: 56),
            const SizedBox(height: 16),
            Text(
              'Finanzas personales · Peru',
              style: context.texto.labelSmall?.copyWith(color: t.marca),
            ),
            const SizedBox(height: 12),
            Text(
              'Tu plata,\nanotada sola.',
              style: context.texto.displaySmall?.copyWith(height: 1.05),
            ),
            const SizedBox(height: 12),
            Text(
              'Leemos los avisos que tu banco ya te manda y los convertimos '
              'en movimientos clasificados. Nada sale del telefono.',
              style: context.texto.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 26),

            _Paso(
              numero: 1,
              titulo: 'Tus dos monedas',
              nota: 'Cada moneda lleva su propia cuenta: sus movimientos, su '
                  'presupuesto y sus metas. Nada se convierte para sumarse.',
              hijo: Row(
                children: [
                  _Eleccion(
                    etiqueta: 'Soles',
                    activo: moneda == 'PEN',
                    alTocar: () =>
                        ref.read(monedaProvider.notifier).cambiar('PEN'),
                  ),
                  const SizedBox(width: 10),
                  _Eleccion(
                    etiqueta: 'Dolares',
                    activo: moneda == 'USD',
                    alTocar: () =>
                        ref.read(monedaProvider.notifier).cambiar('USD'),
                  ),
                ],
              ),
            ),

            _Paso(
              numero: 2,
              titulo: 'Conecta tu correo',
              nota: 'Permiso de lectura y nada mas. Solo mira los remitentes '
                  'de banco que actives, y ningun otro correo tuyo.',
              hijo: conectado
                  ? Row(
                      children: [
                        Icon(Icons.check_circle, size: 19, color: t.bueno),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Conectado como $correo',
                            style: context.texto.bodySmall
                                ?.copyWith(color: t.bueno),
                          ),
                        ),
                      ],
                    )
                  : FilledButton.icon(
                      onPressed: _conectar,
                      icon: const Icon(Icons.mail_outline, size: 19),
                      label: const Text('Continuar con Google'),
                    ),
            ),

            _Paso(
              numero: 3,
              titulo: 'Tu primer presupuesto',
              nota: _lineasArmadas == null
                  ? 'Lo armamos con tus ultimos tres meses. Si todavia no hay '
                      'historial, lo pones tu cuando quieras.'
                  : _lineasArmadas == 0
                      ? 'Todavia no hay historial para calcularlo. Lo pones a '
                          'mano desde Presupuesto cuando quieras.'
                      : 'Listo: $_lineasArmadas categoria(s) con limite '
                          'sacado de lo que ya gastas.',
              hijo: _lineasArmadas != null && _lineasArmadas! > 0
                  ? null
                  : OutlinedButton(
                      onPressed: _armando ? null : _armarPresupuesto,
                      child: _armando
                          ? const RanaCargando(tamanio: 17)
                          : const Text('Armarlo con mi historial'),
                    ),
            ),

            const SizedBox(height: 14),
            Center(
              child: TextButton(
                onPressed: _terminar,
                child: Text(
                  conectado ? 'Entrar a la app' : 'Prefiero registrar todo a mano',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _conectar() async {
    await ref.read(sesionProvider.notifier).entrar();
    ref.read(revisionProvider.notifier).refrescar();
  }

  Future<void> _armarPresupuesto() async {
    setState(() => _armando = true);
    final n = await ref.read(repositorioProvider).presupuestoDesdeHistorial(
          periodo: ref.read(periodoProvider),
          moneda: ref.read(monedaProvider),
        );
    ref.read(revisionProvider.notifier).refrescar();
    if (!mounted) return;
    setState(() {
      _armando = false;
      _lineasArmadas = n;
    });
  }

  Future<void> _terminar() async {
    await ref.read(daoProvider).guardarConfig(claveOnboarding, hoyLima());
    ref.read(revisionProvider.notifier).refrescar();
    widget.alTerminar();
  }
}

/// Un paso numerado.
class _Paso extends StatelessWidget {
  const _Paso({
    required this.numero,
    required this.titulo,
    required this.nota,
    this.hijo,
  });

  final int numero;
  final String titulo;
  final String nota;
  final Widget? hijo;

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.marca.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$numero',
                  style: context.texto.labelSmall?.copyWith(color: t.marca),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(titulo, style: context.texto.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(nota, style: context.texto.bodySmall?.copyWith(height: 1.45)),
          if (hijo != null) ...[
            const SizedBox(height: 14),
            hijo!,
          ],
        ],
      ),
    );
  }
}

/// Una de las dos monedas.
class _Eleccion extends StatelessWidget {
  const _Eleccion({
    required this.etiqueta,
    required this.activo,
    required this.alTocar,
  });

  final String etiqueta;
  final bool activo;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(radioPastilla),
        onTap: alTocar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: activo ? t.marca : Colors.transparent,
            borderRadius: BorderRadius.circular(radioPastilla),
            border: Border.all(color: activo ? t.marca : t.grilla),
          ),
          child: Text(
            etiqueta,
            style: context.texto.titleSmall?.copyWith(
              color: activo ? t.marcaTinta : t.tinta,
            ),
          ),
        ),
      ),
    );
  }
}
