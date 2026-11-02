/// Modelo que representa un pago realizado sobre una deuda.
///
/// Transporta información entre SQLite, Repository,
/// Service, Provider y las pantallas de Deudas.
class DebtPaymentModel {
  /// Identificador del pago.
  final int? idPago;

  /// Monto total pagado.
  final double monto;

  /// Valor aplicado directamente al capital.
  final double abonoCapital;

  /// Valor destinado al pago de intereses.
  final double interesesPagados;

  /// Tipo de movimiento: ORDINARIO o EXTRAORDINARIO.
  final String tipoPago;

  /// Opción elegida para un abono extraordinario:
  /// REDUCIR_PLAZO o REDUCIR_CUOTA.
  final String? opcionAbono;

  /// Fecha del pago en formato ISO.
  final String fecha;

  /// Método utilizado para realizar el pago.
  final String? metodoPago;

  /// Descripción adicional del pago.
  final String? descripcion;

  /// Identificador de la deuda asociada.
  final int idDeuda;

  /// Fecha de creación del registro.
  final String fechaRegistro;

  /// Constructor del modelo.
  const DebtPaymentModel({
    this.idPago,
    required this.monto,
    this.abonoCapital = 0,
    this.interesesPagados = 0,
    this.tipoPago = 'ORDINARIO',
    this.opcionAbono,
    required this.fecha,
    this.metodoPago,
    this.descripcion,
    required this.idDeuda,
    required this.fechaRegistro,
  });

  /// Convierte el objeto en un Map para SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id_pago': idPago,
      'monto': monto,
      'abono_capital': abonoCapital,
      'intereses_pagados': interesesPagados,
      'tipo_pago': tipoPago,
      'opcion_abono': opcionAbono,
      'fecha': fecha,
      'metodo_pago': metodoPago,
      'descripcion': descripcion,
      'id_deuda': idDeuda,
      'fecha_registro': fechaRegistro,
    };
  }

  /// Crea un DebtPaymentModel a partir de un registro de SQLite.
  factory DebtPaymentModel.fromMap(Map<String, dynamic> map) {
    return DebtPaymentModel(
      idPago: map['id_pago'],
      monto: (map['monto'] as num).toDouble(),
      abonoCapital: (map['abono_capital'] as num?)?.toDouble() ?? 0,
      interesesPagados: (map['intereses_pagados'] as num?)?.toDouble() ?? 0,
      tipoPago: map['tipo_pago'] ?? 'ORDINARIO',
      opcionAbono: map['opcion_abono'],
      fecha: map['fecha'],
      metodoPago: map['metodo_pago'],
      descripcion: map['descripcion'],
      idDeuda: map['id_deuda'],
      fechaRegistro: map['fecha_registro'],
    );
  }

  /// Crea una copia modificando únicamente
  /// los campos enviados como parámetro.
  DebtPaymentModel copyWith({
    int? idPago,
    double? monto,
    double? abonoCapital,
    double? interesesPagados,
    String? tipoPago,
    String? opcionAbono,
    String? fecha,
    String? metodoPago,
    String? descripcion,
    int? idDeuda,
    String? fechaRegistro,
  }) {
    return DebtPaymentModel(
      idPago: idPago ?? this.idPago,
      monto: monto ?? this.monto,
      abonoCapital: abonoCapital ?? this.abonoCapital,
      interesesPagados: interesesPagados ?? this.interesesPagados,
      tipoPago: tipoPago ?? this.tipoPago,
      opcionAbono: opcionAbono ?? this.opcionAbono,
      fecha: fecha ?? this.fecha,
      metodoPago: metodoPago ?? this.metodoPago,
      descripcion: descripcion ?? this.descripcion,
      idDeuda: idDeuda ?? this.idDeuda,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    );
  }
}
