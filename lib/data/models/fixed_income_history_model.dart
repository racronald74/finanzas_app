/// Modelo que representa un registro histórico
/// del ingreso fijo mensual de un usuario.
class FixedIncomeHistoryModel {
  /// Identificador del registro histórico.
  final int? idIngresoFijo;

  /// Usuario al que pertenece el ingreso fijo.
  final int idUsuario;

  /// Monto del ingreso fijo.
  final double monto;

  /// Fecha desde la cual comienza a aplicar este monto.
  final String fechaInicio;

  const FixedIncomeHistoryModel({
    this.idIngresoFijo,
    required this.idUsuario,
    required this.monto,
    required this.fechaInicio,
  });

  /// Convierte el modelo en un mapa para SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id_ingreso_fijo': idIngresoFijo,
      'id_usuario': idUsuario,
      'monto': monto,
      'fecha_inicio': fechaInicio,
    };
  }

  /// Crea el modelo a partir de un registro de SQLite.
  factory FixedIncomeHistoryModel.fromMap(Map<String, dynamic> map) {
    return FixedIncomeHistoryModel(
      idIngresoFijo: map['id_ingreso_fijo'] as int?,
      idUsuario: map['id_usuario'] as int,
      monto: (map['monto'] as num).toDouble(),
      fechaInicio: map['fecha_inicio'] as String,
    );
  }
}
