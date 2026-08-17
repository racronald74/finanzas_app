// Permite utilizar la base de datos SQLite
import 'package:sqflite/sqflite.dart';

// Helper que administra la conexión a la base de datos
import '../database/database_helper.dart';

// Modelo de gastos
import '../models/expense_model.dart';

/// Repositorio encargado de todas las operaciones
/// sobre la tabla gasto.
///
/// Esta clase es la única que accede directamente
/// a SQLite.
class ExpenseRepository {
  /// Instancia del helper de base de datos
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  /// Inserta un nuevo gasto
  Future<int> insertExpense(
    ExpenseModel expense, {
    DatabaseExecutor? executor,
  }) async {
    final DatabaseExecutor db = executor ?? await _databaseHelper.database;

    return await db.insert('gasto', expense.toMap());
  }

  /// Obtiene todos los gastos de un usuario
  /// ordenados desde el más reciente.
  Future<List<ExpenseModel>> getExpensesByUser(int idUsuario) async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> result = await db.query(
      'gasto',
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
      orderBy: 'fecha DESC',
    );
    return result.map((item) => ExpenseModel.fromMap(item)).toList();
  }

  /// Actualiza un gasto existente
  Future<int> updateExpense(ExpenseModel expense) async {
    final Database db = await _databaseHelper.database;

    return await db.update(
      'gasto',
      expense.toMap(),
      where: 'id_gasto = ?',
      whereArgs: [expense.idGasto],
    );
  }

  /// Elimina un gasto
  Future<int> deleteExpense(int idGasto) async {
    final Database db = await _databaseHelper.database;
    return await db.delete(
      'gasto',
      where: 'id_gasto = ?',
      whereArgs: [idGasto],
    );
  }

  /// Obtiene los gastos registrados dentro de un período.
  ///
  /// El período se define mediante una fecha de inicio
  /// incluida y una fecha de fin no incluida.
  Future<List<ExpenseModel>> getExpensesByPeriod(
    int idUsuario,
    String fechaInicio,
    String fechaFin,
  ) async {
    final Database db = await _databaseHelper.database;

    final result = await db.query(
      'gasto',
      where: 'id_usuario = ? AND fecha >= ? AND fecha < ?',
      whereArgs: [idUsuario, fechaInicio, fechaFin],
      orderBy: 'fecha DESC',
    );

    return result.map((item) => ExpenseModel.fromMap(item)).toList();
  }
}
