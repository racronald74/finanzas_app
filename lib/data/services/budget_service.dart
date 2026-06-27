import '../models/budget_summary.dart';

/// Servicio encargado de calcular los indicadores financieros.
///
/// No consulta SQLite.
/// Solo aplica reglas de negocio.
class BudgetService {
  BudgetSummary calculateBudget({
    required double fixedIncome,
    required double additionalIncome,
    required double totalExpenses,
    required double totalSavings,
  }) {
    final totalIncome = fixedIncome + additionalIncome;

    final availableBudget = totalIncome - totalExpenses - totalSavings;

    double usedPercentage = 0;
    double availablePercentage = 0;

    if (totalIncome > 0) {
      usedPercentage = totalExpenses / totalIncome;

      if (usedPercentage > 1) {
        usedPercentage = 1;
      }

      availablePercentage = availableBudget / totalIncome;

      if (availablePercentage < 0) {
        availablePercentage = 0;
      }

      if (availablePercentage > 1) {
        availablePercentage = 1;
      }
    }

    return BudgetSummary(
      fixedIncome: fixedIncome,
      additionalIncome: additionalIncome,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      totalSavings: totalSavings,
      availableBudget: availableBudget,
      usedPercentage: usedPercentage,
      availablePercentage: availablePercentage,
    );
  }
}
