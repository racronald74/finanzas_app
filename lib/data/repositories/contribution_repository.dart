import '../database/database_helper.dart';
import '../models/contribution_model.dart';

/// Repositorio encargado de manejar las operaciones
/// relacionadas con los aportes en SQLite.
class ContributionRepository {
  /// Registra un nuevo aporte.
  Future<int> insertContribution(ContributionModel contribution) async {
    final db = await DatabaseHelper.instance.database;

    return await db.insert('aporte', contribution.toMap());
  }

  /// Obtiene todos los aportes asociados a una meta.
  ///
  /// Los aportes más recientes aparecen primero.
  Future<List<ContributionModel>> getContributionsByGoal(int idMeta) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      'aporte',
      where: 'id_meta = ?',
      whereArgs: [idMeta],
      orderBy: 'fecha DESC',
    );

    return result.map((map) => ContributionModel.fromMap(map)).toList();
  }

  /// Actualiza un aporte existente.
  Future<int> updateContribution(ContributionModel contribution) async {
    final db = await DatabaseHelper.instance.database;

    return await db.update(
      'aporte',
      contribution.toMap(),
      where: 'id_aporte = ? AND id_meta = ?',
      whereArgs: [contribution.idAporte, contribution.idMeta],
    );
  }

  /// Elimina un aporte existente.
  Future<int> deleteContribution({
    required int idAporte,
    required int idMeta,
  }) async {
    final db = await DatabaseHelper.instance.database;

    return await db.delete(
      'aporte',
      where: 'id_aporte = ? AND id_meta = ?',
      whereArgs: [idAporte, idMeta],
    );
  }
}
