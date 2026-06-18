/// Modelo que representa un ingreso financiero.
class IncomeModel {
  final int? idIngreso;
  final String descripcion;
  final double monto;
  final String fecha;
  final String tipo;
  final String? fuente;
  final String origen;
  final int? idCategoria;
  final int idUsuario;
  final String? fechaRegistro;

  IncomeModel({
    this.idIngreso,
    required this.descripcion,
    required this.monto,
    required this.fecha,
    required this.tipo,
    this.fuente,
    this.origen = 'Manual',
    required this.idCategoria,
    required this.idUsuario,
    this.fechaRegistro,
  });

  /// Convierte el objeto a Map para SQLite
  Map<String, dynamic> toMap() {
    final map = {
      'id_ingreso': idIngreso,
      'descripcion': descripcion,
      'monto': monto,
      'fecha': fecha,
      'tipo': tipo,
      'fuente': fuente,
      'origen': origen,
      'id_categoria': idCategoria,
      'id_usuario': idUsuario,
      'fecha_registro': fechaRegistro,
    };

    map.removeWhere((_, value) => value == null);

    return map;
  }

  /// Convierte un Map de SQLite a objeto
  factory IncomeModel.fromMap(Map<String, dynamic> map) {
    return IncomeModel(
      idIngreso: map['id_ingreso'],
      descripcion: map['descripcion'] ?? '',
      monto: (map['monto'] as num).toDouble(),
      fecha: map['fecha'],
      tipo: map['tipo'] ?? 'ADICIONAL',
      fuente: map['fuente'],
      origen: map['origen'] ?? 'Manual',
      idCategoria: map['id_categoria'],
      idUsuario: map['id_usuario'],
      fechaRegistro: map['fecha_registro'],
    );
  }
}
