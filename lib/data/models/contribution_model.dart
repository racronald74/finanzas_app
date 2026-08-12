/// Modelo que representa un aporte realizado a una meta.
///
/// Su responsabilidad es transportar la información del aporte
/// entre SQLite, Repository, Service, Provider y las pantallas.
class ContributionModel {
  /// Identificador único del aporte.
  final int? idAporte;

  /// Valor monetario del aporte.
  final double monto;

  /// Fecha en la que se realizó el aporte.
  ///
  /// Se almacena como texto para mantener compatibilidad
  /// con el formato utilizado actualmente en SQLite.
  final String fecha;

  /// Origen o método utilizado para realizar el aporte.
  ///
  /// Ejemplos:
  /// - Efectivo
  /// - Transferencia
  /// - Nequi
  /// - Daviplata
  /// - Cuenta bancaria
  final String origen;

  /// Identificador de la meta a la que pertenece el aporte.
  final int idMeta;

  /// Fecha y hora en la que se registró el aporte.
  final String? fechaRegistro;

  /// Constructor del modelo.
  const ContributionModel({
    this.idAporte,
    required this.monto,
    required this.fecha,
    required this.origen,
    required this.idMeta,
    this.fechaRegistro,
  });

  /// Convierte el modelo en un Map para SQLite.
  Map<String, dynamic> toMap() {
    final map = {
      'id_aporte': idAporte,
      'monto': monto,
      'fecha': fecha,
      'origen': origen,
      'id_meta': idMeta,
      'fecha_registro': fechaRegistro,
    };

    // No enviamos a SQLite los campos cuyo valor sea null.
    map.removeWhere((_, value) => value == null);

    return map;
  }

  /// Crea un ContributionModel a partir de un registro de SQLite.
  factory ContributionModel.fromMap(Map<String, dynamic> map) {
    return ContributionModel(
      idAporte: map['id_aporte'],
      monto: (map['monto'] as num).toDouble(),
      fecha: map['fecha'] ?? '',
      origen: map['origen'] ?? '',
      idMeta: map['id_meta'],
      fechaRegistro: map['fecha_registro'],
    );
  }

  /// Crea una copia del aporte modificando únicamente
  /// los campos enviados como parámetro.
  ContributionModel copyWith({
    int? idAporte,
    double? monto,
    String? fecha,
    String? origen,
    int? idMeta,
    String? fechaRegistro,
  }) {
    return ContributionModel(
      idAporte: idAporte ?? this.idAporte,
      monto: monto ?? this.monto,
      fecha: fecha ?? this.fecha,
      origen: origen ?? this.origen,
      idMeta: idMeta ?? this.idMeta,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    );
  }
}
