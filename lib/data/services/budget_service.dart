import '../models/budget_summary.dart';

/// Servicio encargado de calcular los indicadores financieros.
///
/// No consulta SQLite.
/// Solo aplica reglas de negocio.
class BudgetService {
  BudgetSummary calculateBudget({
    required double initialBalance,
    required double fixedIncome,
    required double additionalIncome,
    required double totalExpenses,
    required double totalSavings,
  }) {
    final totalIncome = fixedIncome + additionalIncome;

    final totalBudget = initialBalance + totalIncome;

    final availableBudget =
        initialBalance + totalIncome - totalExpenses - totalSavings;

    double usedPercentage = 0;
    double availablePercentage = 0;

    if (totalBudget > 0) {
      usedPercentage = totalExpenses / totalBudget;

      if (usedPercentage > 1) {
        usedPercentage = 1;
      }

      availablePercentage = availableBudget / totalBudget;

      if (availablePercentage < 0) {
        availablePercentage = 0;
      }

      if (availablePercentage > 1) {
        availablePercentage = 1;
      }
    }

    return BudgetSummary(
      initialBalance: initialBalance,
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
