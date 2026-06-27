import 'package:flutter/material.dart';

import '../data/models/income_model.dart';
import '../data/services/income_service.dart';

/// Proveedor de ingresos
class IncomeProvider extends ChangeNotifier {
  final IncomeService _incomeService = IncomeService();

  List<IncomeModel> _incomes = [];

  bool _isLoading = false;

  String? _errorMessage;

  List<IncomeModel> get incomes => _incomes;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  /// Crear ingreso
  Future<bool> createIncome(IncomeModel income) async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      await _incomeService.createIncome(income);

      await loadIncomeData(income.idUsuario);

      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  Future<bool> updateIncome(IncomeModel income) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _incomeService.updateIncome(income);
      await loadIncomeData(income.idUsuario);
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteIncome(IncomeModel income) async {
    if (income.idIngreso == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _incomeService.deleteIncome(
        idIngreso: income.idIngreso!,
        idUsuario: income.idUsuario,
      );
      await loadIncomeData(income.idUsuario);
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

  /// Total de ingresos adicionales del usuario.
  double get totalIncome {
    double total = 0;

    for (final income in _additionalIncomes) {
      total += income.monto;
    }

    return total;
  }

  /// Total utilizado para el cálculo del presupuesto.
  ///
  /// Corresponde al ingreso fijo mensual más
  /// todos los ingresos adicionales registrados.
  double get totalBudgetIncome {
    double total = totalIncome;

    if (_fixedIncome != null) {
      total += _fixedIncome!.monto;
    }

    return total;
  }
}
