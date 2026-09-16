import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'comunes.dart';

/// Pinta carga, error y contenido sin repetir el mismo `when` en cada pantalla.
extension VistaAsincrona<T> on AsyncValue<T> {
  Widget vista(
    Widget Function(T datos) constructor, {
    VoidCallback? alReintentar,
    double altoCarga = 160,
  }) {
    return when(
      data: constructor,
      loading: () => SizedBox(
        height: altoCarga,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      ),
      error: (e, _) => Vacio(
        titulo: 'No se pudo cargar',
        detalle: e.toString(),
        icono: Icons.cloud_off_outlined,
        accion: alReintentar == null
            ? null
            : OutlinedButton(
                onPressed: alReintentar,
                child: const Text('Reintentar'),
              ),
      ),
    );
  }
}
