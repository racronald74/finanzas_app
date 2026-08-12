/// Modelo que representa una meta de ahorro.
class GoalModel {
  /// Identificador único de la meta.
  final int? id;

  /// Nombre de la meta.
  final String name;

  /// Categoría de la meta.
  final String category;

  /// Monto objetivo.
  final double targetAmount;

  /// Monto acumulado.
  final double savedAmount;

  /// Fecha límite de la meta.
  final DateTime deadline;

  /// Estado de la meta.
  final String status;

  /// Prioridad de la meta.
  final String priority;

  /// Indica si los recordatorios están activados.
  final bool reminderEnabled;

  /// Usuario propietario de la meta.
  final int userId;

  /// Fecha en que se completó la meta.
  final DateTime? completedAt;

  /// Fecha de registro.
  final DateTime? createdAt;

  const GoalModel({
    this.id,
    required this.name,
    required this.category,
    required this.targetAmount,
    this.savedAmount = 0,
    required this.deadline,
    this.status = 'Activa',
    this.priority = 'Media',
    this.reminderEnabled = false,
    required this.userId,
    this.completedAt,
    this.createdAt,
  });

  /// Compatibilidad con el resto del módulo de metas.
  int? get idMeta => id;

  String get nombre => name;

  double get montoObjetivo => targetAmount;

  double get montoAcumulado => savedAmount;

  DateTime get fechaLimite => deadline;

  int get idUsuario => userId;

  /// Convierte el modelo en un Map para SQLite.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id_meta': id,
      'nombre': name,
      'monto_objetivo': targetAmount,
      'monto_acumulado': savedAmount,
      'fecha_limite': deadline.toIso8601String().split('T').first,
      'estado': status,
      'id_usuario': userId,
      'fecha_registro': createdAt?.toIso8601String(),
      'prioridad': priority,
      'recordatorio': reminderEnabled ? 1 : 0,
      'categoria': category,
      'fecha_cumplimiento': completedAt?.toIso8601String().split('T').first,
    };

    map.removeWhere((_, value) => value == null);

    return map;
  }

  /// Crea un GoalModel a partir de un registro de SQLite.
  factory GoalModel.fromMap(Map<String, dynamic> map) {
    return GoalModel(
      id: map['id_meta'],
      name: map['nombre'] ?? '',
      category: map['categoria'] ?? '',
      targetAmount: (map['monto_objetivo'] as num).toDouble(),
      savedAmount: (map['monto_acumulado'] as num?)?.toDouble() ?? 0,
      deadline: DateTime.parse(map['fecha_limite']),
      status: map['estado'] ?? 'Activa',
      priority: map['prioridad'] ?? 'Media',
      reminderEnabled: map['recordatorio'] == 1 || map['recordatorio'] == true,
      userId: map['id_usuario'],
      completedAt: map['fecha_cumplimiento'] != null
          ? DateTime.tryParse(map['fecha_cumplimiento'])
          : null,
      createdAt: map['fecha_registro'] != null
          ? DateTime.tryParse(map['fecha_registro'])
          : null,
    );
  }
}
