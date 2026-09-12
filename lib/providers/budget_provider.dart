import 'package:flutter/material.dart';

import '../data/models/budget_summary.dart';
import '../data/services/budget_service.dart';
import '../data/services/period_service.dart';

/// Provider encargado de administrar el estado del presupuesto.
class BudgetProvider extends ChangeNotifier {
  final BudgetService _budgetService = BudgetService();

  /// Servicio encargado de calcular los saldos entre períodos.
  final PeriodService _periodService = PeriodService();

  BudgetSummary _summary = const BudgetSummary(
    initialBalance: 0,
    fixedIncome: 0,
    additionalIncome: 0,
    totalIncome: 0,
    totalExpenses: 0,
    totalSavings: 0,
    availableBudget: 0,
    usedPercentage: 0,
    availablePercentage: 0,
  );

  BudgetSummary get summary => _summary;

  /// Calcula el saldo inicial del período actual.
  ///
  /// Utiliza la fecha de registro del usuario como
  /// inicio del historial financiero.
  Future<double> calculateInitialBalance({
    required int idUsuario,
    required DateTime currentPeriodStart,
    required double fixedIncome,
    required DateTime registrationDate,
  }) async {
    return await _periodService.calculateInitialBalance(
      idUsuario: idUsuario,
      currentPeriodStart: currentPeriodStart,
      fixedIncome: fixedIncome,
      registrationDate: registrationDate,
    );
  }

  /// Calcula el presupuesto correspondiente a un período específico.
  ///
  /// Permite consultar tanto el período actual como períodos históricos.
  /// El saldo inicial y el ingreso fijo se calculan de acuerdo con
  /// el período seleccionado.
  Future<BudgetSummary> calculateBudgetForPeriod({
    required int idUsuario,
    required DateTime periodStart,
    required double fixedIncome,
    required double additionalIncome,
    required double totalExpenses,
    required DateTime registrationDate,
  }) async {
    // Calcula el saldo acumulado hasta el inicio del período seleccionado.
    final initialBalance = await calculateInitialBalance(
      idUsuario: idUsuario,
      currentPeriodStart: periodStart,
      fixedIncome: fixedIncome,
      registrationDate: registrationDate,
    );

    // Calcula el resumen financiero utilizando las reglas de negocio existentes.
    return _budgetService.calculateBudget(
      initialBalance: initialBalance,
      fixedIncome: fixedIncome,
      additionalIncome: additionalIncome,
      totalExpenses: totalExpenses,
      totalSavings: 0,
    );
  }

  /// Obtiene el saldo con el que terminó el período anterior.
  ///
  /// Permite saber si realmente existe un período financiero anterior
  /// para evitar mostrar un saldo cuando el usuario está consultando
  /// su primer período.
  Future<PreviousPeriodBalance> getPreviousPeriodBalance({
    required int idUsuario,
    required DateTime selectedPeriodStart,
    required DateTime registrationDate,
    required double fixedIncome,
  }) async {
    return await _periodService.calculatePreviousPeriodBalance(
      idUsuario: idUsuario,
      selectedPeriodStart: selectedPeriodStart,
      registrationDate: registrationDate,
      fixedIncome: fixedIncome,
    );
  }

  void updateBudget({
    required double initialBalance,
    required double fixedIncome,
    required double additionalIncome,
    required double totalExpenses,
    required double totalSavings,
  }) {
    _summary = _budgetService.calculateBudget(
      initialBalance: initialBalance,
      fixedIncome: fixedIncome,
      additionalIncome: additionalIncome,
      totalExpenses: totalExpenses,
      totalSavings: totalSavings,
    );

    notifyListeners();
  }

  void refresh({
    required double initialBalance,
    required double fixedIncome,
    required double additionalIncome,
    required double totalExpenses,
    double totalSavings = 0,
  }) {
    updateBudget(
      initialBalance: initialBalance,
      fixedIncome: fixedIncome,
      additionalIncome: additionalIncome,
      totalExpenses: totalExpenses,
      totalSavings: totalSavings,
    );
  }
}
