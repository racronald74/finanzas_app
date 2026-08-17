import 'package:sqflite/sqflite.dart';

// Modelo del gasto
import '../models/expense_model.dart';

// Repositorio encargado de SQLite
import '../repositories/expense_repository.dart';

/// Servicio del módulo Gastos.
///
/// Aquí se implementan las reglas de negocio
/// antes de acceder a la base de datos.
class ExpenseService {
  /// Repositorio de gastos
  final ExpenseRepository _expenseRepository = ExpenseRepository();

  /// Registrar un nuevo gasto.
  ///
  /// Devuelve el ID generado por SQLite.
  Future<int> createExpense(
    ExpenseModel expense, {
    DatabaseExecutor? executor,
  }) async {
    // RN13: El nombre es obligatorio
    if (expense.nombre.trim().isEmpty) {
      throw Exception('Debe ingresar un nombre para el gasto');
    }

    // RN12: El monto debe ser mayor que cero
    if (expense.monto <= 0) {
      throw Exception('El monto debe ser mayor que cero');
    }

    return await _expenseRepository.insertExpense(expense, executor: executor);
  }

  /// Obtener gastos de un usuario
  Future<List<ExpenseModel>> getExpensesByUser(int idUsuario) async {
    return await _expenseRepository.getExpensesByUser(idUsuario);
  }

  /// Obtiene los gastos registrados dentro de un período.
  ///
  /// Recibe una fecha de inicio incluida y una fecha de fin no incluida.
  Future<List<ExpenseModel>> getExpensesByPeriod(
    int idUsuario,
    String fechaInicio,
    String fechaFin,
  ) async {
    return await _expenseRepository.getExpensesByPeriod(
      idUsuario,
      fechaInicio,
      fechaFin,
    );
  }

  /// Actualizar un gasto existente
  Future<void> updateExpense(ExpenseModel expense) async {
    // RN13
    if (expense.nombre.trim().isEmpty) {
      throw Exception('Debe ingresar un nombre para el gasto');
    }

    // RN12
    if (expense.monto <= 0) {
      throw Exception('El monto debe ser mayor que cero');
    }

    await _expenseRepository.updateExpense(expense);
  }

  /// Eliminar un gasto
  Future<void> deleteExpense(int idGasto) async {
    await _expenseRepository.deleteExpense(idGasto);
  }
}
