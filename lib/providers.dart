import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/fechas.dart';
import '../data/db/base_datos.dart';
import '../data/fx/tipo_cambio.dart';
import '../data/gmail/autenticacion.dart';
import '../data/gmail/cliente_gmail.dart';
import '../data/ingesta/servicio_ingesta.dart';
import '../data/repos/dao.dart';
import '../data/repos/repositorio.dart';
import '../data/repos/vistas.dart';
import '../domain/catalogo.dart';
import '../domain/finanzas.dart';
import '../domain/movimiento.dart';

// ============================================================================
//  INFRAESTRUCTURA
// ============================================================================

final baseDatosProvider = Provider<BaseDatos>((_) => BaseDatos.instancia);

final daoProvider = Provider<Dao>((ref) => Dao(ref.watch(baseDatosProvider)));

final tipoCambioProvider =
    Provider<ServicioTipoCambio>((ref) => ServicioTipoCambio(ref.watch(daoProvider)));

final repositorioProvider = Provider<Repositorio>(
  (ref) => Repositorio(ref.watch(daoProvider), ref.watch(tipoCambioProvider)),
);

/// El cliente de Google. El `clientId` de iOS se inyecta desde
/// `Info.plist`; en Android sale del SHA-1 configurado en Google Cloud.
final autenticacionProvider =
    Provider<AutenticacionGmail>((_) => AutenticacionGmail());

final clienteGmailProvider = Provider<ClienteGmail>(
  (ref) => ClienteGmail(ref.watch(autenticacionProvider)),
);

final ingestaProvider = Provider<ServicioIngesta>(
  (ref) => ServicioIngesta(
    dao: ref.watch(daoProvider),
    gmail: ref.watch(clienteGmailProvider),
    fx: ref.watch(tipoCambioProvider),
  ),
);

final preferenciasProvider =
    FutureProvider<SharedPreferences>((_) => SharedPreferences.getInstance());

// ============================================================================
//  ESTADO DE LA APP
// ============================================================================

/// El periodo que se esta mirando. Es global: cambiarlo en el Dashboard tiene
/// que cambiarlo tambien en Presupuesto y en Movimientos.
final periodoProvider =
    NotifierProvider<PeriodoNotifier, String>(PeriodoNotifier.new);

class PeriodoNotifier extends Notifier<String> {
  @override
  String build() => periodoActual();

  void cambiar(String periodo) => state = periodo;
}

final temaProvider = NotifierProvider<TemaNotifier, ThemeMode>(TemaNotifier.new);

class TemaNotifier extends Notifier<ThemeMode> {
  static const _clave = 'tema';

  @override
  ThemeMode build() {
    _cargar();
    return ThemeMode.system;
  }

  Future<void> _cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_clave);
    if (v == null) return;
    state = ThemeMode.values.firstWhere(
      (m) => m.name == v,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> cambiar(ThemeMode modo) async {
    state = modo;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clave, modo.name);
  }
}

/// Estado de la sesion de Google.
final sesionProvider =
    AsyncNotifierProvider<SesionNotifier, bool>(SesionNotifier.new);

class SesionNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async =>
      ref.watch(autenticacionProvider).reconectar();

  Future<void> entrar() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(autenticacionProvider).entrar(),
    );
  }

  Future<void> salir() async {
    await ref.read(autenticacionProvider).salir();
    state = const AsyncValue.data(false);
  }

  Future<void> desconectar() async {
    await ref.read(autenticacionProvider).desconectar();
    state = const AsyncValue.data(false);
  }
}

/// Se incrementa cada vez que algo cambia en la base. Las pantallas lo miran
/// para recargarse: es mas simple y mas confiable que invalidar a mano cada
/// provider desde cada formulario.
final revisionProvider =
    NotifierProvider<RevisionNotifier, int>(RevisionNotifier.new);

class RevisionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void refrescar() => state++;
}

// ============================================================================
//  DATOS DERIVADOS
// ============================================================================

final dashboardProvider = FutureProvider<DatosDashboard>((ref) {
  ref.watch(revisionProvider);
  return ref
      .watch(repositorioProvider)
      .dashboard(ref.watch(periodoProvider));
});

final cuentasProvider = FutureProvider<List<Cuenta>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(daoProvider).cuentas();
});

final categoriasProvider = FutureProvider<List<Categoria>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(daoProvider).categorias();
});

final reglasProvider = FutureProvider<List<Regla>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(daoProvider).reglas();
});

final remitentesProvider = FutureProvider<List<Remitente>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(daoProvider).remitentes();
});

final periodosProvider = FutureProvider<List<String>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(daoProvider).periodosDisponibles();
});

final pendientesProvider = FutureProvider<List<Movimiento>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(daoProvider).pendientesRevision();
});

final configProvider = FutureProvider<Map<String, String>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(daoProvider).config();
});

final plantillasProvider = FutureProvider<List<PlantillaIngreso>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(daoProvider).plantillas();
});

final presupuestoProvider =
    FutureProvider<List<AvancePresupuesto>>((ref) {
  ref.watch(revisionProvider);
  return ref
      .watch(repositorioProvider)
      .avancesPresupuesto(ref.watch(periodoProvider));
});

final posicionesProvider = FutureProvider<List<PosicionInversion>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(repositorioProvider).posiciones();
});

final patrimonioProvider = FutureProvider<List<FotoPatrimonio>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(daoProvider).patrimonio();
});

/// Filtros de la pantalla de movimientos.
final filtroProvider =
    NotifierProvider<FiltroNotifier, FiltroMovimientos>(FiltroNotifier.new);

class FiltroNotifier extends Notifier<FiltroMovimientos> {
  @override
  FiltroMovimientos build() =>
      FiltroMovimientos(periodo: ref.watch(periodoProvider));

  void actualizar(FiltroMovimientos f) => state = f;

  void limpiar() =>
      state = FiltroMovimientos(periodo: ref.read(periodoProvider));
}

final movimientosProvider = FutureProvider<List<Movimiento>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(daoProvider).movimientos(ref.watch(filtroProvider));
});

// ============================================================================
//  SINCRONIZACION
// ============================================================================

/// Lo que esta pasando con la sincronizacion, para que la interfaz lo muestre.
sealed class EstadoSync {
  const EstadoSync();
}

class SyncQuieto extends EstadoSync {
  const SyncQuieto();
}

class SyncCorriendo extends EstadoSync {
  const SyncCorriendo(this.mensaje);

  final String mensaje;
}

class SyncListo extends EstadoSync {
  const SyncListo(this.resultado);

  final ResultadoSync resultado;
}

class SyncFallo extends EstadoSync {
  const SyncFallo(this.mensaje);

  final String mensaje;
}

final syncProvider =
    NotifierProvider<SyncNotifier, EstadoSync>(SyncNotifier.new);

class SyncNotifier extends Notifier<EstadoSync> {
  @override
  EstadoSync build() => const SyncQuieto();

  Future<void> sincronizar({int? dias}) async {
    if (state is SyncCorriendo) return;
    state = const SyncCorriendo('Leyendo tus correos...');
    try {
      final r = await ref.read(ingestaProvider).sincronizar(dias: dias);
      state = r.error != null ? SyncFallo(r.error!) : SyncListo(r);
      if (r.huboAlgo) ref.read(revisionProvider.notifier).refrescar();
    } catch (e) {
      state = SyncFallo(e.toString());
    }
  }

  Future<void> historico(DateTime desde, DateTime hasta) async {
    if (state is SyncCorriendo) return;
    state = const SyncCorriendo('Procesando el historico...');
    try {
      final r =
          await ref.read(ingestaProvider).sincronizarHistorico(desde, hasta);
      state = r.error != null ? SyncFallo(r.error!) : SyncListo(r);
      ref.read(revisionProvider.notifier).refrescar();
    } catch (e) {
      state = SyncFallo(e.toString());
    }
  }

  void limpiar() => state = const SyncQuieto();
}
