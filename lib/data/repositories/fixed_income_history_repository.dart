import '../database/database_helper.dart';
import '../models/fixed_income_history_model.dart';

/// Repositorio encargado de consultar y guardar
/// el historial del ingreso fijo mensual.
class FixedIncomeHistoryRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  /// Registra un nuevo valor de ingreso fijo.
  Future<int> insert(FixedIncomeHistoryModel history) async {
    final db = await _databaseHelper.database;

    return db.insert('ingreso_fijo_historico', history.toMap());
  }

  /// Obtiene el ingreso fijo que corresponde a un período determinado.
  ///
  /// Busca el último registro cuya fecha de inicio
  /// sea anterior o igual al comienzo del período.
  Future<FixedIncomeHistoryModel?> getByPeriod({
    required int idUsuario,
    required DateTime periodStart,
  }) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'ingreso_fijo_historico',
      where: 'id_usuario = ? AND fecha_inicio <= ?',
      whereArgs: [idUsuario, periodStart.toIso8601String()],
      orderBy: 'fecha_inicio DESC',
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return FixedIncomeHistoryModel.fromMap(result.first);
  }

  /// Obtiene todos los registros históricos de un usuario.
  Future<List<FixedIncomeHistoryModel>> getByUser(int idUsuario) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'ingreso_fijo_historico',
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
      orderBy: 'fecha_inicio ASC',
    );

    return result.map(FixedIncomeHistoryModel.fromMap).toList();
  }
}
