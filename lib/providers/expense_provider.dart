// Permite notificar cambios a la interfaz
import 'package:flutter/material.dart';

// Modelo de gastos
import '../data/models/expense_model.dart';

// Servicio del módulo gastos
import '../data/services/expense_service.dart';

/// Provider encargado de administrar el estado
/// del módulo Gastos.
///
/// Es el intermediario entre la interfaz y la
/// lógica de negocio.
class ExpenseProvider extends ChangeNotifier {
  /// Servicio del módulo
  final ExpenseService _expenseService = ExpenseService();

  /// Lista de gastos del usuario
  List<ExpenseModel> _expenses = [];

  /// Indica si existe una operación en ejecución
  bool _isLoading = false;

  /// Mensaje de error para mostrar en pantalla
  String _errorMessage = '';

  /// Lectura pública de la lista
  List<ExpenseModel> get expenses => _expenses;

  /// Estado de carga
  bool get isLoading => _isLoading;

  /// Último mensaje de error
  String get errorMessage => _errorMessage;

  /// Registrar un nuevo gasto
  Future<bool> createExpense(ExpenseModel expense) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Aplica reglas de negocio
      await _expenseService.createExpense(expense);
      // Recarga la lista
      await loadExpenses(expense.idUsuario);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Obtener gastos del usuario
  Future<void> loadExpenses(int idUsuario) async {
    _expenses = await _expenseService.getExpensesByUser(idUsuario);
    notifyListeners();
  }

  /// Obtiene los gastos registrados dentro de un período.
  ///
  /// La fecha de inicio se incluye y la fecha de fin no se incluye.
  Future<List<ExpenseModel>> loadExpensesByPeriod(
    int idUsuario,
    String fechaInicio,
    String fechaFin,
  ) async {
    return await _expenseService.getExpensesByPeriod(
      idUsuario,
      fechaInicio,
      fechaFin,
    );
  }

  /// Actualizar gasto
  Future<bool> updateExpense(ExpenseModel expense) async {
    try {
      await _expenseService.updateExpense(expense);
      await loadExpenses(expense.idUsuario);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Eliminar gasto
  Future<void> deleteExpense(int idGasto, int idUsuario) async {
    await _expenseService.deleteExpense(idGasto);
    await loadExpenses(idUsuario);
  }

  /// Total gastado durante el período actual.
  ///
  /// Los gastos históricos permanecen almacenados en SQLite,
  /// pero solamente los gastos del mes actual participan
  /// en el cálculo del presupuesto.
  double get totalExpenses {
    final now = DateTime.now();

    double total = 0;

    for (final expense in _expenses) {
      final fecha = DateTime.parse(expense.fecha);

      final esPeriodoActual =
          fecha.year == now.year && fecha.month == now.month;

      if (esPeriodoActual) {
        total += expense.monto;
      }
    }

    return total;
  }
}
