class UserModel {
  final int? idUsuario;
  final String nombre;
  final String correo;
  final String contrasena;
  final double ingresoFijoMensual;
  final String fechaRegistro;

  // Preferencia general para habilitar o deshabilitar notificaciones.
  final bool notificacionesActivas;

  // Preferencias individuales por tipo de notificación.
  final bool notificacionesMetas;
  final bool notificacionesDeudas;
  final bool notificacionesObligaciones;

  UserModel({
    this.idUsuario,
    required this.nombre,
    required this.correo,
    required this.contrasena,
    required this.ingresoFijoMensual,
    required this.fechaRegistro,
    this.notificacionesActivas = true,
    this.notificacionesMetas = true,
    this.notificacionesDeudas = true,
    this.notificacionesObligaciones = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_usuario': idUsuario,
      'nombre': nombre,
      'correo': correo,
      'contrasena': contrasena,
      'ingreso_fijo_mensual': ingresoFijoMensual,
      'fecha_registro': fechaRegistro,
      'notificaciones_activas': notificacionesActivas ? 1 : 0,
      'notificaciones_metas': notificacionesMetas ? 1 : 0,
      'notificaciones_deudas': notificacionesDeudas ? 1 : 0,
      'notificaciones_obligaciones': notificacionesObligaciones ? 1 : 0,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      idUsuario: map['id_usuario'],
      nombre: map['nombre'],
      correo: map['correo'],
      contrasena: map['contrasena'],
      ingresoFijoMensual: (map['ingreso_fijo_mensual'] ?? 0).toDouble(),
      fechaRegistro: map['fecha_registro'],

      // Convierte los valores de SQLite a booleanos.
      notificacionesActivas:
          map['notificaciones_activas'] == 1 ||
          map['notificaciones_activas'] == true,
      notificacionesMetas:
          map['notificaciones_metas'] == 1 ||
          map['notificaciones_metas'] == true,
      notificacionesDeudas:
          map['notificaciones_deudas'] == 1 ||
          map['notificaciones_deudas'] == true,
      notificacionesObligaciones:
          map['notificaciones_obligaciones'] == 1 ||
          map['notificaciones_obligaciones'] == true,
    );
  }

  /// Crea una copia del usuario modificando únicamente
  /// los campos enviados como parámetro.
  UserModel copyWith({
    int? idUsuario,
    String? nombre,
    String? correo,
    String? contrasena,
    double? ingresoFijoMensual,
    String? fechaRegistro,
    bool? notificacionesActivas,
    bool? notificacionesMetas,
    bool? notificacionesDeudas,
    bool? notificacionesObligaciones,
  }) {
    return UserModel(
      idUsuario: idUsuario ?? this.idUsuario,
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      contrasena: contrasena ?? this.contrasena,
      ingresoFijoMensual: ingresoFijoMensual ?? this.ingresoFijoMensual,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      notificacionesActivas:
          notificacionesActivas ?? this.notificacionesActivas,
      notificacionesMetas: notificacionesMetas ?? this.notificacionesMetas,
      notificacionesDeudas: notificacionesDeudas ?? this.notificacionesDeudas,
      notificacionesObligaciones:
          notificacionesObligaciones ?? this.notificacionesObligaciones,
    );
  }
}
