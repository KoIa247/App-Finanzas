import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/tema.dart';
import '../../providers.dart';
import '../../widgets/async.dart';
import '../../widgets/comunes.dart';
import '../../widgets/marca.dart';

/// Perfil.
///
/// Nada de esto es obligatorio y la app funciona entera sin tocarlo. Sirve
/// para que el presupuesto deje de ser una plantilla: no es lo mismo lo que
/// le sobra a alguien que vive solo que a alguien con dos personas a cargo.
///
/// Todo va a `config`, que es clave y valor: no hace falta una tabla para
/// guardar ocho respuestas que nadie consulta por separado.
class PantallaPerfil extends ConsumerWidget {
  const PantallaPerfil({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final futuro = ref.watch(configProvider);
    return futuro.vista((config) => _Formulario(config));
  }
}

/// Las claves de `config` que usa esta pantalla.
class _K {
  static const nombre = 'perfil_nombre';
  static const ciudad = 'perfil_ciudad';
  static const ocupacion = 'perfil_ocupacion';
  static const ingreso = 'perfil_ingreso';
  static const tipoIngreso = 'perfil_tipo_ingreso';
  static const diaPago = 'perfil_dia_pago';
  static const hogar = 'perfil_hogar';
  static const dependientes = 'perfil_dependientes';
}

class _Formulario extends ConsumerStatefulWidget {
  const _Formulario(this.config);

  final Map<String, String> config;

  @override
  ConsumerState<_Formulario> createState() => _EstadoFormulario();
}

class _EstadoFormulario extends ConsumerState<_Formulario> {
  late final _nombre = TextEditingController(text: _v(_K.nombre));
  late final _ciudad = TextEditingController(text: _v(_K.ciudad));
  late final _ocupacion = TextEditingController(text: _v(_K.ocupacion));
  late final _ingreso = TextEditingController(text: _v(_K.ingreso));
  late final _diaPago = TextEditingController(text: _v(_K.diaPago));
  late final _dependientes =
      TextEditingController(text: _v(_K.dependientes));

  late String _tipoIngreso = _v(_K.tipoIngreso, 'Sueldo fijo');
  late String _hogar = _v(_K.hogar, 'Solo');
  bool _guardando = false;

  String _v(String k, [String porDefecto = '']) =>
      widget.config[k]?.isNotEmpty == true ? widget.config[k]! : porDefecto;

  @override
  void dispose() {
    _nombre.dispose();
    _ciudad.dispose();
    _ocupacion.dispose();
    _ingreso.dispose();
    _diaPago.dispose();
    _dependientes.dispose();
    super.dispose();
  }

  /// Cuanto del perfil esta lleno. Se cuenta sobre lo que el usuario puede
  /// responder, no sobre lo que la app sabe de el.
  double get _completado {
    final valores = <String>[
      _nombre.text,
      _ciudad.text,
      _ocupacion.text,
      _ingreso.text,
      _diaPago.text,
      _dependientes.text,
      _tipoIngreso,
      _hogar,
    ];
    final llenos = valores.where((v) => v.trim().isNotEmpty).length;
    return llenos / valores.length;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: t.superficie,
            borderRadius: BorderRadius.circular(radioTarjeta),
            border: Border.all(color: t.borde),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Informacion completada', style: context.texto.labelSmall),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(radioPastilla),
                child: LinearProgressIndicator(
                  value: _completado,
                  minHeight: 7,
                  backgroundColor: t.superficie2,
                  valueColor: AlwaysStoppedAnimation(t.marca),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Nada de esto es obligatorio. Sirve para que el presupuesto se '
                'parezca a tu situacion y no a una plantilla.',
                style: context.texto.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        _Seccion(
          titulo: 'Datos personales',
          hijos: [
            TextField(
              controller: _nombre,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Nombre preferido'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ciudad,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Ciudad'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ocupacion,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Ocupacion',
                hintText: 'Ej. ingeniero, docente, estudiante',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        _Seccion(
          titulo: 'Informacion financiera',
          hijos: [
            TextField(
              controller: _ingreso,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
              ],
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Ingreso mensual aproximado',
                prefixText: 'S/ ',
              ),
            ),
            const SizedBox(height: 14),
            Text('Tipo de ingreso', style: context.texto.labelSmall),
            const SizedBox(height: 8),
            _Opciones(
              valor: _tipoIngreso,
              opciones: const ['Sueldo fijo', 'Variable'],
              alElegir: (v) => setState(() => _tipoIngreso = v),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _diaPago,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Dia de pago',
                hintText: 'El ciclo del mes arranca en esta fecha',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        _Seccion(
          titulo: 'Hogar',
          hijos: [
            Text('Convivencia', style: context.texto.labelSmall),
            const SizedBox(height: 8),
            _Opciones(
              valor: _hogar,
              opciones: const ['Solo', 'En pareja', 'Con familia'],
              alElegir: (v) => setState(() => _hogar = v),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _dependientes,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Dependientes economicos',
                hintText: 'Personas a tu cargo',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? RanaCargando(tamanio: 18, color: t.marcaTinta)
              : const Text('Guardar perfil'),
        ),
        const SizedBox(height: 14),
        const Aviso(
          tono: TonoAviso.info,
          texto: 'Esto se queda en el telefono, como todo lo demas. No viaja a '
              'ningun servidor.',
        ),
      ],
    );
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final dao = ref.read(daoProvider);
    final valores = {
      _K.nombre: _nombre.text.trim(),
      _K.ciudad: _ciudad.text.trim(),
      _K.ocupacion: _ocupacion.text.trim(),
      _K.ingreso: _ingreso.text.trim(),
      _K.tipoIngreso: _tipoIngreso,
      _K.diaPago: _diaPago.text.trim(),
      _K.hogar: _hogar,
      _K.dependientes: _dependientes.text.trim(),
    };
    for (final e in valores.entries) {
      await dao.guardarConfig(e.key, e.value);
    }
    ref.read(revisionProvider.notifier).refrescar();
    if (!mounted) return;
    setState(() => _guardando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil guardado')),
    );
  }
}

/// Un bloque del formulario.
class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.hijos});

  final String titulo;
  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.superficie,
        borderRadius: BorderRadius.circular(radioTarjeta),
        border: Border.all(color: t.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(titulo, style: context.texto.titleMedium),
          const SizedBox(height: 14),
          ...hijos,
        ],
      ),
    );
  }
}

/// Un segmentado de opciones, como el de la moneda.
class _Opciones extends StatelessWidget {
  const _Opciones({
    required this.valor,
    required this.opciones,
    required this.alElegir,
  });

  final String valor;
  final List<String> opciones;
  final ValueChanged<String> alElegir;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.superficie2,
        borderRadius: BorderRadius.circular(radioPastilla),
      ),
      child: Row(
        children: [
          for (final o in opciones)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(radioPastilla),
                onTap: () => alElegir(o),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: valor == o ? t.marca : Colors.transparent,
                    borderRadius: BorderRadius.circular(radioPastilla),
                  ),
                  child: Text(
                    o,
                    textAlign: TextAlign.center,
                    style: context.texto.bodySmall?.copyWith(
                      color: valor == o ? t.marcaTinta : t.apagado,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
