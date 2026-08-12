import '../database/database_helper.dart';
import '../models/goal_model.dart';

/// Repositorio para manejar las operaciones de persistencia
/// relacionadas con las metas.
class GoalRepository {
  /// Inserta una nueva meta.
  Future<int> crearMeta(GoalModel meta) async {
    final db = await DatabaseHelper.instance.database;

    return await db.insert('meta', meta.toMap());
  }

  /// Obtiene una meta específica mediante su identificador.
  Future<GoalModel?> obtenerMetaPorId({
    required int idMeta,
    required int idUsuario,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      'meta',
      where: 'id_meta = ? AND id_usuario = ?',
      whereArgs: [idMeta, idUsuario],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return GoalModel.fromMap(result.first);
  }

  /// Obtiene una meta mediante su identificador.
  ///
  /// Se utiliza cuando conocemos la meta pero todavía
  /// no tenemos disponible el identificador del usuario.
  Future<GoalModel?> obtenerMetaPorIdMeta(int idMeta) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      'meta',
      where: 'id_meta = ?',
      whereArgs: [idMeta],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return GoalModel.fromMap(result.first);
  }

  /// Obtiene todas las metas registradas por un usuario.
  Future<List<GoalModel>> listarMetas(int idUsuario) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      'meta',
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
      orderBy: 'fecha_registro DESC',
    );

    return result.map((map) => GoalModel.fromMap(map)).toList();
  }

  /// Actualiza una meta existente.
  Future<int> actualizarMeta(GoalModel meta) async {
    final db = await DatabaseHelper.instance.database;

    return await db.update(
      'meta',
      meta.toMap(),
      where: 'id_meta = ? AND id_usuario = ?',
      whereArgs: [meta.idMeta, meta.idUsuario],
    );
  }

  /// Elimina una meta.
  Future<int> eliminarMeta({
    required int idMeta,
    required int idUsuario,
  }) async {
    final db = await DatabaseHelper.instance.database;

    return await db.delete(
      'meta',
      where: 'id_meta = ? AND id_usuario = ?',
      whereArgs: [idMeta, idUsuario],
    );
  }

  /// Obtiene las metas que se encuentran activas.
  Future<List<GoalModel>> listarMetasActivas(int idUsuario) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      'meta',
      where: 'id_usuario = ? AND estado = ?',
      whereArgs: [idUsuario, 'Activa'],
      orderBy: 'fecha_registro DESC',
    );

    return result.map((map) => GoalModel.fromMap(map)).toList();
  }

  /// Obtiene las metas que se encuentran completadas.
  Future<List<GoalModel>> listarMetasCompletadas(int idUsuario) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      'meta',
      where: 'id_usuario = ? AND estado = ?',
      whereArgs: [idUsuario, 'Completada'],
      orderBy: 'fecha_registro DESC',
    );

    return result.map((map) => GoalModel.fromMap(map)).toList();
  }
}
