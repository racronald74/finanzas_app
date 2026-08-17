import '../repositories/expense_repository.dart';
import '../repositories/income_repository.dart';
import '../../shared/utils/period_utils.dart';

/// Servicio encargado de calcular los valores financieros
/// relacionados con los períodos mensuales.
class PeriodService {
  /// Repositorio de ingresos.
  final IncomeRepository _incomeRepository = IncomeRepository();

  /// Repositorio de gastos.
  final ExpenseRepository _expenseRepository = ExpenseRepository();

  /// Calcula el saldo acumulado antes del período actual.
  ///
  /// El saldo inicial del primer período es cero.
  /// Para períodos posteriores se acumulan los ingresos y gastos
  /// registrados en los períodos anteriores.
  Future<double> calculateInitialBalance({
    required int idUsuario,
    required DateTime currentPeriodStart,
    required double fixedIncome,
    required DateTime registrationDate,
  }) async {
    /// Determina el primer período financiero a partir
    /// de la fecha en que se registró el usuario.
    final firstPeriodStart = PeriodUtils.startOfMonth(registrationDate);

    double accumulatedBalance = 0;

    DateTime periodStart = firstPeriodStart;

    while (periodStart.isBefore(currentPeriodStart)) {
      final periodEnd = PeriodUtils.startOfNextMonth(periodStart);

      final fechaInicio = PeriodUtils.toDateString(periodStart);
      final fechaFin = PeriodUtils.toDateString(periodEnd);

      final incomes = await _incomeRepository.getIncomesByPeriod(
        idUsuario,
        fechaInicio,
        fechaFin,
      );

      final expenses = await _expenseRepository.getExpensesByPeriod(
        idUsuario,
        fechaInicio,
        fechaFin,
      );

      double additionalIncome = 0;

      for (final income in incomes) {
        if (income.tipo == 'ADICIONAL') {
          additionalIncome += income.monto;
        }
      }

      double totalExpenses = 0;

      for (final expense in expenses) {
        totalExpenses += expense.monto;
      }

      accumulatedBalance += fixedIncome + additionalIncome - totalExpenses;

      periodStart = periodEnd;
    }

    return accumulatedBalance;
  }
}
