class UserModel {
  final int? idUsuario;
  final String nombre;
  final String correo;
  final String contrasena;
  final String fechaRegistro;

  UserModel({
    this.idUsuario,
    required this.nombre,
    required this.correo,
    required this.contrasena,
    required this.fechaRegistro,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_usuario': idUsuario,
      'nombre': nombre,
      'correo': correo,
      'contrasena': contrasena,
      'fecha_registro': fechaRegistro,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      idUsuario: map['id_usuario'],
      nombre: map['nombre'],
      correo: map['correo'],
      contrasena: map['contrasena'],
      fechaRegistro: map['fecha_registro'],
    );
  }

  /// Crea una copia del usuario modificando únicamente
  /// los campos enviados como parámetro.
  UserModel copyWith({
    int? idUsuario,
    String? nombre,
    String? correo,
    String? contrasena,
    String? fechaRegistro,
  }) {
    return UserModel(
      idUsuario: idUsuario ?? this.idUsuario,
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      contrasena: contrasena ?? this.contrasena,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    );
  }
}
