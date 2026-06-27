/// Modelo que representa el resumen financiero del usuario.
///
/// Centraliza todos los indicadores utilizados por el
/// Dashboard, Gastos, Reportes y demás módulos.
class BudgetSummary {
  /// Ingreso fijo mensual.
  final double fixedIncome;

  /// Total de ingresos adicionales.
  final double additionalIncome;

  /// Total de ingresos.
  final double totalIncome;

  /// Total de gastos.
  final double totalExpenses;

  /// Total aportado a metas.
  final double totalSavings;

  /// Presupuesto disponible.
  final double availableBudget;

  /// Porcentaje utilizado.
  final double usedPercentage;

  /// Porcentaje disponible.
  final double availablePercentage;

  const BudgetSummary({
    required this.fixedIncome,
    required this.additionalIncome,
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalSavings,
    required this.availableBudget,
    required this.usedPercentage,
    required this.availablePercentage,
  });
}
