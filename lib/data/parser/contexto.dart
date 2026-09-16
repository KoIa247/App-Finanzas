import '../../domain/enums.dart';

/// Lo que el parser recibe de un correo ya descargado.
class ContextoCorreo {
  const ContextoCorreo({
    required this.parser,
    required this.banco,
    required this.asunto,
    required this.html,
    required this.texto,
    required this.fechaMensaje,
    required this.idMensaje,
    required this.config,
  });

  /// BCP | GENERICO
  final String parser;
  final String banco;
  final String asunto;
  final String html;
  final String texto;
  final DateTime fechaMensaje;
  final String idMensaje;
  final ConfigParser config;
}

/// Los ajustes que cambian como se lee un correo.
///
/// Se pasan explicitamente en vez de leerse de un global para que las pruebas
/// puedan medir el parser con una politica fija, sin depender de lo que el
/// usuario tenga elegido en ese momento.
class ConfigParser {
  const ConfigParser({
    this.politicaTerceros = PoliticaTerceros.ignorar,
    this.tercerosSiempreRegistrar = const [],
    this.registrarDebito = false,
    this.debitoSiempreRegistrar = const ['PLIN-'],
    this.cuentaEfectivo = 'EFECTIVO',
    this.cuentaEnvios = 'EFECTIVO',
  });

  final PoliticaTerceros politicaTerceros;

  /// Beneficiarios que SI se registran aunque la politica sea ignorar.
  final List<String> tercerosSiempreRegistrar;

  /// De fabrica solo se registran los consumos con tarjeta de credito.
  final bool registrarDebito;

  /// Comercios que si se registran aunque el debito este apagado. Los Plin
  /// vienen de fabrica: no son una compra con la tarjeta, es plata que le
  /// mandas a una persona.
  final List<String> debitoSiempreRegistrar;

  final String cuentaEfectivo;

  /// Cuenta a la que se cargan los Yape, Plin y envios a personas.
  final String cuentaEnvios;
}

/// Movimiento tal como sale del parser, antes de resolver cuentas, clasificar
/// y convertir a soles. Es mutable a proposito: la tuberia de ingesta lo va
/// completando por pasos.
class MovimientoCrudo {
  MovimientoCrudo({
    this.banco = '',
    this.fecha = '',
    this.hora = '',
    this.tipo = TipoMovimiento.gasto,
    this.importe = 0,
    this.moneda = 'PEN',
    this.comercio = '',
    this.descripcion = '',
    this.categoria = '',
    this.subcategoria = '',
    this.medioPago = '',
    this.nroOperacion = '',
    this.tipoCambio,
    this.importePen,
    this.estado = EstadoMovimiento.ok,
    this.motivoRevision = '',
    this.recurrente = false,
    this.cuentaU4 = '',
    this.u4Origen = '',
    this.cuentaTipo = '',
    this.cuentaDestinoU4 = '',
    this.cuentaDestinoTipo = '',
    this.cuentaId = '',
    this.cuentaDestinoId = '',
    this.comision = 0,
    this.movimientoRel = '',
    this.notas = '',
    this.reglaAplicada = '',
    this.esCredito = true,
  });

  String banco;
  String fecha;
  String hora;
  TipoMovimiento tipo;
  double importe;
  String moneda;
  String comercio;
  String descripcion;
  String categoria;
  String subcategoria;
  String medioPago;
  String nroOperacion;
  double? tipoCambio;
  double? importePen;
  EstadoMovimiento estado;
  String motivoRevision;
  bool recurrente;

  /// Ultimos 4 digitos de la cuenta o tarjeta de cargo.
  String cuentaU4;

  /// Los digitos por los que viajo el dinero, aunque no se cargue ahi.
  ///
  /// Un Plin sale por la tarjeta de debito pero no se carga a ella. Guardar el
  /// numero aparte es lo unico que permite saber despues si el dinero salio de
  /// una cuenta que no es tuya.
  String u4Origen;

  String cuentaTipo;
  String cuentaDestinoU4;
  String cuentaDestinoTipo;

  /// Id de cuenta ya resuelto contra el catalogo.
  String cuentaId;
  String cuentaDestinoId;

  double comision;
  String movimientoRel;
  String notas;
  String reglaAplicada;

  /// Solo para consumos: si fue con credito o con debito.
  bool esCredito;

  /// Acumula un motivo de revision sin pisar el que ya hubiera.
  ///
  /// Se acumula, no se reemplaza: si ademas de decidir el tipo hay que asignar
  /// la cuenta, las dos cosas tienen que quedar a la vista.
  void agregarMotivo(String motivo) {
    if (motivo.isEmpty) return;
    motivoRevision =
        motivoRevision.isEmpty ? motivo : '$motivoRevision · $motivo';
  }
}

/// Lo que devuelve un parser sobre un correo.
class ResultadoParser {
  const ResultadoParser._(this.accion, this.motivo, this.movimiento);

  const ResultadoParser.registrar(MovimientoCrudo mov)
      : this._(AccionParser.registrar, '', mov);

  const ResultadoParser.ignorar(String motivo)
      : this._(AccionParser.ignorar, motivo, null);

  const ResultadoParser.error(String motivo)
      : this._(AccionParser.error, motivo, null);

  final AccionParser accion;
  final String motivo;
  final MovimientoCrudo? movimiento;
}
