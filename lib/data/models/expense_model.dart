/// Modelo que representa un gasto del usuario.
///
/// Su responsabilidad es transportar información entre
/// SQLite, Repositories, Services, Providers y Pantallas.
class ExpenseModel {
  /// Identificador del gasto
  final int? idGasto;

  /// Nombre del gasto
  final String nombre;

  /// Valor del gasto
  final double monto;

  /// Fecha del gasto en formato ISO (YYYY-MM-DD)
  final String fecha;

  /// Descripción del gasto
  final String descripcion;

  /// Categoría del gasto
  final int idCategoria;

  /// Identificador del usuario propietario del gasto
  final int idUsuario;

  /// Origen del gasto MANUAL OBLIGACION DEUDA
  final String origen;

  /// Fecha de creación del registro
  final String fechaRegistro;

  // Constructor con parámetros requeridos y opcionales
  const ExpenseModel({
    this.idGasto,
    required this.nombre,
    required this.monto,
    required this.fecha,
    required this.descripcion,
    required this.idCategoria,
    required this.idUsuario,
    required this.origen,
    required this.fechaRegistro,
  });

  /// Convierte el objeto en un Map para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id_gasto': idGasto,
      'nombre': nombre,
      'monto': monto,
      'fecha': fecha,
      'descripcion': descripcion,
      'id_categoria': idCategoria,
      'id_usuario': idUsuario,
      'origen': origen,
      'fecha_registro': fechaRegistro,
    };
  }

  /// Crea un ExpenseModel a partir de un Map obtenido de SQLite
  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      idGasto: map['id_gasto'],
      nombre: map['nombre'],
      monto: (map['monto'] as num).toDouble(),
      fecha: map['fecha'],
      descripcion: map['descripcion'] ?? '',
      idCategoria: map['id_categoria'],
      idUsuario: map['id_usuario'],
      origen: map['origen'],
      fechaRegistro: map['fecha_registro'],
    );
  }

  /// Crea una copia modificando únicamente
  /// los campos enviados como parámetro.
  ExpenseModel copyWith({
    int? idGasto,
    String? nombre,
    double? monto,
    String? fecha,
    String? descripcion,
    int? idCategoria,
    int? idUsuario,
    String? origen,
    String? fechaRegistro,
  }) {
    return ExpenseModel(
      idGasto: idGasto ?? this.idGasto,
      nombre: nombre ?? this.nombre,
      monto: monto ?? this.monto,
      fecha: fecha ?? this.fecha,
      descripcion: descripcion ?? this.descripcion,
      idCategoria: idCategoria ?? this.idCategoria,
      idUsuario: idUsuario ?? this.idUsuario,
      origen: origen ?? this.origen,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    );
  }
}
