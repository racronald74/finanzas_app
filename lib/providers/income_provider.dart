import 'package:flutter/material.dart';

import '../data/models/income_model.dart';
import '../data/services/income_service.dart';

/// Proveedor de ingresos
class IncomeProvider extends ChangeNotifier {
  final IncomeService _incomeService = IncomeService();

  List<IncomeModel> _incomes = [];

  bool _isLoading = false;

  List<IncomeModel> get incomes => _incomes;

  bool get isLoading => _isLoading;

  /// Crear ingreso
  Future<void> createIncome(IncomeModel income) async {
    _isLoading = true;

    notifyListeners();

    await _incomeService.createIncome(income);

    await loadIncomes(income.idUsuario);

    _isLoading = false;

    notifyListeners();
  }

  /// Cargar ingresos de un usuario
  Future<void> loadIncomes(int idUsuario) async {
    _incomes = await _incomeService.getIncomesByUser(idUsuario);

    notifyListeners();
  }

  IncomeModel? _fixedIncome;

  List<IncomeModel> _additionalIncomes = [];

  IncomeModel? get fixedIncome => _fixedIncome;

  List<IncomeModel> get additionalIncomes => _additionalIncomes;

  /// Cargar información de ingresos
  Future<void> loadIncomeData(int idUsuario) async {
    _isLoading = true;

    notifyListeners();

    _fixedIncome = await _incomeService.getFixedIncome(idUsuario);

    _additionalIncomes = await _incomeService.getAdditionalIncomes(idUsuario);

    _isLoading = false;

    notifyListeners();
  }

  /// Total de ingresos del usuario
  double get totalIncome {
    double total = 0;

    if (_fixedIncome != null) {
      total += _fixedIncome!.monto;
    }

    for (final income in _additionalIncomes) {
      total += income.monto;
    }

    return total;
  }
}
