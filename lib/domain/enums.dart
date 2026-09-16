/// Tipos de movimiento. El signo indica como afecta al patrimonio.
enum TipoMovimiento {
  gasto('GASTO'),
  ingreso('INGRESO'),
  transferencia('TRANSFERENCIA'),
  pagoTarjeta('PAGO_TARJETA'),
  devolucion('DEVOLUCION'),
  retiroEfectivo('RETIRO_EFECTIVO'),
  aporteInversion('APORTE_INVERSION'),
  retiroInversion('RETIRO_INVERSION'),
  comision('COMISION');

  const TipoMovimiento(this.valor);

  final String valor;

  static TipoMovimiento desde(Object? v) {
    final s = v?.toString().toUpperCase().trim();
    return TipoMovimiento.values.firstWhere(
      (t) => t.valor == s,
      orElse: () => TipoMovimiento.gasto,
    );
  }

  /// Los movimientos que no son ni gasto ni ingreso: solo mueven plata de un
  /// bolsillo a otro. Nunca deben sumar al total del mes.
  bool get esNeutro => const {
        TipoMovimiento.transferencia,
        TipoMovimiento.pagoTarjeta,
        TipoMovimiento.retiroEfectivo,
        TipoMovimiento.aporteInversion,
        TipoMovimiento.retiroInversion,
      }.contains(this);

  String get etiqueta => switch (this) {
        TipoMovimiento.gasto => 'Gasto',
        TipoMovimiento.ingreso => 'Ingreso',
        TipoMovimiento.transferencia => 'Transferencia',
        TipoMovimiento.pagoTarjeta => 'Pago de tarjeta',
        TipoMovimiento.devolucion => 'Devolucion',
        TipoMovimiento.retiroEfectivo => 'Retiro de efectivo',
        TipoMovimiento.aporteInversion => 'Aporte a inversion',
        TipoMovimiento.retiroInversion => 'Retiro de inversion',
        TipoMovimiento.comision => 'Comision',
      };
}

enum EstadoMovimiento {
  ok('OK'),
  revisar('REVISAR'),
  anulado('ANULADO');

  const EstadoMovimiento(this.valor);

  final String valor;

  static EstadoMovimiento desde(Object? v) {
    final s = v?.toString().toUpperCase().trim();
    return EstadoMovimiento.values.firstWhere(
      (e) => e.valor == s,
      orElse: () => EstadoMovimiento.ok,
    );
  }
}

/// Como se pago. No es un enum cerrado en la base porque los bancos nuevos
/// pueden traer medios que todavia no existen aqui.
class MedioPago {
  static const tarjetaCredito = 'TC';
  static const tarjetaDebito = 'TD';
  static const transferencia = 'TRANSFERENCIA';
  static const efectivo = 'EFECTIVO';
  static const yape = 'YAPE';
  static const plin = 'PLIN';
  static const debitoAutomatico = 'DEBITO_AUTOMATICO';

  static String etiqueta(String? v) => switch (v) {
        tarjetaCredito => 'Tarjeta de credito',
        tarjetaDebito => 'Tarjeta de debito',
        transferencia => 'Transferencia',
        efectivo => 'Efectivo',
        yape => 'Yape',
        plin => 'Plin',
        debitoAutomatico => 'Debito automatico',
        _ => 'Otro',
      };
}

class Fuente {
  static const email = 'EMAIL';
  static const manual = 'MANUAL';
  static const importado = 'IMPORTADO';
}

/// Motivos de revision.
///
/// Son constantes porque el sistema los busca despues para decidir si una duda
/// quedo resuelta: si fueran texto suelto, limpiar una alerta podria borrar
/// otra distinta que si sigue haciendo falta.
class MotivoRevision {
  static const confirmarTransferencia =
      'Confirma si es gasto, prestamo o aporte a inversion';
  static const sinCategoria = 'Sin categoria: crea una regla o corrigela';
  static const entradaAjena = 'Entro plata a tu cuenta desde ';
  static const salidaAjena = 'Salio hacia una cuenta que no es tuya: ';
  static const sinCuenta = 'No se reconocio la cuenta/tarjeta';
  static const vincularDevolucion =
      'Vincula la devolucion con el gasto original si corresponde';
}

/// Tipos de cuenta. Definen como se resuelven los ultimos 4 digitos del correo.
class TipoCuenta {
  static const tarjetaCredito = 'TARJETA_CREDITO';
  static const tarjetaDebito = 'TARJETA_DEBITO';
  static const cuentaCorriente = 'CUENTA_CORRIENTE';
  static const ahorros = 'AHORROS';
  static const efectivo = 'EFECTIVO';
  static const inversion = 'INVERSION';

  static String etiqueta(String? v) => switch (v) {
        tarjetaCredito => 'Tarjeta de credito',
        tarjetaDebito => 'Tarjeta de debito',
        cuentaCorriente => 'Cuenta corriente',
        ahorros => 'Ahorros',
        efectivo => 'Efectivo',
        inversion => 'Inversion',
        _ => 'Cuenta',
      };

  static const todos = [
    tarjetaCredito,
    tarjetaDebito,
    cuentaCorriente,
    ahorros,
    efectivo,
    inversion,
  ];
}

/// Que hacer con las transferencias hacia otra persona.
enum PoliticaTerceros {
  ignorar('IGNORAR'),
  neutro('NEUTRO'),
  gasto('GASTO');

  const PoliticaTerceros(this.valor);

  final String valor;

  static PoliticaTerceros desde(Object? v) {
    final s = v?.toString().toUpperCase().trim();
    return PoliticaTerceros.values.firstWhere(
      (p) => p.valor == s,
      orElse: () => PoliticaTerceros.ignorar,
    );
  }
}

/// Que accion pide un correo despues de leerlo.
enum AccionParser { registrar, ignorar, error }
