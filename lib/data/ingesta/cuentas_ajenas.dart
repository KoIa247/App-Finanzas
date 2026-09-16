import '../../core/texto.dart';
import '../../domain/catalogo.dart';
import '../../domain/enums.dart';
import '../parser/contexto.dart';

/// Conecta los ultimos 4 digitos del correo con la cuenta correcta.
///
/// Cuando varias cuentas comparten los mismos digitos (pasa: una tarjeta y una
/// cuenta del mismo banco), se desempata por tipo y despues por moneda.
String resolverCuenta(
  List<Cuenta> cuentas,
  String ultimos4, {
  String tipoHint = '',
  String moneda = 'PEN',
}) {
  final u4 = ultimos4.trim();
  if (u4.isEmpty) return '';

  final candidatas =
      cuentas.where((c) => c.ultimos4.trim() == u4 && c.activa).toList();
  if (candidatas.isEmpty) return '';
  if (candidatas.length == 1) return candidatas.first.id;

  final porTipo =
      candidatas.where((c) => norm(c.tipo) == norm(tipoHint)).toList();
  if (porTipo.length == 1) return porTipo.first.id;

  final base = porTipo.isNotEmpty ? porTipo : candidatas;
  final porMoneda = base.where((c) => norm(c.moneda) == norm(moneda)).toList();
  return (porMoneda.isNotEmpty ? porMoneda.first : base.first).id;
}

Cuenta? buscarCuenta(List<Cuenta> cuentas, String id) {
  if (id.isEmpty) return null;
  for (final c in cuentas) {
    if (c.id == id) return c;
  }
  return null;
}

/// Esos ultimos 4 digitos, pertenecen a una cuenta que no es tuya?
///
/// A proposito NO mira si la cuenta esta activa: si la desactivas, el banco
/// sigue mandando los correos y sin esto volverian a contarse como tuyos. La
/// marca "no es mi dinero" tiene que sobrevivir a que la cuenta se desactive.
bool u4EsAjeno(List<Cuenta> cuentas, String u4) {
  final buscado = u4.trim();
  if (buscado.isEmpty) return false;
  return cuentas.any((c) => c.ultimos4.trim() == buscado && !c.esPropia);
}

bool u4EsPropio(List<Cuenta> cuentas, String u4) {
  final buscado = u4.trim();
  if (buscado.isEmpty) return false;
  return cuentas.any((c) => c.ultimos4.trim() == buscado && c.esPropia);
}

/// Que hacer con un movimiento que toca una cuenta ajena.
class VeredictoAjeno {
  const VeredictoAjeno({
    this.descartar = false,
    this.motivo = '',
    this.convertirEnIngreso = false,
    this.convertirEnGasto = false,
  });

  final bool descartar;
  final String motivo;
  final bool convertirEnIngreso;
  final bool convertirEnGasto;

  bool get hayAjuste => convertirEnIngreso || convertirEnGasto;
}

/// Este movimiento traslada dinero entre cuentas de verdad?
///
/// Un retiro en cajero o un pago de tarjeta tambien traen una "cuenta destino",
/// pero es sintetica: tratarlos como traslado convertiria un retiro de la
/// cuenta ajena en un ingreso tuyo.
bool esTraslado(MovimientoCrudo mov) =>
    mov.tipo == TipoMovimiento.transferencia ||
    mov.descripcion.startsWith('Transferencia a terceros');

/// DECIDE QUE HACER CON UN MOVIMIENTO QUE TOCA UNA CUENTA AJENA.
///
/// Hay cuentas que operas pero cuyo dinero no es tuyo: la del negocio de un
/// familiar es el caso tipico. El banco te manda el correo porque tu haces la
/// operacion, pero esa plata nunca fue tuya. Esos correos NO se registran.
///
/// Tres situaciones, y las tres importan:
///
///   origen ajeno -> destino ajeno o desconocido : NO ES TU PLATA. Se descarta.
///   origen ajeno -> destino tuyo                : ESA PLATA YA ES TUYA. Entra
///                                                 como ingreso a tu cuenta.
///   origen tuyo  -> destino ajeno               : PLATA TUYA QUE SE VA. Entra
///                                                 como gasto, no como
///                                                 transferencia interna.
///
/// La comparacion usa la cuenta ya resuelta cuando existe, y solo cae a los
/// digitos cuando no se pudo resolver. Ese orden importa: [resolverCuenta] sabe
/// desempatar por tipo y moneda, asi que si tuvieras una tarjeta propia con los
/// mismos digitos que la cuenta ajena, tu consumo se sigue registrando.
VeredictoAjeno evaluarAjeno(List<Cuenta> cuentas, MovimientoCrudo mov) {
  final u4Origen = mov.u4Origen.isNotEmpty ? mov.u4Origen : mov.cuentaU4;
  final u4Destino = mov.cuentaDestinoU4;
  final traslado = esTraslado(mov);

  final cuentaOrigen = buscarCuenta(cuentas, mov.cuentaId);
  final origenAjeno = cuentaOrigen != null
      ? !cuentaOrigen.esPropia
      : u4EsAjeno(cuentas, u4Origen);

  // El destino solo cuenta como tuyo si existe de verdad en el catalogo: un id
  // que no esta en la tabla no es una cuenta tuya, es un dato roto.
  final destinoReal = buscarCuenta(cuentas, mov.cuentaDestinoId);
  final destinoAjeno = traslado &&
      (destinoReal != null
          ? !destinoReal.esPropia
          : u4EsAjeno(cuentas, u4Destino));
  final destinoPropio = traslado &&
      (destinoReal != null
          ? destinoReal.esPropia
          : u4EsPropio(cuentas, u4Destino));

  if (origenAjeno) {
    if (destinoPropio) {
      return VeredictoAjeno(
        convertirEnIngreso: true,
        motivo: '${MotivoRevision.entradaAjena}'
            '${cuentaOrigen?.nombre ?? 'una cuenta que no es tuya'}',
      );
    }
    return VeredictoAjeno(
      descartar: true,
      motivo: 'Sale de ${cuentaOrigen?.nombre ?? 'una cuenta ajena'}: '
          'ese dinero no es tuyo',
    );
  }

  if (destinoAjeno) {
    return VeredictoAjeno(
      convertirEnGasto: true,
      motivo: '${MotivoRevision.salidaAjena}'
          '${destinoReal?.nombre ?? mov.comercio}',
    );
  }

  return const VeredictoAjeno();
}

/// Aplica el ajuste que decidio [evaluarAjeno].
void aplicarAjusteAjeno(MovimientoCrudo mov, VeredictoAjeno v) {
  if (v.convertirEnIngreso) {
    mov.tipo = TipoMovimiento.ingreso;
    mov.categoria = 'Ingresos';
    mov.subcategoria = 'Transferencias recibidas';
    // La cuenta pasa a ser la de destino: la plata entro ahi.
    mov.cuentaId = mov.cuentaDestinoId;
    mov.cuentaDestinoId = '';
  } else if (v.convertirEnGasto) {
    mov.tipo = TipoMovimiento.gasto;
    mov.categoria = '';
    mov.subcategoria = '';
  }
  mov.estado = EstadoMovimiento.revisar;
  mov.agregarMotivo(v.motivo);
}

/// Yape, Plin y los envios a personas no son una compra en un comercio, asi
/// que no se cargan a la tarjeta por la que viajaron.
bool esEnvioAPersona(MovimientoCrudo mov) =>
    mov.medioPago == MedioPago.yape ||
    mov.medioPago == MedioPago.plin ||
    mov.categoria == 'Envios a personas';
