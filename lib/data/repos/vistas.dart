import '../../domain/finanzas.dart';
import '../../domain/movimiento.dart';

/// Un corte de gasto por categoria, listo para el grafico.
class CorteCategoria {
  const CorteCategoria({
    required this.categoria,
    required this.monto,
    required this.color,
    this.icono = '',
    this.movimientos = 0,
  });

  final String categoria;
  final double monto;
  final String color;
  final String icono;
  final int movimientos;
}

/// Cuanto consumiste con cada tarjeta o cuenta este mes.
class ConsumoMedio {
  const ConsumoMedio({
    required this.cuentaId,
    required this.nombre,
    required this.tipo,
    required this.monto,
    this.ultimos4 = '',
    this.movimientos = 0,
    this.lineaCredito = 0,
    this.diaPago,
  });

  final String cuentaId;
  final String nombre;
  final String tipo;
  final double monto;
  final String ultimos4;
  final int movimientos;
  final double lineaCredito;
  final int? diaPago;

  bool get esTarjetaCredito => tipo == 'TARJETA_CREDITO';

  /// Cuanto de la linea llevas consumido. Solo tiene sentido en tarjetas.
  double get usoLinea =>
      lineaCredito > 0 ? (monto / lineaCredito).clamp(0.0, 1.0) : 0;
}

/// Un punto de la evolucion mensual.
class PuntoMes {
  const PuntoMes({
    required this.periodo,
    required this.ingresos,
    required this.gastos,
  });

  final String periodo;
  final double ingresos;
  final double gastos;

  double get ahorro => ingresos - gastos;
}

/// Un pago de tarjeta que se viene.
class ProximoPago {
  const ProximoPago({
    required this.cuentaId,
    required this.nombre,
    required this.diaPago,
    required this.diasRestantes,
    required this.consumoDelMes,
  });

  final String cuentaId;
  final String nombre;
  final int diaPago;
  final int diasRestantes;
  final double consumoDelMes;

  bool get urgente => diasRestantes <= 3;
}

/// Cuanta parte del mes esta cubierta por correos del banco.
///
/// Existe para ser honesto con el usuario: si un mes casi no tiene correos, sus
/// totales no estan bien y decirlo vale mas que mostrar un numero bonito.
class Cobertura {
  const Cobertura({
    required this.diasConMovimiento,
    required this.diasDelPeriodo,
    required this.movimientosPorCorreo,
    required this.movimientosManuales,
  });

  final int diasConMovimiento;
  final int diasDelPeriodo;
  final int movimientosPorCorreo;
  final int movimientosManuales;

  double get porcentaje =>
      diasDelPeriodo > 0 ? diasConMovimiento / diasDelPeriodo : 0;

  /// Por debajo de un tercio del mes, los totales no son confiables.
  bool get baja => porcentaje < 0.33 && movimientosPorCorreo < 5;
}

/// Tu posicion consolidada: lo que tienes menos lo que debes.
class PosicionConsolidada {
  const PosicionConsolidada({
    required this.fecha,
    required this.liquidezPen,
    required this.deudaPen,
    required this.inversionesPen,
    required this.neto,
    required this.tipoCambio,
    this.notas = '',
    this.hayFoto = true,
  });

  final String fecha;
  final double liquidezPen;
  final double deudaPen;
  final double inversionesPen;
  final double neto;
  final double tipoCambio;
  final String notas;

  /// Falso cuando el usuario todavia no registro ninguna foto.
  final bool hayFoto;
}

/// Todo lo que pinta el Dashboard, calculado de una sola pasada.
class DatosDashboard {
  const DatosDashboard({
    required this.periodo,
    required this.ingresos,
    required this.gastos,
    required this.presupuestado,
    required this.porCategoria,
    required this.porMedio,
    required this.evolucion,
    required this.ultimos,
    required this.posicion,
    required this.avances,
    required this.proximosPagos,
    required this.suscripciones,
    required this.cobertura,
    required this.pendientes,
  });

  final String periodo;
  final double ingresos;
  final double gastos;
  final double presupuestado;
  final List<CorteCategoria> porCategoria;
  final List<ConsumoMedio> porMedio;
  final List<PuntoMes> evolucion;
  final List<Movimiento> ultimos;
  final PosicionConsolidada posicion;
  final List<AvancePresupuesto> avances;
  final List<ProximoPago> proximosPagos;
  final List<Suscripcion> suscripciones;
  final Cobertura cobertura;
  final int pendientes;

  double get ahorro => ingresos - gastos;

  double get tasaAhorro => ingresos > 0 ? ahorro / ingresos : 0;

  double get presupuestoDisponible => presupuestado - gastos;

  double get consumoPresupuesto =>
      presupuestado > 0 ? gastos / presupuestado : 0;

  /// Cuanto te cuestan al anio las suscripciones que siguen activas.
  double get costoAnualSuscripciones => suscripciones
      .where((s) => s.activa)
      .fold(0.0, (a, s) => a + s.costoAnual);
}

/// Como se repartio cada sol que entro.
class DistribucionIngreso {
  const DistribucionIngreso({
    required this.ingresos,
    required this.gastos,
    required this.inversion,
  });

  final double ingresos;
  final double gastos;
  final double inversion;

  double get ahorro => ingresos - gastos - inversion;

  double _pct(double v) => ingresos > 0 ? (v / ingresos).clamp(0.0, 1.0) : 0;

  double get pctGasto => _pct(gastos);

  double get pctInversion => _pct(inversion);

  double get pctAhorro => ingresos > 0 ? (ahorro / ingresos) : 0;
}
