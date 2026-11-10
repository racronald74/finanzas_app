import 'package:flutter/material.dart';

import '../../../data/models/budget_summary.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/income_model.dart';
import '../../../shared/utils/period_utils.dart';

import '../../../providers/budget_provider.dart';
import '../../../providers/income_provider.dart';
import '../../../providers/expense_provider.dart';
import '../../../providers/goal_provider.dart';
import '../../../providers/obligation_provider.dart';
import '../../../providers/debt_provider.dart';

import '../models/dashboard_summary.dart';

/// Provider encargado de reunir la información del Dashboard.
class DashboardProvider extends ChangeNotifier {
  // Resumen financiero presentado en la pantalla principal.
  DashboardSummary _summary = DashboardSummary.empty();

  // Estado de carga de la información.
  bool _isLoading = false;

  // Mensaje de error de la última consulta.
  String? _errorMessage;

  DashboardSummary get summary => _summary;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  /// Consulta y consolida la información financiera del usuario.
  Future<void> loadDashboard({
    required int idUsuario,
    required DateTime registrationDate,
    required double fixedIncome,
    required BudgetProvider budgetProvider,
    required IncomeProvider incomeProvider,
    required ExpenseProvider expenseProvider,
    required GoalProvider goalProvider,
    required ObligationProvider obligationProvider,
    required DebtProvider debtProvider,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Define el período mensual actual.
      final now = DateTime.now();
      final periodStart = PeriodUtils.startOfMonth(now);
      final periodEnd = PeriodUtils.startOfNextMonth(periodStart);

      final fechaInicio = PeriodUtils.toDateString(periodStart);
      final fechaFin = PeriodUtils.toDateString(periodEnd);

      // Obtiene el ingreso fijo y los ingresos adicionales.
      await incomeProvider.loadIncomeData(idUsuario);

      final currentFixedIncome =
          incomeProvider.fixedIncome?.monto ?? fixedIncome;

      // Consulta los ingresos y gastos del mes actual.
      final incomes = await incomeProvider.loadIncomesByPeriod(
        idUsuario,
        fechaInicio,
        fechaFin,
      );

      final expenses = await expenseProvider.loadExpensesByPeriod(
        idUsuario,
        fechaInicio,
        fechaFin,
      );

      // Calcula los ingresos adicionales del período.
      final additionalIncome = _calculateAdditionalIncome(incomes);

      // Suma todos los gastos, incluidos pagos de deudas y obligaciones.
      final totalExpenses = _calculateTotalExpenses(expenses);

      // Calcula el presupuesto respetando las reglas existentes.
      final BudgetSummary budget = await budgetProvider
          .calculateBudgetForPeriod(
            idUsuario: idUsuario,
            periodStart: periodStart,
            fixedIncome: currentFixedIncome,
            additionalIncome: additionalIncome,
            totalExpenses: totalExpenses,
            registrationDate: registrationDate,
          );

      // Carga el ahorro acumulado de las metas.
      await goalProvider.loadGoals(idUsuario);

      // Carga las obligaciones y deudas pendientes.
      await obligationProvider.loadObligations(idUsuario);
      await debtProvider.loadDebts(idUsuario);

      // Prepara los movimientos recientes del período actual.
      final recentMovements = _buildRecentMovements(
        incomes: incomes,
        expenses: expenses,
      );

      // Obtiene las obligaciones pendientes ordenadas por vencimiento.
      final upcomingObligations = obligationProvider.pendingObligations.toList()
        ..sort((a, b) {
          return DateTime.parse(
            a.fechaVencimiento,
          ).compareTo(DateTime.parse(b.fechaVencimiento));
        });

      // Obtiene las deudas que todavía tienen saldo pendiente.
      final pendingDebts = debtProvider.debts
          .where((debt) => debt.saldoPendiente > 0)
          .toList();

      // Actualiza el resumen que consumirá la pantalla.
      _summary = DashboardSummary(
        availableBalance: budget.availableBudget,
        monthlyIncome: budget.totalIncome,
        monthlyExpenses: budget.totalExpenses,
        goalSavings: goalProvider.totalSavings,
        recentMovements: recentMovements,
        upcomingObligations: upcomingObligations,
        pendingDebts: pendingDebts,
      );
    } catch (error) {
      // Conserva el mensaje para facilitar el diagnóstico.
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Suma únicamente los ingresos adicionales del período.
  double _calculateAdditionalIncome(List<IncomeModel> incomes) {
    double total = 0;

    for (final income in incomes) {
      if (income.tipo == 'ADICIONAL') {
        total += income.monto;
      }
    }

    return total;
  }

  /// Suma todos los gastos registrados en el período.
  double _calculateTotalExpenses(List<ExpenseModel> expenses) {
    double total = 0;

    for (final expense in expenses) {
      total += expense.monto;
    }

    return total;
  }

  /// Combina ingresos y gastos para obtener los movimientos recientes.
  List<DashboardMovement> _buildRecentMovements({
    required List<IncomeModel> incomes,
    required List<ExpenseModel> expenses,
  }) {
    final movements = <DashboardMovement>[];

    // Incorpora los ingresos del período.
    for (final income in incomes) {
      movements.add(
        DashboardMovement(
          title: income.descripcion,
          amount: income.monto,
          date: income.fecha,
          isIncome: true,
        ),
      );
    }

    // Incorpora los gastos del período.
    for (final expense in expenses) {
      movements.add(
        DashboardMovement(
          title: expense.nombre,
          amount: expense.monto,
          date: expense.fecha,
          isIncome: false,
        ),
      );
    }

    // Ordena los movimientos desde el más reciente.
    movements.sort((a, b) {
      return DateTime.parse(b.date).compareTo(DateTime.parse(a.date));
    });

    // Devuelve como máximo cinco movimientos.
    return movements.take(5).toList();
  }
}
