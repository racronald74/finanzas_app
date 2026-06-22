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
  Future<int> insertExpense(ExpenseModel expense) async {
    // Obtiene la conexión SQLite
    final Database db = await _databaseHelper.database;

    // Inserta el registro y devuelve el id generado
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
}
