/// Modelo que representa un ingreso financiero.
class IncomeModel {
  final int? idIngreso;
  final String descripcion;
  final double monto;
  final String fecha;
  final String tipo;
  final int idCategoria;
  final int idUsuario;

  IncomeModel({
    this.idIngreso,
    required this.descripcion,
    required this.monto,
    required this.fecha,
    required this.tipo,
    required this.idCategoria,
    required this.idUsuario,
  });

  /// Convierte el objeto a Map para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id_ingreso': idIngreso,
      'descripcion': descripcion,
      'monto': monto,
      'fecha': fecha,
      'tipo': tipo,
      'id_categoria': idCategoria,
      'id_usuario': idUsuario,
    };
  }

  /// Convierte un Map de SQLite a objeto
  factory IncomeModel.fromMap(Map<String, dynamic> map) {
    return IncomeModel(
      idIngreso: map['id_ingreso'],
      descripcion: map['descripcion'],
      monto: map['monto'],
      fecha: map['fecha'],
      tipo: map['tipo'],
      idCategoria: map['id_categoria'],
      idUsuario: map['id_usuario'],
    );
  }
}
