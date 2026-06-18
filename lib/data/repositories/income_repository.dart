import '../database/database_helper.dart';
import '../models/income_model.dart';

// Repositorio para manejar operaciones relacionadas con ingresos
class IncomeRepository {
  /// Inserta un ingreso
  Future<int> insertIncome(IncomeModel income) async {
    final db = await DatabaseHelper.instance.database;

    return await db.insert('ingreso', income.toMap());
  }

  Future<int> updateIncome(IncomeModel income) async {
    final db = await DatabaseHelper.instance.database;

    return db.update(
      'ingreso',
      income.toMap(),
      where: 'id_ingreso = ? AND id_usuario = ?',
      whereArgs: [income.idIngreso, income.idUsuario],
    );
  }

  Future<int> deleteIncome({
    required int idIngreso,
    required int idUsuario,
  }) async {
    final db = await DatabaseHelper.instance.database;

    return db.delete(
      'ingreso',
      where: 'id_ingreso = ? AND id_usuario = ?',
      whereArgs: [idIngreso, idUsuario],
    );
  }

  /// Obtener ingresos de un usuario
  Future<List<IncomeModel>> getIncomesByUser(int idUsuario) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      'ingreso',

      where: 'id_usuario = ?',

      whereArgs: [idUsuario],

      orderBy: 'fecha DESC',
    );

    return result.map((e) => IncomeModel.fromMap(e)).toList();
  }

  /// Obtener ingreso fijo mensual
  Future<IncomeModel?> getFixedIncome(int idUsuario) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      'ingreso',

      where: 'id_usuario = ? AND tipo = ?',

      whereArgs: [idUsuario, 'FIJO'],

      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return IncomeModel.fromMap(result.first);
  }

  /// Obtener ingresos adicionales
  Future<List<IncomeModel>> getAdditionalIncomes(int idUsuario) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      'ingreso',

      where: 'id_usuario = ? AND tipo = ?',

      whereArgs: [idUsuario, 'ADICIONAL'],

      orderBy: 'fecha DESC',
    );

    return result.map((e) => IncomeModel.fromMap(e)).toList();
  }
}
