/// Modelo que representa una notificación almacenada en SQLite.
class NotificationModel {
  final int? idNotificacion;
  final String tipo;
  final String mensaje;
  final String fecha;
  final bool leida;
  final int idUsuario;
  final String? fechaLectura;

  // Identificador de la meta, deuda u obligación que origina la notificación.
  final int? idEventoOrigen;

  // Fecha del evento que origina la notificación, por ejemplo, el vencimiento.
  final String? fechaEvento;

  NotificationModel({
    this.idNotificacion,
    required this.tipo,
    required this.mensaje,
    required this.fecha,
    this.leida = false,
    required this.idUsuario,
    this.fechaLectura,
    this.idEventoOrigen,
    this.fechaEvento,
  });

  /// Convierte la notificación en un mapa para SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id_notificacion': idNotificacion,
      'tipo': tipo,
      'mensaje': mensaje,
      'fecha': fecha,
      'leida': leida ? 1 : 0,
      'id_usuario': idUsuario,
      'fecha_lectura': fechaLectura,
      'id_evento_origen': idEventoOrigen,
      'fecha_evento': fechaEvento,
    };
  }

  /// Construye una notificación a partir de un registro SQLite.
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      idNotificacion: map['id_notificacion'] as int?,
      tipo: map['tipo'] as String,
      mensaje: map['mensaje'] as String,
      fecha: map['fecha'] as String,
      leida: map['leida'] == 1 || map['leida'] == true,
      idUsuario: map['id_usuario'] as int,
      fechaLectura: map['fecha_lectura'] as String?,
      idEventoOrigen: map['id_evento_origen'] as int?,
      fechaEvento: map['fecha_evento'] as String?,
    );
  }

  /// Crea una copia permitiendo modificar campos específicos.
  NotificationModel copyWith({
    int? idNotificacion,
    String? tipo,
    String? mensaje,
    String? fecha,
    bool? leida,
    int? idUsuario,
    String? fechaLectura,
    int? idEventoOrigen,
    String? fechaEvento,
  }) {
    return NotificationModel(
      idNotificacion: idNotificacion ?? this.idNotificacion,
      tipo: tipo ?? this.tipo,
      mensaje: mensaje ?? this.mensaje,
      fecha: fecha ?? this.fecha,
      leida: leida ?? this.leida,
      idUsuario: idUsuario ?? this.idUsuario,
      fechaLectura: fechaLectura ?? this.fechaLectura,
      idEventoOrigen: idEventoOrigen ?? this.idEventoOrigen,
      fechaEvento: fechaEvento ?? this.fechaEvento,
    );
  }
}
