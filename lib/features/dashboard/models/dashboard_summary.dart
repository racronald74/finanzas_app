import '../../../data/models/debt_model.dart';
import '../../../data/models/obligation_model.dart';

/// Representa un movimiento financiero reciente del Dashboard.
class DashboardMovement {
  final String title;
  final double amount;
  final String date;
  final bool isIncome;

  const DashboardMovement({
    required this.title,
    required this.amount,
    required this.date,
    required this.isIncome,
  });
}

/// Agrupa la información financiera que presenta el Dashboard.
class DashboardSummary {
  final double availableBalance;
  final double monthlyIncome;
  final double monthlyExpenses;
  final double goalSavings;

  final List<DashboardMovement> recentMovements;
  final List<ObligationModel> upcomingObligations;
  final List<DebtModel> pendingDebts;

  const DashboardSummary({
    required this.availableBalance,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.goalSavings,
    required this.recentMovements,
    required this.upcomingObligations,
    required this.pendingDebts,
  });

  /// Devuelve un resumen vacío mientras se cargan los datos.
  factory DashboardSummary.empty() {
    return const DashboardSummary(
      availableBalance: 0,
      monthlyIncome: 0,
      monthlyExpenses: 0,
      goalSavings: 0,
      recentMovements: [],
      upcomingObligations: [],
      pendingDebts: [],
    );
  }
}
