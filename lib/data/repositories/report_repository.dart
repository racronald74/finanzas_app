import '../models/income_model.dart';
import '../models/expense_model.dart';
import '../models/fixed_income_history_model.dart';
import '../models/category_model.dart';

import 'income_repository.dart';
import 'expense_repository.dart';
import 'fixed_income_history_repository.dart';
import 'category_repository.dart';

/// Repositorio encargado de obtener los datos necesarios
/// para generar los reportes financieros.
class ReportRepository {
  // Repositorios existentes de la aplicación.
  final IncomeRepository _incomeRepository = IncomeRepository();
  final ExpenseRepository _expenseRepository = ExpenseRepository();
  final FixedIncomeHistoryRepository _fixedIncomeRepository =
      FixedIncomeHistoryRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();

  /// Obtiene los ingresos registrados durante un período.
  Future<List<IncomeModel>> getIncomesByPeriod({
    required int idUsuario,
    required String fechaInicio,
    required String fechaFin,
  }) {
    return _incomeRepository.getIncomesByPeriod(
      idUsuario,
      fechaInicio,
      fechaFin,
    );
  }

  /// Obtiene los gastos registrados durante un período.
  Future<List<ExpenseModel>> getExpensesByPeriod({
    required int idUsuario,
    required String fechaInicio,
    required String fechaFin,
  }) {
    return _expenseRepository.getExpensesByPeriod(
      idUsuario,
      fechaInicio,
      fechaFin,
    );
  }

  /// Obtiene el ingreso fijo correspondiente al período.
  Future<FixedIncomeHistoryModel?> getFixedIncomeByPeriod({
    required int idUsuario,
    required DateTime periodStart,
  }) {
    return _fixedIncomeRepository.getByPeriod(
      idUsuario: idUsuario,
      periodStart: periodStart,
    );
  }

  /// Obtiene las categorías registradas en la aplicación.
  Future<List<CategoryModel>> getCategories() {
    return _categoryRepository.getCategories();
  }
}
