import '../repositories/expense_repository.dart';
import '../repositories/income_repository.dart';
import '../../shared/utils/period_utils.dart';
import '../repositories/fixed_income_history_repository.dart';

/// Resultado del cálculo del saldo anterior.
///
/// Permite distinguir entre un saldo real de $0
/// y la ausencia de un período financiero anterior.
class PreviousPeriodBalance {
  final double amount;
  final bool hasPreviousPeriod;

  const PreviousPeriodBalance({
    required this.amount,
    required this.hasPreviousPeriod,
  });
}

/// Servicio encargado de calcular los valores financieros
/// relacionados con los períodos mensuales.
class PeriodService {
  /// Repositorio de ingresos.
  final IncomeRepository _incomeRepository = IncomeRepository();

  /// Repositorio de gastos.
  final ExpenseRepository _expenseRepository = ExpenseRepository();

  /// Repositorio del historial de ingresos fijos.
  final FixedIncomeHistoryRepository _fixedIncomeHistoryRepository =
      FixedIncomeHistoryRepository();

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

    // Si se consulta un período anterior al registro del usuario,
    // no existe saldo financiero para ese período.
    if (currentPeriodStart.isBefore(firstPeriodStart)) {
      return 0;
    }

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

      final fixedIncomeHistory = await _fixedIncomeHistoryRepository
          .getByPeriod(idUsuario: idUsuario, periodStart: periodStart);

      final periodFixedIncome = fixedIncomeHistory?.monto ?? fixedIncome;

      accumulatedBalance +=
          periodFixedIncome + additionalIncome - totalExpenses;

      periodStart = periodEnd;
    }

    return accumulatedBalance;
  }

  /// Calcula el saldo con el que terminó el período anterior.
  ///
  /// Si no existe un período financiero anterior al período seleccionado,
  /// devuelve hasPreviousPeriod = false.
  Future<PreviousPeriodBalance> calculatePreviousPeriodBalance({
    required int idUsuario,
    required DateTime selectedPeriodStart,
    required DateTime registrationDate,
    required double fixedIncome,
  }) async {
    final firstPeriodStart = PeriodUtils.startOfMonth(registrationDate);

    // Si el período seleccionado es el primer período financiero
    // del usuario, no existe un período anterior.
    if (!selectedPeriodStart.isAfter(firstPeriodStart)) {
      return const PreviousPeriodBalance(amount: 0, hasPreviousPeriod: false);
    }

    // Calcula el saldo acumulado hasta el inicio del período seleccionado.
    final amount = await calculateInitialBalance(
      idUsuario: idUsuario,
      currentPeriodStart: selectedPeriodStart,
      fixedIncome: fixedIncome,
      registrationDate: registrationDate,
    );

    return PreviousPeriodBalance(amount: amount, hasPreviousPeriod: true);
  }
}
