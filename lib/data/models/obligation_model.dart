/// Modelo que representa una obligación del usuario.
///
/// Transporta información entre SQLite, Repository,
/// Service, Provider y las pantallas de Obligaciones.
class ObligationModel {
  /// Identificador de la obligación.
  final int? idObligacion;

  /// Nombre de la obligación.
  final String nombre;

  /// Monto de la obligación.
  final double monto;

  /// Identificador de la categoría financiera.
  final int idCategoria;

  /// Fecha de vencimiento en formato ISO.
  final String fechaVencimiento;

  /// Indica si tiene recordatorio activo.
  final bool recordatorio;

  /// Estado de la obligación: Pendiente o Pagada.
  final String estado;

  /// Indica si la obligación es recurrente.
  final bool esRecurrente;

  /// Día del mes en que vence una obligación recurrente.
  final int? diaVencimiento;

  /// Identificador del usuario propietario.
  final int idUsuario;

  /// Identificador del gasto generado al pagar la obligación.
  final int? idGastoGenerado;

  /// Fecha de creación del registro.
  final String fechaRegistro;

  /// Frecuencia de la obligación recurrente.
  final String? frecuencia;

  const ObligationModel({
    this.idObligacion,
    required this.nombre,
    required this.monto,
    required this.idCategoria,
    required this.fechaVencimiento,
    required this.recordatorio,
    required this.estado,
    required this.esRecurrente,
    this.diaVencimiento,
    required this.idUsuario,
    this.idGastoGenerado,
    required this.fechaRegistro,
    this.frecuencia,
  });

  /// Convierte el objeto en un Map para SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id_obligacion': idObligacion,
      'nombre': nombre,
      'monto': monto,
      'id_categoria': idCategoria,
      'fecha_vencimiento': fechaVencimiento,
      'recordatorio': recordatorio ? 1 : 0,
      'estado': estado,
      'es_recurrente': esRecurrente ? 1 : 0,
      'dia_vencimiento': diaVencimiento,
      'id_usuario': idUsuario,
      'id_gasto_generado': idGastoGenerado,
      'fecha_registro': fechaRegistro,
      'frecuencia': frecuencia,
    };
  }

  /// Crea un modelo a partir de un registro obtenido de SQLite.
  factory ObligationModel.fromMap(Map<String, dynamic> map) {
    return ObligationModel(
      idObligacion: map['id_obligacion'],
      nombre: map['nombre'],
      monto: (map['monto'] as num).toDouble(),
      idCategoria: map['id_categoria'],
      fechaVencimiento: map['fecha_vencimiento'],
      recordatorio: map['recordatorio'] == 1,
      estado: map['estado'],
      esRecurrente: map['es_recurrente'] == 1,
      diaVencimiento: map['dia_vencimiento'],
      idUsuario: map['id_usuario'],
      idGastoGenerado: map['id_gasto_generado'],
      fechaRegistro: map['fecha_registro'],
      frecuencia: map['frecuencia'],
    );
  }

  /// Crea una copia modificando únicamente
  /// los campos enviados como parámetro.
  ObligationModel copyWith({
    int? idObligacion,
    String? nombre,
    double? monto,
    int? idCategoria,
    String? fechaVencimiento,
    bool? recordatorio,
    String? estado,
    bool? esRecurrente,
    int? diaVencimiento,
    int? idUsuario,
    int? idGastoGenerado,
    String? fechaRegistro,
    String? frecuencia,
  }) {
    return ObligationModel(
      idObligacion: idObligacion ?? this.idObligacion,
      nombre: nombre ?? this.nombre,
      monto: monto ?? this.monto,
      idCategoria: idCategoria ?? this.idCategoria,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      recordatorio: recordatorio ?? this.recordatorio,
      estado: estado ?? this.estado,
      esRecurrente: esRecurrente ?? this.esRecurrente,
      diaVencimiento: diaVencimiento ?? this.diaVencimiento,
      idUsuario: idUsuario ?? this.idUsuario,
      idGastoGenerado: idGastoGenerado ?? this.idGastoGenerado,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      frecuencia: frecuencia ?? this.frecuencia,
    );
  }
}
