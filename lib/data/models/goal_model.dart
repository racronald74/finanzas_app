/// Modelo que representa una meta de ahorro.
///
/// Contiene la información necesaria para almacenar,
/// consultar y actualizar una meta dentro de la aplicación.
class GoalModel {
  /// Identificador único de la meta.
  final int? id;

  /// Nombre de la meta.
  final String name;

  /// Categoría de la meta.
  final String category;

  /// Descripción de la meta.
  final String? description;

  /// Valor objetivo que se desea alcanzar.
  final double targetAmount;

  /// Valor ahorrado hasta el momento.
  final double savedAmount;

  /// Fecha límite de la meta.
  final DateTime deadline;

  /// Estado actual de la meta.
  final String status;

  /// Constructor del modelo.
  const GoalModel({
    this.id,
    required this.name,
    required this.category,
    this.description,
    required this.targetAmount,
    required this.savedAmount,
    required this.deadline,
    this.status = 'Activa',
  });
}
