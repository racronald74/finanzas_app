import 'package:flutter/material.dart';

import '../data/models/budget_summary.dart';
import '../data/services/budget_service.dart';

/// Provider encargado de administrar el estado del presupuesto.
class BudgetProvider extends ChangeNotifier {
  final BudgetService _budgetService = BudgetService();

  BudgetSummary _summary = const BudgetSummary(
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

  void updateBudget({
    required double fixedIncome,
    required double additionalIncome,
    required double totalExpenses,
    required double totalSavings,
  }) {
    _summary = _budgetService.calculateBudget(
      fixedIncome: fixedIncome,
      additionalIncome: additionalIncome,
      totalExpenses: totalExpenses,
      totalSavings: totalSavings,
    );

    notifyListeners();
  }

  void refresh({
    required double fixedIncome,
    required double additionalIncome,
    required double totalExpenses,
    double totalSavings = 0,
  }) {
    updateBudget(
      fixedIncome: fixedIncome,
      additionalIncome: additionalIncome,
      totalExpenses: totalExpenses,
      totalSavings: totalSavings,
    );
  }
}
